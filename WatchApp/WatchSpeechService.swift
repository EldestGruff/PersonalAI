//
//  WatchSpeechService.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Speech recognition for watchOS using SFSpeechRecognizer + AVAudioEngine.
//  On-device recognition is preferred (requiresOnDeviceRecognition = true)
//  so captures work without network access.
//

import Foundation
import Speech
import AVFoundation

// MARK: - Watch Speech Service

actor WatchSpeechService {
    static let shared = WatchSpeechService()

    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?

    // MARK: - Permissions

    /// Returns true if both speech recognition and microphone access are granted.
    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }

        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording

    /// Starts a recognition session and returns a stream of partial transcripts.
    /// Call stopListening() to end the session and get the final text.
    func startListening() throws -> AsyncStream<String> {
        stopListening()

        let recognizer = SFSpeechRecognizer(locale: .current)
        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        return AsyncStream { continuation in
            self.recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
                if let result {
                    continuation.yield(result.bestTranscription.formattedString)
                    if result.isFinal { continuation.finish() }
                } else if error != nil {
                    continuation.finish()
                }
            }
        }
    }

    /// Stops the recognition session and returns the best transcript so far.
    @discardableResult
    func stopListening() -> String {
        let transcript = recognitionTask?.result?.bestTranscription.formattedString ?? ""
        recognitionTask?.cancel()
        recognitionTask = nil
        request?.endAudio()
        request = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        recognizer = nil
        return transcript
    }
}
