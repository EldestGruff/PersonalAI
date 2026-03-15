//
//  AnalyticsService.swift
//  STASH
//
//  Wraps TelemetryDeck. All opt-out logic lives here.
//  To swap analytics providers: update track() only.
//

import Foundation
import TelemetryDeck

// @unchecked Sendable: thread safety guaranteed by UserDefaults (internally locked)
// and TelemetryDeck SDK (handles its own thread safety). No mutable state beyond
// UserDefaults reads/writes.
final class AnalyticsService: @unchecked Sendable {
    static let shared = AnalyticsService()

    private let optOutKey = "analytics.optOut"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isOptedOut: Bool {
        get { defaults.bool(forKey: optOutKey) }
        set { defaults.set(newValue, forKey: optOutKey) }
    }

    func initialize() {
        guard !isOptedOut else { return }
        let config = TelemetryManagerConfiguration(appID: AppConstants.Analytics.telemetryDeckAppID)
        TelemetryDeck.initialize(config: config)
    }

    func track(_ event: AnalyticsEvent) {
        guard !isOptedOut else { return }
        TelemetryDeck.signal(event.signalName, parameters: event.metadata)
    }
}
