//
//  WatchConnectivityManager.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Watch-side WCSession delegate.
//  Sends recorded audio files to the iPhone via transferFile.
//  WCSession handles offline queuing automatically — files are held
//  in its outbox and delivered when the iPhone becomes reachable.
//
//  ObservableObject allows WatchCaptureView to reactively display
//  the number of pending (not yet delivered) file transfers.
//  Note: @Observable (Swift Observation macro) conflicts with KVO on NSObject —
//  ObservableObject + @Published is the correct pattern for NSObject subclasses.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    /// Number of audio files queued but not yet delivered to iPhone.
    /// Updated on every transfer enqueue, delivery confirmation, and session activation.
    @Published private(set) var pendingCount: Int = 0

    private override init() {}

    // MARK: - Session Activation

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send Audio

    /// Transfers a recorded audio file to the iPhone.
    /// Metadata carries the capture timestamp; iPhone uses it to timestamp the thought.
    /// WCSession queues the transfer if the phone isn't currently reachable.
    func sendAudio(fileURL: URL, capturedAt: Date = Date()) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            print("[WatchConnectivityManager] sendAudio: session not activated — file not sent")
            return
        }

        let metadata: [String: Any] = [
            "capturedAt": capturedAt.timeIntervalSince1970
        ]
        session.transferFile(fileURL, metadata: metadata)

        // Capture count on WCSession's queue (where it's accurate), then hop to main for @Published
        let count = session.outstandingFileTransfers.count
        DispatchQueue.main.async { [weak self] in
            self?.pendingCount = count
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    // nonisolated is required: WCSession delivers these callbacks on its own
    // internal queue, not the main actor. Without nonisolated, the project-wide
    // MainActor default would make these @MainActor isolated, which WCSession
    // cannot call correctly and would trigger a Swift concurrency warning.

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("[WatchConnectivityManager] Activation error: \(error.localizedDescription)")
        }
        // Restore pending count from previous app launches
        let count = session.outstandingFileTransfers.count
        DispatchQueue.main.async {
            WatchConnectivityManager.shared.pendingCount = count
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didFinishFileTransfer fileTransfer: WCSessionFileTransfer,
        error: Error?
    ) {
        if let error {
            print("[WatchConnectivityManager] File transfer failed: \(error.localizedDescription)")
        }
        // Update count — delivered files are removed from outstandingFileTransfers
        let count = session.outstandingFileTransfers.count
        DispatchQueue.main.async {
            WatchConnectivityManager.shared.pendingCount = count
        }
    }
}
