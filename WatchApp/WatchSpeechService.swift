//
//  WatchSpeechService.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Records voice on the Watch using AVAudioRecorder.
//  The recorded audio file is transferred to iPhone via WatchConnectivity,
//  where SFSpeechRecognizer transcribes it and saves the thought.
//  This keeps Speech framework off the Watch target entirely.
//

import Foundation
import AVFoundation

// MARK: - Watch Audio Recorder

actor WatchSpeechService {
    static let shared = WatchSpeechService()

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        recordingURL = url
    }

    /// Stops recording and returns the audio file URL (nil if nothing was recorded).
    func stopRecording() -> URL? {
        recorder?.stop()
        recorder = nil
        let url = recordingURL
        recordingURL = nil
        return url
    }

    /// Returns the current audio level (0.0–1.0) for waveform animation.
    func currentPower() -> Float {
        guard let recorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        // Convert dBFS to 0-1 range (-60 dBFS = silence, 0 dBFS = max)
        let db = recorder.averagePower(forChannel: 0)
        return max(0, min(1, (db + 60) / 60))
    }
}
