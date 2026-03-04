//
//  PhoneConnectivityManager.swift
//  STASH
//
//  Issue #58: Apple Watch companion app — iPhone side
//
//  Receives audio files recorded on the Apple Watch, transcribes them
//  with SFSpeechRecognizer, and saves the resulting thought via ThoughtService.
//  Classification runs normally on iPhone, not Watch.
//
//  Activate in STASHApp.init() alongside other service bootstrapping.
//

import Foundation
import WatchConnectivity
import Speech

// MARK: - Phone Connectivity Manager

final class PhoneConnectivityManager: NSObject {
    static let shared = PhoneConnectivityManager()

    private override init() {}

    // MARK: - Setup

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Transcription

    private func transcribe(audioURL: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: .current)
        guard recognizer?.isAvailable == true else {
            throw TranscriptionError.unavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.requiresOnDeviceRecognition = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    private enum TranscriptionError: Error {
        case unavailable
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    // MARK: - Receive Watch Audio

    /// Called when the Watch delivers a recorded audio file.
    /// Transcribes → creates Thought → saves via ThoughtService.
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let capturedAt: Date
        if let ts = file.metadata?["capturedAt"] as? TimeInterval {
            capturedAt = Date(timeIntervalSince1970: ts)
        } else {
            capturedAt = Date()
        }

        // Copy to a stable location before the system cleans up the received file
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(file.fileURL.pathExtension)

        do {
            try FileManager.default.copyItem(at: file.fileURL, to: dest)
        } catch {
            AnalyticsService.shared.track(.coreDataError(operation: "watch_file_copy"))
            return
        }

        Task {
            do {
                let text = try await transcribe(audioURL: dest)
                try FileManager.default.removeItem(at: dest)

                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

                let context = Context(
                    timestamp: capturedAt,
                    location: nil,
                    timeOfDay: TimeOfDay.from(date: capturedAt),
                    energy: .medium,
                    focusState: .scattered,
                    calendar: nil,
                    activity: nil,
                    weather: nil,
                    stateOfMind: nil,
                    energyBreakdown: nil
                )
                let thought = Thought(
                    id: UUID(),
                    userId: UUID(),
                    content: text,
                    attributedContent: nil,
                    tags: [],
                    status: .active,
                    context: context,
                    createdAt: capturedAt,
                    updatedAt: capturedAt,
                    classification: nil,
                    relatedThoughtIds: [],
                    taskId: nil
                )
                _ = try await ThoughtService.shared.create(thought)
            } catch {
                AnalyticsService.shared.track(.coreDataError(operation: "watch_thought_create"))
                try? FileManager.default.removeItem(at: dest)
            }
        }
    }
}
