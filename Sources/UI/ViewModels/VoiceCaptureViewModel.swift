//
//  VoiceCaptureViewModel.swift
//  STASH
//
//  Phase 3B: Voice Capture ViewModel
//  Manages state for real-time voice-to-text capture
//

import Foundation
import Observation

// MARK: - Capture State

/// State of the voice capture process
enum VoiceCaptureState: Equatable {
    case idle
    case listening
    case paused
    case processing
    case saved
    case error(String)
}

// MARK: - Voice Capture ViewModel

/// ViewModel for the voice capture screen.
///
/// Manages real-time speech-to-text capture with:
/// - Pause/resume functionality
/// - Real-time transcription display
/// - Manual save via Done button
/// - Permission handling
/// - Context enrichment (background)
@Observable
@MainActor
final class VoiceCaptureViewModel {
    // MARK: - State

    /// Current state of voice capture
    var captureState: VoiceCaptureState = .idle

    /// Transcribed text (updates in real-time)
    var transcribedText: String = ""

    /// Whether capture succeeded (triggers dismissal)
    var captureSucceeded: Bool = false

    /// Current error to display
    var error: AppError?

    // MARK: - Dependencies

    private let speechService: SpeechRecognitionService
    private let thoughtService: ThoughtService

    // MARK: - Private State

    @ObservationIgnored private var transcriptionTask: _Concurrency.Task<Void, Never>?
    @ObservationIgnored private var silenceTimer: _Concurrency.Task<Void, Never>?
    @ObservationIgnored private var savedTranscript: String = "" // Text saved from completed segments

    private let silenceTimeoutSeconds: TimeInterval = 7

    // MARK: - Initialization

    init(
        speechService: SpeechRecognitionService = .shared,
        thoughtService: ThoughtService = .shared
    ) {
        self.speechService = speechService
        self.thoughtService = thoughtService
    }

    // MARK: - Lifecycle

    /// Starts listening on view appear
    func startListening() async {
        let permissionStatus = await speechService.permissionStatus

        if permissionStatus != .authorized {
            let newStatus = await speechService.requestPermission()
            if newStatus != .authorized {
                captureState = .error("Microphone and speech recognition permissions are required. Please enable them in Settings.")
                return
            }
        }

        captureState = .listening
        await beginCapture()
    }

    /// Pauses listening (keeps transcript)
    func pauseListening() async {
        guard captureState == .listening else { return }
        savedTranscript = transcribedText
        cancelSilenceTimer()
        // Set state BEFORE stopping so handleStreamEnded won't auto-restart
        captureState = .paused
        _ = await speechService.stopListening()
    }

    /// Resumes listening (appends to existing transcript)
    func resumeListening() async {
        guard captureState == .paused else { return }
        captureState = .listening
        await beginCapture()
    }


    // MARK: - Private — Capture Management

    /// Starts a recognition session and wires up the stream.
    /// Called on initial start, resume, and auto-restart after session end.
    private func beginCapture() async {
        guard captureState == .listening else { return }
        resetSilenceTimer() // Safety net: save after 7s of silence even if no new speech
        do {
            let stream = try await speechService.startListening()
            transcriptionTask = _Concurrency.Task { [weak self] in
                for await update in stream {
                    self?.handleTranscriptionUpdate(update)
                }
                guard let self = self else { return }
                self.handleSessionEnded()
            }
        } catch {
            captureState = .error("Failed to start voice recognition: \(error.localizedDescription)")
        }
    }

    /// Called when a recognition session ends (stream exhausted).
    ///
    /// If we're still in listening state this was an OS-initiated session boundary
    /// (silence timeout, 60-second limit, etc.) — auto-restart seamlessly so the
    /// user never sees a "paused" state they didn't ask for.
    private func handleSessionEnded() {
        guard captureState == .listening else { return }
        cancelSilenceTimer()
        savedTranscript = transcribedText
        // Auto-restart: let iOS manage session boundaries, we just continue
        _Concurrency.Task { [weak self] in
            await self?.beginCapture()
        }
    }

    /// Stops listening and saves the thought
    func stopAndSave() async {
        guard !transcribedText.isEmpty else {
            // Nothing to save
            await cancelListening()
            return
        }

        captureState = .processing

        // Cancel ongoing tasks
        cancelSilenceTimer()
        transcriptionTask?.cancel()

        // Stop speech recognition (cleanup only — transcribedText is authoritative)
        _ = await speechService.stopListening()

        let content = transcribedText

        // Create thought
        let now = Date()
        let thought = Thought(
            id: UUID(),
            userId: UUID(), // TODO: Get from user session
            content: content,
            attributedContent: nil,
            tags: [],
            status: .active,
            context: Context.empty(), // Start with empty, enrich in background
            createdAt: now,
            updatedAt: now,
            classification: nil, // Will be classified in background
            relatedThoughtIds: [],
            taskId: nil
        )

        do {
            // Save thought
            let saved = try await thoughtService.create(thought)

            // Enrich context in background (Phase 1a requirement)
            _Concurrency.Task.detached {
                await ContextEnrichmentService.shared.enrichContext(for: thought.id)
            }

            // Gamification hooks (mirrors CaptureViewModel)
            let streakUpdate = StreakTracker.shared.recordCapture()
            if let milestone = streakUpdate.milestone {
                _ = await AcornService.shared.processStreakMilestone(days: milestone.rawValue)
            }
            _ = await AcornService.shared.processCapture(hadContext: false)
            _ = await BadgeService.shared.checkAll(newThought: saved, thoughtService: thoughtService)
            _ = await VariableRewardService.shared.roll()
            SquirrelReminderService.shared.onCaptureCompleted()
            SquirrelCompanionService.shared.recordCapture()
            AnalyticsService.shared.track(.thoughtCaptured(method: .voice))

            captureState = .saved
            captureSucceeded = true
        } catch {
            captureState = .error("Failed to save thought: \(error.localizedDescription)")
        }
    }

    /// Cancels listening and discards transcript
    func cancelListening() async {
        cancelSilenceTimer()
        // Set state BEFORE cancelling task so handleSessionEnded won't auto-restart
        captureState = .idle
        transcriptionTask?.cancel()
        await speechService.cancelListening()
        transcribedText = ""
        savedTranscript = ""
        captureSucceeded = true // Dismiss screen
    }

    // MARK: - Private Methods

    /// Handles a transcription update from the speech recognizer.
    ///
    /// update.text is cumulative within a session (partial result building up).
    /// savedTranscript holds text from completed prior sessions so it prepends.
    private func handleTranscriptionUpdate(_ update: TranscriptionUpdate) {
        transcribedText = savedTranscript.isEmpty ? update.text : savedTranscript + " " + update.text

        if update.isFinal {
            savedTranscript = transcribedText
        }

        resetSilenceTimer()
    }

    private func resetSilenceTimer() {
        silenceTimer?.cancel()
        let timeout = silenceTimeoutSeconds
        silenceTimer = _Concurrency.Task { [weak self] in
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard let self, !_Concurrency.Task.isCancelled else { return }
            await self.stopAndSave()
        }
    }

    private func cancelSilenceTimer() {
        silenceTimer?.cancel()
        silenceTimer = nil
    }


    // MARK: - Cleanup

    deinit {
        silenceTimer?.cancel()
        transcriptionTask?.cancel()
    }
}
