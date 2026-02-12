//
//  SpeechRecognitionService.swift
//  STASH
//
//  Phase 3B: Speech Recognition for Voice Capture
//  Wrapper around Speech framework for real-time speech-to-text
//

import Foundation
import Speech
import AVFoundation

// MARK: - Transcription Update

/// Represents a single transcription update from the speech recognizer.
struct TranscriptionUpdate: Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Float
}

// MARK: - Speech Recognition Service Protocol

/// Protocol for speech recognition services.
///
/// Enables mocking in tests.
protocol SpeechRecognitionServiceProtocol: FrameworkServiceProtocol {
    /// Starts listening and returns a stream of transcription updates
    func startListening() async throws -> AsyncStream<TranscriptionUpdate>

    /// Stops listening and returns the final transcript
    func stopListening() async -> String

    /// Cancels listening without returning a result
    func cancelListening() async
}

// MARK: - Speech Recognition Service

/// Service for converting speech to text using Speech framework.
///
/// Provides real-time streaming transcription for voice capture UI.
/// Handles microphone permission, audio session configuration, and
/// speech recognition authorization.
///
/// ## Permissions
///
/// Requires both microphone and speech recognition permissions.
/// Check `permissionStatus` and call `requestPermission()` before
/// starting recognition.
///
/// ## Performance
///
/// Prefers on-device recognition when available (iOS 17+).
/// Falls back to server-based recognition if needed.
actor SpeechRecognitionService: SpeechRecognitionServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .speech }

    nonisolated var isAvailable: Bool {
        SFSpeechRecognizer(locale: Locale.current) != nil
    }

    var permissionStatus: PermissionLevel {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioApplication.shared.recordPermission

        // Both permissions must be granted
        if speechStatus == .authorized && micStatus == .granted {
            return .authorized
        } else if speechStatus == .denied || micStatus == .denied {
            return .denied
        } else if speechStatus == .restricted || micStatus == .undetermined {
            return .restricted
        } else {
            return .notDetermined
        }
    }

    // MARK: - State

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var currentTranscript: String = ""

    // MARK: - Initialization

    init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale.current)
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        guard isAvailable else { return .restricted }

        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        // Request microphone permission
        let micStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.shared.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        // Map to PermissionLevel
        if speechStatus == .authorized && micStatus {
            return .authorized
        } else if speechStatus == .denied || !micStatus {
            return .denied
        } else {
            return .restricted
        }
    }

    // MARK: - Speech Recognition

    /// Starts listening and returns a stream of transcription updates.
    ///
    /// Throws if:
    /// - Speech recognizer is unavailable
    /// - Permissions are not granted
    /// - Audio session cannot be configured
    func startListening() async throws -> AsyncStream<TranscriptionUpdate> {
        guard isAvailable else {
            throw ServiceError.frameworkUnavailable(frameworkType)
        }

        guard permissionStatus == .authorized else {
            throw ServiceError.permissionDenied(frameworkType, permissionStatus)
        }

        // Cancel any existing recognition
        await cancelListening()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // Prefer on-device recognition if available
        if let recognizer = recognizer, recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        self.recognitionRequest = request

        // Create audio engine
        let engine = AVAudioEngine()
        self.audioEngine = engine

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create async stream
        return AsyncStream { continuation in
            // Install tap on audio input
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            // Start recognition task
            self.recognitionTask = self.recognizer?.recognitionTask(with: request) { result, error in
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    let confidence = result.bestTranscription.segments.first?.confidence ?? 0.0

                    Task {
                        await self.updateCurrentTranscript(transcription)

                        let update = TranscriptionUpdate(
                            text: transcription,
                            isFinal: result.isFinal,
                            confidence: confidence
                        )

                        continuation.yield(update)

                        if result.isFinal {
                            continuation.finish()
                        }
                    }
                }

                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    continuation.finish()
                }
            }

            // Start audio engine
            engine.prepare()
            do {
                try engine.start()
            } catch {
                print("Audio engine error: \(error.localizedDescription)")
                continuation.finish()
            }

            // Handle cancellation
            continuation.onTermination = { @Sendable _ in
                Task {
                    await self.cancelListening()
                }
            }
        }
    }

    /// Stops listening and returns the final transcript.
    func stopListening() async -> String {
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()

        // Wait a moment for final result
        try? await Task.sleep(for: .milliseconds(100))

        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        return currentTranscript
    }

    /// Cancels listening without returning a result.
    func cancelListening() async {
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Stop audio engine
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        // Cancel recognition request
        recognitionRequest = nil

        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        // Reset transcript
        currentTranscript = ""
    }

    // MARK: - Private Helpers

    private func updateCurrentTranscript(_ text: String) {
        currentTranscript = text
    }
}

// MARK: - Shared Instance

extension SpeechRecognitionService {
    static let shared = SpeechRecognitionService()
}
