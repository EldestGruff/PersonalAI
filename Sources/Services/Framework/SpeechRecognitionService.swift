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
/// Each call to startListening() returns one AsyncStream that covers one
/// recognition session. The stream ends when the recognition task completes
/// (isFinal), is cancelled, or encounters an unrecoverable error.
///
/// The ViewModel is responsible for restarting capture across sessions —
/// this keeps the service simple and lets the OS manage session lifetimes
/// without us fighting it.
actor SpeechRecognitionService: SpeechRecognitionServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .speech }

    nonisolated var isAvailable: Bool {
        SFSpeechRecognizer(locale: Locale.current) != nil
    }

    var permissionStatus: PermissionLevel {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioApplication.shared.recordPermission

        if speechStatus == .authorized && micStatus == .granted {
            return .authorized
        } else if speechStatus == .denied || micStatus == .denied {
            return .denied
        } else if speechStatus == .restricted {
            // .restricted means parental controls / MDM policy blocks access.
            // AVAudioApplication has no .restricted case — only .granted/.denied/.undetermined.
            return .restricted
        } else {
            // Covers: speechStatus == .notDetermined, micStatus == .undetermined, or any mix.
            // Previously this branch incorrectly returned .restricted for micStatus == .undetermined.
            return .notDetermined
        }
    }

    // MARK: - State

    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var streamContinuation: AsyncStream<TranscriptionUpdate>.Continuation?

    /// Last recognized text — returned by stopListening() for callers that want it.
    private var currentTranscript: String = ""

    /// Current recognition request. Accessed from the audio tap (non-actor thread).
    nonisolated(unsafe) private var activeRequest: SFSpeechAudioBufferRecognitionRequest?

    // MARK: - Initialization

    init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale.current)
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        guard isAvailable else { return .restricted }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        if speechStatus == .authorized && micStatus {
            return .authorized
        } else if speechStatus == .denied || !micStatus {
            return .denied
        } else {
            return .restricted
        }
    }

    // MARK: - Speech Recognition

    /// Starts a recognition session and returns a stream of transcription updates.
    ///
    /// The stream ends when the recognition task completes naturally (isFinal),
    /// is explicitly stopped, or encounters an unrecoverable error. The ViewModel
    /// handles restarting across sessions to provide seamless capture.
    func startListening() async throws -> AsyncStream<TranscriptionUpdate> {
        guard isAvailable else {
            throw ServiceError.frameworkUnavailable(framework: frameworkType, reason: "Speech recognizer not available for current locale")
        }

        guard permissionStatus == .authorized else {
            throw ServiceError.permissionDenied(framework: frameworkType, currentLevel: permissionStatus)
        }

        await cancelListening()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        self.audioEngine = engine

        nonisolated(unsafe) let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        let stream = AsyncStream<TranscriptionUpdate> { continuation in
            self.streamContinuation = continuation

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.activeRequest?.append(buffer)
            }

            continuation.onTermination = { @Sendable _ in
                _Concurrency.Task { await self.stopEngine() }
            }
        }

        engine.prepare()
        try engine.start()

        startRecognitionTask()

        return stream
    }

    /// Stops listening gracefully and returns the last recognized transcript.
    func stopListening() async -> String {
        let transcript = currentTranscript
        streamContinuation?.finish()
        streamContinuation = nil
        await stopEngine()
        return transcript
    }

    /// Cancels listening and discards the transcript.
    func cancelListening() async {
        streamContinuation?.finish()
        streamContinuation = nil
        await stopEngine()
        currentTranscript = ""
    }

    // MARK: - Private — Recognition Task

    private func startRecognitionTask() {
        guard let recognizer, streamContinuation != nil else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Use server recognition by default — it has much more lenient silence
        // detection than on-device. iOS falls back to on-device automatically
        // when offline. The ViewModel handles restarting across session boundaries.

        activeRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // Extract Sendable values from the non-Sendable result before crossing actor boundary.
            let update: (text: String, confidence: Float, isFinal: Bool)?
            if let result {
                update = (
                    text: result.bestTranscription.formattedString,
                    confidence: result.bestTranscription.segments.first?.confidence ?? 0.0,
                    isFinal: result.isFinal
                )
            } else {
                update = nil
            }
            let errorCode = (error as? NSError)?.code

            _Concurrency.Task { [weak self] in
                await self?.handleCallback(update: update, errorCode: errorCode)
            }
        }
    }

    private func handleCallback(
        update: (text: String, confidence: Float, isFinal: Bool)?,
        errorCode: Int?
    ) async {
        if let update {
            currentTranscript = update.text
            streamContinuation?.yield(TranscriptionUpdate(text: update.text, isFinal: update.isFinal, confidence: update.confidence))

            if update.isFinal {
                // Session ended naturally — close the stream. ViewModel will restart.
                streamContinuation?.finish()
                streamContinuation = nil
            }
        }

        if let code = errorCode {
            switch code {
            case 301:
                break // Cancellation — cleanup in progress, ignore
            default:
                // Any other error ends the session. ViewModel will restart if appropriate.
                if streamContinuation != nil {
                    streamContinuation?.finish()
                    streamContinuation = nil
                }
            }
        }
    }

    // MARK: - Private — Engine Lifecycle

    private func stopEngine() async {
        recognitionTask?.cancel()
        recognitionTask = nil
        activeRequest = nil

        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Shared Instance

extension SpeechRecognitionService {
    static let shared = SpeechRecognitionService()
}
