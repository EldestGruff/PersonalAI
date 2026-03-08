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

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

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
        guard session.activationState == .activated else { return }

        let metadata: [String: Any] = [
            "capturedAt": capturedAt.timeIntervalSince1970
        ]
        session.transferFile(fileURL, metadata: metadata)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}


}
