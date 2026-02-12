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
/// - 3-second silence auto-save
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
    @ObservationIgnored private var transcriptBeforePause: String = ""

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
        // Check permissions first
        let permissionStatus = await speechService.permissionStatus

        if permissionStatus != .authorized {
            // Request permission
            let newStatus = await speechService.requestPermission()

            if newStatus != .authorized {
                captureState = .error("Microphone and speech recognition permissions are required. Please enable them in Settings.")
                return
            }
        }

        // Start speech recognition
        do {
            captureState = .listening

            let stream = try await speechService.startListening()

            // Subscribe to transcription updates
            transcriptionTask = _Concurrency.Task { [weak self] in
                for await update in stream {
                    await self?.handleTranscriptionUpdate(update)
                }
            }
        } catch {
            captureState = .error("Failed to start voice recognition: \(error.localizedDescription)")
        }
    }

    /// Pauses listening (keeps transcript)
    func pauseListening() async {
        guard captureState == .listening else { return }

        // Cancel silence timer
        silenceTimer?.cancel()
        silenceTimer = nil

        // Stop audio engine but keep transcript
        transcriptBeforePause = transcribedText
        _ = await speechService.stopListening()

        captureState = .paused
    }

    /// Resumes listening (appends to existing transcript)
    func resumeListening() async {
        guard captureState == .paused else { return }

        do {
            captureState = .listening

            let stream = try await speechService.startListening()

            // Subscribe to new transcription updates (will append)
            transcriptionTask = _Concurrency.Task { [weak self] in
                for await update in stream {
                    await self?.handleTranscriptionUpdate(update)
                }
            }
        } catch {
            captureState = .error("Failed to resume voice recognition: \(error.localizedDescription)")
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
        transcriptionTask?.cancel()
        silenceTimer?.cancel()

        // Stop speech recognition
        let finalTranscript = await speechService.stopListening()

        // Use final transcript if available, otherwise use what we have
        let content = finalTranscript.isEmpty ? transcribedText : finalTranscript

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
            _ = try await thoughtService.create(thought)

            // TODO: Enrich context in background (Phase 1a requirement)
            // Task.detached {
            //     await self.enrichContextInBackground(for: thought.id)
            // }

            captureState = .saved
            captureSucceeded = true
        } catch {
            captureState = .error("Failed to save thought: \(error.localizedDescription)")
        }
    }

    /// Cancels listening and discards transcript
    func cancelListening() async {
        transcriptionTask?.cancel()
        silenceTimer?.cancel()

        await speechService.cancelListening()

        transcribedText = ""
        transcriptBeforePause = ""
        captureState = .idle
        captureSucceeded = true // Dismiss screen
    }

    // MARK: - Private Methods

    /// Handles a transcription update from the speech recognizer
    private func handleTranscriptionUpdate(_ update: TranscriptionUpdate) {
        // Merge with previous transcript if resuming from pause
        if !transcriptBeforePause.isEmpty && !transcribedText.contains(transcriptBeforePause) {
            transcribedText = transcriptBeforePause + " " + update.text
        } else {
            transcribedText = update.text
        }

        // Reset silence timer on each update
        resetSilenceTimer()
    }

    /// Resets the 3-second silence timer
    private func resetSilenceTimer() {
        silenceTimer?.cancel()

        silenceTimer = _Concurrency.Task { [weak self] in
            try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)

            guard !_Concurrency.Task.isCancelled else { return }

            // Auto-save if we have text and we're still listening
            if let self = self,
               self.captureState == .listening,
               !self.transcribedText.isEmpty {
                await self.stopAndSave()
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        transcriptionTask?.cancel()
        silenceTimer?.cancel()
    }
}
