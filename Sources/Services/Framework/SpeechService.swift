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

// MARK: - Debug Logging

/// Thread-safe logging helper for debugging actor executor issues
private func speechLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let fileName = (file as NSString).lastPathComponent
    let threadInfo = Thread.isMainThread ? "MAIN" : "BG:\(Thread.current.name ?? "unnamed")"
    print("🎤 [SpeechService][\(threadInfo)][\(fileName):\(line)] \(function): \(message)")
}

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
        speechLog("init() - Creating SpeechService instance")
        self.configuration = configuration
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechLog("init() - SpeechService instance created, recognizer available: \(self.recognizer?.isAvailable ?? false)")
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        speechLog("requestPermission() - ENTER")

        // Request speech recognition permission
        speechLog("requestPermission() - About to request speech permission")
        let speechStatus = await requestSpeechPermission()
        speechLog("requestPermission() - Speech permission result: \(speechStatus)")
        guard speechStatus == .authorized else {
            speechLog("requestPermission() - EXIT (speech not authorized)")
            return speechStatus
        }

        #if os(iOS) || os(watchOS)
        // Request microphone permission (needed for live transcription)
        speechLog("requestPermission() - About to request microphone permission")
        let micStatus = await requestMicrophonePermission()
        speechLog("requestPermission() - Microphone permission result: \(micStatus)")
        guard micStatus else {
            speechLog("requestPermission() - EXIT (mic denied)")
            return .denied
        }
        #endif

        speechLog("requestPermission() - EXIT (authorized)")
        return .authorized
    }

    private func requestSpeechPermission() async -> PermissionLevel {
        speechLog("requestSpeechPermission() - ENTER")
        // Capture self as nonisolated before entering the callback
        // to avoid actor executor issues when callback runs on different thread
        let mapper = { (status: SFSpeechRecognizerAuthorizationStatus) -> PermissionLevel in
            // Use static mapping to avoid any actor access
            switch status {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            case .authorized: return .authorized
            @unknown default: return .notDetermined
            }
        }

        let result = await withCheckedContinuation { continuation in
            speechLog("requestSpeechPermission() - Inside withCheckedContinuation, calling SFSpeechRecognizer.requestAuthorization")
            SFSpeechRecognizer.requestAuthorization { status in
                speechLog("requestSpeechPermission() - Authorization callback received, status: \(status.rawValue)")
                // Use the pre-captured mapper to avoid any actor isolation issues
                let level = mapper(status)
                speechLog("requestSpeechPermission() - Mapped to level: \(level), resuming continuation")
                continuation.resume(returning: level)
            }
        }
        speechLog("requestSpeechPermission() - EXIT with result: \(result)")
        return result
    }

    #if os(iOS) || os(watchOS)
    private func requestMicrophonePermission() async -> Bool {
        speechLog("requestMicrophonePermission() - ENTER")
        let result = await withCheckedContinuation { continuation in
            speechLog("requestMicrophonePermission() - Inside withCheckedContinuation, calling AVAudioApplication.requestRecordPermission")
            AVAudioApplication.requestRecordPermission { granted in
                speechLog("requestMicrophonePermission() - Permission callback received, granted: \(granted)")
                continuation.resume(returning: granted)
            }
        }
        speechLog("requestMicrophonePermission() - EXIT with result: \(result)")
        return result
    }
    #endif

    // MARK: - File Transcription

    /// Transcribes audio from a file.
    ///
    /// - Parameter audioURL: URL to the audio file
    /// - Returns: The transcribed text
    /// - Throws: `ServiceError` if transcription fails
    func transcribeAudio(_ audioURL: URL) async throws -> String {
        speechLog("transcribeAudio() - ENTER, url: \(audioURL)")

        speechLog("transcribeAudio() - Checking permission status")
        let currentPermission = permissionStatus
        speechLog("transcribeAudio() - Current permission: \(currentPermission)")
        guard currentPermission.allowsAccess else {
            speechLog("transcribeAudio() - EXIT (permission denied)")
            throw ServiceError.permissionDenied(
                framework: .speech,
                currentLevel: currentPermission
            )
        }

        speechLog("transcribeAudio() - Checking recognizer availability")
        guard let recognizer = recognizer, recognizer.isAvailable else {
            speechLog("transcribeAudio() - EXIT (recognizer unavailable)")
            throw ServiceError.frameworkUnavailable(
                framework: .speech,
                reason: "Speech recognizer is not available"
            )
        }
        speechLog("transcribeAudio() - Recognizer available")

        speechLog("transcribeAudio() - Creating SFSpeechURLRecognitionRequest")
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        // Use on-device recognition if available
        if recognizer.supportsOnDeviceRecognition {
            speechLog("transcribeAudio() - Enabling on-device recognition")
            request.requiresOnDeviceRecognition = true
        }

        speechLog("transcribeAudio() - About to call withCheckedThrowingContinuation")
        return try await withCheckedThrowingContinuation { continuation in
            speechLog("transcribeAudio() - Inside continuation, starting recognition task")
            recognizer.recognitionTask(with: request) { result, error in
                // WARNING: This callback runs on Speech framework's thread, NOT on actor
                speechLog("transcribeAudio CALLBACK - ENTER, error: \(String(describing: error)), hasResult: \(result != nil)")

                if let error = error {
                    speechLog("transcribeAudio CALLBACK - Resuming with error")
                    continuation.resume(throwing: ServiceError.persistence(
                        operation: "transcribe audio",
                        underlying: error
                    ))
                    return
                }

                if let result = result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    speechLog("transcribeAudio CALLBACK - Resuming with result: '\(text.prefix(50))...'")
                    continuation.resume(returning: text)
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
        speechLog("startLiveTranscription() - ENTER")

        #if os(iOS) || os(watchOS)
        speechLog("startLiveTranscription() - Checking permission status")
        let currentPermission = permissionStatus
        speechLog("startLiveTranscription() - Current permission: \(currentPermission)")
        guard currentPermission.allowsAccess else {
            speechLog("startLiveTranscription() - EXIT (permission denied)")
            throw ServiceError.permissionDenied(
                framework: .speech,
                currentLevel: currentPermission
            )
        }

        speechLog("startLiveTranscription() - Checking recognizer availability")
        guard let recognizer = recognizer, recognizer.isAvailable else {
            speechLog("startLiveTranscription() - EXIT (recognizer unavailable)")
            throw ServiceError.frameworkUnavailable(
                framework: .speech,
                reason: "Speech recognizer is not available"
            )
        }
        speechLog("startLiveTranscription() - Recognizer is available")

        // Stop any existing session
        speechLog("startLiveTranscription() - About to stop any existing session")
        await stopLiveTranscription()
        speechLog("startLiveTranscription() - Existing session stopped")

        // Set up audio session
        speechLog("startLiveTranscription() - Setting up audio session")
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        speechLog("startLiveTranscription() - Audio session configured")

        // Set up audio engine
        speechLog("startLiveTranscription() - Creating AVAudioEngine")
        let audioEngine = AVAudioEngine()
        speechLog("startLiveTranscription() - About to store audioEngine on actor (self.audioEngine = audioEngine)")
        self.audioEngine = audioEngine
        speechLog("startLiveTranscription() - audioEngine stored successfully")

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        speechLog("startLiveTranscription() - Got input node, format: \(recordingFormat)")

        // Create recognition request
        speechLog("startLiveTranscription() - Creating SFSpeechAudioBufferRecognitionRequest")
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        if recognizer.supportsOnDeviceRecognition {
            speechLog("startLiveTranscription() - Enabling on-device recognition")
            request.requiresOnDeviceRecognition = true
        }

        speechLog("startLiveTranscription() - About to store recognitionRequest on actor (self.recognitionRequest = request)")
        self.recognitionRequest = request
        speechLog("startLiveTranscription() - recognitionRequest stored successfully")

        // Install audio tap BEFORE creating stream to avoid actor isolation issues
        speechLog("startLiveTranscription() - Installing audio tap on input node")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // This callback runs on audio thread - NOT on actor
            // Only touches 'request' which was captured, not 'self'
            request.append(buffer)
        }
        speechLog("startLiveTranscription() - Audio tap installed")

        // Start audio engine BEFORE creating stream
        speechLog("startLiveTranscription() - Preparing audio engine")
        audioEngine.prepare()
        speechLog("startLiveTranscription() - Starting audio engine")
        try audioEngine.start()
        speechLog("startLiveTranscription() - Audio engine started successfully")

        // Use makeStream which returns both stream and continuation synchronously
        // This allows us to store state on the actor BEFORE returning the stream
        speechLog("startLiveTranscription() - Creating AsyncThrowingStream with makeStream()")
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
        speechLog("startLiveTranscription() - Stream created successfully")

        // Store the continuation immediately (we're on the actor)
        speechLog("startLiveTranscription() - About to store liveTranscriptionContinuation on actor")
        self.liveTranscriptionContinuation = continuation
        speechLog("startLiveTranscription() - liveTranscriptionContinuation stored successfully")

        // Start recognition task and store it immediately
        // The callback closure only captures the continuation (which is Sendable)
        // and does NOT capture self, avoiding actor isolation issues
        speechLog("startLiveTranscription() - About to start recognition task (recognizer.recognitionTask)")
        speechLog("startLiveTranscription() - CRITICAL: The callback closure must NOT capture 'self'")
        let task = recognizer.recognitionTask(with: request) { result, error in
            // WARNING: This callback runs on Speech framework's thread, NOT on actor
            // We must NOT access actor-isolated state here
            speechLog("recognitionTask CALLBACK - ENTER (on Speech framework thread)")
            speechLog("recognitionTask CALLBACK - error: \(String(describing: error)), hasResult: \(result != nil)")

            if let error {
                speechLog("recognitionTask CALLBACK - Finishing with error: \(error)")
                continuation.finish(throwing: error)
                speechLog("recognitionTask CALLBACK - EXIT (error)")
                return
            }

            if let result {
                let transcription = result.bestTranscription.formattedString
                speechLog("recognitionTask CALLBACK - Got transcription: '\(transcription.prefix(50))...', isFinal: \(result.isFinal)")
                continuation.yield(transcription)

                if result.isFinal {
                    speechLog("recognitionTask CALLBACK - Result is final, finishing stream")
                    continuation.finish()
                }
                speechLog("recognitionTask CALLBACK - EXIT (success)")
            }
        }
        speechLog("startLiveTranscription() - Recognition task created, task state: \(task.state.rawValue)")

        // Store the task on the actor
        speechLog("startLiveTranscription() - About to store recognitionTask on actor (self.recognitionTask = task)")
        self.recognitionTask = task
        speechLog("startLiveTranscription() - recognitionTask stored successfully")

        speechLog("startLiveTranscription() - EXIT (returning stream)")
        return stream
        #else
        speechLog("startLiveTranscription() - EXIT (macOS not supported)")
        throw ServiceError.frameworkUnavailable(
            framework: .speech,
            reason: "Live transcription is not available on macOS"
        )
        #endif
    }

    /// Stops live transcription.
    func stopLiveTranscription() async {
        speechLog("stopLiveTranscription() - ENTER")

        #if os(iOS) || os(watchOS)
        speechLog("stopLiveTranscription() - About to access audioEngine")
        if let engine = audioEngine {
            speechLog("stopLiveTranscription() - Stopping audioEngine")
            engine.stop()
            speechLog("stopLiveTranscription() - Removing tap from inputNode")
            engine.inputNode.removeTap(onBus: 0)
        } else {
            speechLog("stopLiveTranscription() - audioEngine was nil")
        }
        speechLog("stopLiveTranscription() - Setting audioEngine = nil")
        audioEngine = nil

        speechLog("stopLiveTranscription() - About to access recognitionRequest")
        if let request = recognitionRequest {
            speechLog("stopLiveTranscription() - Calling endAudio on recognitionRequest")
            request.endAudio()
        } else {
            speechLog("stopLiveTranscription() - recognitionRequest was nil")
        }
        speechLog("stopLiveTranscription() - Setting recognitionRequest = nil")
        recognitionRequest = nil

        speechLog("stopLiveTranscription() - About to access recognitionTask")
        if let task = recognitionTask {
            speechLog("stopLiveTranscription() - Cancelling recognitionTask, state: \(task.state.rawValue)")
            task.cancel()
        } else {
            speechLog("stopLiveTranscription() - recognitionTask was nil")
        }
        speechLog("stopLiveTranscription() - Setting recognitionTask = nil")
        recognitionTask = nil

        speechLog("stopLiveTranscription() - About to access liveTranscriptionContinuation")
        if let continuation = liveTranscriptionContinuation {
            speechLog("stopLiveTranscription() - Finishing liveTranscriptionContinuation")
            continuation.finish()
        } else {
            speechLog("stopLiveTranscription() - liveTranscriptionContinuation was nil")
        }
        speechLog("stopLiveTranscription() - Setting liveTranscriptionContinuation = nil")
        liveTranscriptionContinuation = nil

        // Deactivate audio session
        speechLog("stopLiveTranscription() - Deactivating audio session")
        try? AVAudioSession.sharedInstance().setActive(false)
        speechLog("stopLiveTranscription() - EXIT")
        #else
        speechLog("stopLiveTranscription() - EXIT (macOS, no-op)")
        #endif
    }


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
        speechLog("initialize() - ENTER")
        // No initialization needed
        speechLog("initialize() - EXIT")
    }

    func shutdown() async {
        speechLog("shutdown() - ENTER")
        await stopLiveTranscription()
        speechLog("shutdown() - EXIT")
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
