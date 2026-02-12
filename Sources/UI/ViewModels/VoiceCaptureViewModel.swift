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
    @ObservationIgnored private var savedTranscript: String = "" // Text saved from previous session when paused
    @ObservationIgnored private var lastUpdate: String = "" // Last update received to detect cumulative vs fresh

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

                // Stream ended - let it end naturally, user can resume manually
                guard let self = self else { return }
                await self.handleStreamEnded()
            }
        } catch {
            captureState = .error("Failed to start voice recognition: \(error.localizedDescription)")
        }
    }

    /// Pauses listening (keeps transcript)
    func pauseListening() async {
        guard captureState == .listening else { return }

        // Save current transcript before stopping
        savedTranscript = transcribedText
        lastUpdate = ""
        _ = await speechService.stopListening()

        captureState = .paused
    }

    /// Resumes listening (appends to existing transcript)
    func resumeListening() async {
        guard captureState == .paused else { return }

        do {
            captureState = .listening

            let stream = try await speechService.startListening()

            // Subscribe to new transcription updates (savedTranscript will be prepended)
            transcriptionTask = _Concurrency.Task { [weak self] in
                for await update in stream {
                    await self?.handleTranscriptionUpdate(update)
                }

                // Stream ended naturally
                guard let self = self else { return }
                await self.handleStreamEnded()
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

        await speechService.cancelListening()

        transcribedText = ""
        savedTranscript = ""
        lastUpdate = ""
        captureState = .idle
        captureSucceeded = true // Dismiss screen
    }

    // MARK: - Private Methods

    /// Called when the recognition stream ends naturally
    private func handleStreamEnded() {
        if captureState == .listening {
            // Stream ended due to pause - save what we have and transition to paused
            savedTranscript = transcribedText
            lastUpdate = ""
            captureState = .paused
            print("⏸️ Stream ended - tap mic to continue")
        }
    }

    /// Handles a transcription update from the speech recognizer
    private func handleTranscriptionUpdate(_ update: TranscriptionUpdate) {
        let newText = update.text

        // Check if this update builds on the last one (cumulative) or is fresh (non-cumulative)
        let isCumulative = lastUpdate.isEmpty || (newText.count >= lastUpdate.count && newText.hasPrefix(lastUpdate))

        if isCumulative {
            // Normal cumulative update - use it
            if !savedTranscript.isEmpty {
                transcribedText = savedTranscript + " " + newText
            } else {
                transcribedText = newText
            }
        } else {
            // Fresh update mid-session - append to preserve previous text
            transcribedText = transcribedText + " " + newText
        }

        lastUpdate = newText
    }


    // MARK: - Cleanup

    deinit {
        transcriptionTask?.cancel()
    }
}
