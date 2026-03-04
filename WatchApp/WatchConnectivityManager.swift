//
//  WatchConnectivityManager.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Watch-side WCSession delegate. Flushes the offline queue whenever
//  the session is active. Uses transferUserInfo for reliable delivery —
//  the OS queues transfers and delivers them even when the phone app
//  is in the background or temporarily unreachable.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, Sendable {
    static let shared = WatchConnectivityManager()

    private override init() {}

    // MARK: - Session Activation

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Queue Flushing

    /// Submits every pending queue item to WCSession.
    /// Each item uses transferUserInfo (queued, reliable, no reachability required).
    func flushQueue() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        Task {
            let items = await WatchQueueManager.shared.all()
            for item in items {
                let payload: [String: Any] = [
                    "id": item.id.uuidString,
                    "text": item.text,
                    "capturedAt": item.capturedAt.timeIntervalSince1970
                ]
                session.transferUserInfo(payload)
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if activationState == .activated {
            flushQueue()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            flushQueue()
        }
    }

    /// Called when a transferUserInfo completes (success or failure).
    /// On success: remove from the local queue.
    /// On failure: leave in queue for next flush attempt.
    func session(
        _ session: WCSession,
        didFinishUserInfoTransfer transfer: WCSessionUserInfoTransfer,
        error: Error?
    ) {
        guard error == nil else { return }
        guard
            let idString = transfer.userInfo["id"] as? String,
            let id = UUID(uuidString: idString)
        else { return }

        Task {
            await WatchQueueManager.shared.remove(id)
        }
    }
}
