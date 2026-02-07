//
//  SpeechService.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Speech Framework Integration
//  Wrapper around Speech framework for voice input
//

import Foundation
import Speech
import AVFoundation

// MARK: - Speech Service Protocol

/// Protocol for speech services.
///
/// Enables mocking in tests.
protocol SpeechServiceProtocol: FrameworkServiceProtocol {
    /// Transcribes audio from a file
    func transcribeAudio(_ audioURL: URL) async throws -> String

    /// Starts live transcription from microphone
    func startLiveTranscription() async throws -> AsyncThrowingStream<String, Error>

    /// Stops live transcription
    func stopLiveTranscription() async
}

// MARK: - Speech Service

/// Service for speech-to-text using the Speech framework.
///
/// Provides two modes of operation:
/// 1. File transcription: transcribe pre-recorded audio
/// 2. Live transcription: real-time transcription from microphone
///
/// ## Permissions
///
/// Requires both Speech Recognition and Microphone permissions.
/// Request permission before using any transcription features.
///
/// ## Platform Notes
///
/// AVAudioSession is unavailable on macOS. Live transcription
/// is only available on iOS/watchOS.
///
/// ## Availability
///
/// Speech recognition requires network connectivity for best results.
/// On-device recognition is available on iOS 13+ for some languages.
actor SpeechService: SpeechServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .speech }

    nonisolated var isAvailable: Bool {
        SFSpeechRecognizer.authorizationStatus() != .restricted
    }

    nonisolated var permissionStatus: PermissionLevel {
        mapAuthorizationStatus(SFSpeechRecognizer.authorizationStatus())
    }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - State

    private var recognizer: SFSpeechRecognizer?

    #if os(iOS) || os(watchOS)
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var liveTranscriptionContinuation: AsyncThrowingStream<String, Error>.Continuation?
    #endif

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        // Request speech recognition permission
        let speechStatus = await requestSpeechPermission()
        guard speechStatus == .authorized else {
            return speechStatus
        }

        #if os(iOS) || os(watchOS)
        // Request microphone permission (needed for live transcription)
        let micStatus = await requestMicrophonePermission()
        guard micStatus else {
            return .denied
        }
        #endif

        return .authorized
    }

    private func requestSpeechPermission() async -> PermissionLevel {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: self.mapAuthorizationStatus(status))
            }
        }
    }

    #if os(iOS) || os(watchOS)
    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    #endif

    // MARK: - File Transcription

    /// Transcribes audio from a file.
    ///
    /// - Parameter audioURL: URL to the audio file
    /// - Returns: The transcribed text
    /// - Throws: `ServiceError` if transcription fails
    func transcribeAudio(_ audioURL: URL) async throws -> String {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(
                framework: .speech,
                currentLevel: permissionStatus
            )
        }

        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw ServiceError.frameworkUnavailable(
                framework: .speech,
                reason: "Speech recognizer is not available"
            )
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        // Use on-device recognition if available
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: ServiceError.persistence(
                        operation: "transcribe audio",
                        underlying: error
                    ))
                    return
                }

                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    // MARK: - Live Transcription

    /// Starts live transcription from microphone.
    ///
    /// Returns an async stream that emits transcription updates as the
    /// user speaks. Call `stopLiveTranscription()` when done.
    ///
    /// - Returns: AsyncThrowingStream of transcription strings
    /// - Throws: `ServiceError` if transcription cannot start
    func startLiveTranscription() async throws -> AsyncThrowingStream<String, Error> {
        #if os(iOS) || os(watchOS)
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(
                framework: .speech,
                currentLevel: permissionStatus
            )
        }

        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw ServiceError.frameworkUnavailable(
                framework: .speech,
                reason: "Speech recognizer is not available"
            )
        }

        // Stop any existing session
        await stopLiveTranscription()

        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Set up audio engine
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        self.recognitionRequest = request

        // Install audio tap BEFORE creating stream to avoid actor isolation issues
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Start audio engine BEFORE creating stream
        audioEngine.prepare()
        try audioEngine.start()

        // Capture recognizer for use in closure (avoid actor isolation in closure)
        let capturedRecognizer = recognizer

        // Create the async stream
        return AsyncThrowingStream<String, Error> { continuation in
            // Use unstructured task to properly isolate actor access
            let isolatedTask = Task { @MainActor [weak self] in
                guard let self = self else {
                    continuation.finish()
                    return
                }

                await self.setLiveTranscriptionContinuation(continuation)

                // Start recognition
                let recognitionTask = capturedRecognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.finish(throwing: error)
                        return
                    }

                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        continuation.yield(transcription)

                        if result.isFinal {
                            continuation.finish()
                        }
                    }
                }

                await self.setRecognitionTask(recognitionTask)

                continuation.onTermination = { [weak self] _ in
                    guard let self = self else { return }
                    Task {
                        await self.stopLiveTranscription()
                    }
                }
            }
            _ = isolatedTask
        }
        #else
        throw ServiceError.frameworkUnavailable(
            framework: .speech,
            reason: "Live transcription is not available on macOS"
        )
        #endif
    }

    /// Stops live transcription.
    func stopLiveTranscription() async {
        #if os(iOS) || os(watchOS)
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        liveTranscriptionContinuation?.finish()
        liveTranscriptionContinuation = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }

    #if os(iOS) || os(watchOS)
    // Helper methods for actor-isolated property access
    private func setLiveTranscriptionContinuation(_ continuation: AsyncThrowingStream<String, Error>.Continuation) {
        self.liveTranscriptionContinuation = continuation
    }

    private func setRecognitionTask(_ task: SFSpeechRecognitionTask) {
        self.recognitionTask = task
    }
    #endif

    // MARK: - Helpers

    private nonisolated func mapAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> PermissionLevel {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        await stopLiveTranscription()
    }
}

// MARK: - Mock Speech Service

/// Mock speech service for testing and previews.
actor MockSpeechService: SpeechServiceProtocol {
    nonisolated var frameworkType: FrameworkType { .speech }
    nonisolated var isAvailable: Bool { true }
    var permissionStatus: PermissionLevel

    var mockTranscription: String

    init(
        permissionStatus: PermissionLevel = .authorized,
        transcription: String = "Sample transcription"
    ) {
        self.permissionStatus = permissionStatus
        self.mockTranscription = transcription
    }

    func requestPermission() async -> PermissionLevel {
        permissionStatus = .authorized
        return .authorized
    }

    func transcribeAudio(_ audioURL: URL) async throws -> String {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(framework: .speech, currentLevel: permissionStatus)
        }
        return mockTranscription
    }

    func startLiveTranscription() async throws -> AsyncThrowingStream<String, Error> {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(framework: .speech, currentLevel: permissionStatus)
        }

        return AsyncThrowingStream { continuation in
            continuation.yield(mockTranscription)
            continuation.finish()
        }
    }

    func stopLiveTranscription() async {}
}
