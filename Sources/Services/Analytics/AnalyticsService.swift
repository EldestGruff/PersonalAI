//
//  AnalyticsService.swift
//  STASH
//
//  Wraps TelemetryDeck. All opt-out logic lives here.
//  To swap analytics providers: update track() only.
//

import Foundation
import TelemetryDeck

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    private let optOutKey = "analytics.optOut"

    var isOptedOut: Bool {
        get { UserDefaults.standard.bool(forKey: optOutKey) }
        set { UserDefaults.standard.set(newValue, forKey: optOutKey) }
    }

    func initialize() {
        let config = TelemetryManagerConfiguration(appID: "9893DF09-028C-4E41-84A6-2191465CC1EC")
        TelemetryDeck.initialize(config: config)
    }

    func track(_ event: AnalyticsEvent) {
        guard !isOptedOut else { return }
        TelemetryDeck.signal(event.signalName, parameters: event.metadata)
    }
}
