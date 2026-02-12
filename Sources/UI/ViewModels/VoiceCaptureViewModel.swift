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
    @ObservationIgnored private var baseTranscript: String = "" // Accumulated text from all previous recognition sessions

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

                // Stream ended (user paused or recognizer finished)
                // Auto-restart to continue listening
                guard let self = self else { return }

                if await self.captureState == .listening {
                    print("🎤 Recognition stream ended, auto-restarting...")
                    // Save current transcript before restarting
                    await self.saveTranscriptForRestart()

                    // Small delay to prevent rapid restarts
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000)

                    // Restart recognition if still listening
                    if await self.captureState == .listening {
                        await self.restartListening()
                    }
                }
            }
        } catch {
            captureState = .error("Failed to start voice recognition: \(error.localizedDescription)")
        }
    }

    /// Pauses listening (keeps transcript)
    func pauseListening() async {
        guard captureState == .listening else { return }

        // Save current transcript to base before stopping
        if !transcribedText.isEmpty {
            baseTranscript = transcribedText
            print("⏸️ Paused - saved to base: '\(baseTranscript.prefix(50))...'")
        }

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

                // Auto-restart if stream ends while listening
                guard let self = self else { return }
                if await self.captureState == .listening {
                    await self.saveTranscriptForRestart()
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
                    if await self.captureState == .listening {
                        await self.restartListening()
                    }
                }
            }
        } catch {
            captureState = .error("Failed to resume voice recognition: \(error.localizedDescription)")
        }
    }

    /// Restarts listening without state checks (for auto-restart)
    private func restartListening() async {
        print("🔄 Restarting recognition...")

        do {
            let stream = try await speechService.startListening()

            // Subscribe to new transcription updates (will append)
            transcriptionTask = _Concurrency.Task { [weak self] in
                for await update in stream {
                    await self?.handleTranscriptionUpdate(update)
                }

                // Auto-restart if stream ends while listening
                guard let self = self else { return }
                if await self.captureState == .listening {
                    await self.saveTranscriptForRestart()
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
                    if await self.captureState == .listening {
                        await self.restartListening()
                    }
                }
            }
        } catch {
            print("❌ Failed to restart: \(error.localizedDescription)")
            captureState = .error("Failed to restart voice recognition: \(error.localizedDescription)")
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
        baseTranscript = ""
        captureState = .idle
        captureSucceeded = true // Dismiss screen
    }

    // MARK: - Private Methods

    /// Saves current transcript before restarting recognition
    private func saveTranscriptForRestart() {
        // Move current text to base transcript so it's prepended to all future updates
        if !transcribedText.isEmpty && transcribedText != baseTranscript {
            baseTranscript = transcribedText
            print("💾 Saved to base: '\(baseTranscript.prefix(50))...' (length: \(baseTranscript.count))")
        }
    }

    /// Handles a transcription update from the speech recognizer
    private func handleTranscriptionUpdate(_ update: TranscriptionUpdate) {
        // Each update contains cumulative text from current recognition session
        // Prepend base transcript from all previous sessions
        if !baseTranscript.isEmpty {
            transcribedText = baseTranscript + " " + update.text
            print("📝 Base + Current: '\(baseTranscript.prefix(20))...' + '\(update.text.prefix(20))...' = '\(transcribedText.prefix(40))...'")
        } else {
            transcribedText = update.text
            print("📝 First session: '\(transcribedText.prefix(40))...'")
        }

        // Note: Removed auto-save timer - users should tap "Done" when finished
        // This prevents losing text when pausing to think
    }


    // MARK: - Cleanup

    deinit {
        transcriptionTask?.cancel()
    }
}
