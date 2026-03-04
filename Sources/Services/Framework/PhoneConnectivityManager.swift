//
//  PhoneConnectivityManager.swift
//  STASH
//
//  Issue #58: Apple Watch companion app — iPhone side
//
//  Receives thought payloads from the Apple Watch via WatchConnectivity
//  and persists them through ThoughtService for normal classification
//  and storage. Classification runs on iPhone, not Watch.
//
//  Activate in STASHApp.init() alongside other service bootstrapping.
//

import Foundation
import WatchConnectivity

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
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    // Required on iOS (not watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate after handoff (e.g. paired Watch swap)
        WCSession.default.activate()
    }

    // MARK: - Receive Watch Thoughts

    /// Called when the Watch delivers a queued thought payload.
    /// Creates a Thought and saves it via ThoughtService.
    /// Classification happens normally on the iPhone side.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard
            let idString = userInfo["id"] as? String,
            let id = UUID(uuidString: idString),
            let text = userInfo["text"] as? String,
            let timestamp = userInfo["capturedAt"] as? TimeInterval
        else { return }

        let capturedAt = Date(timeIntervalSince1970: timestamp)

        Task {
            do {
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
                    id: id,
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
                // Delivery is guaranteed by WCSession — if persistence fails,
                // the thought is lost. Log for analytics and move on.
                AnalyticsService.shared.track(.coreDataError(operation: "watch_thought_receive"))
            }
        }
    }
}
