//
//  AnalyticsService.swift
//  STASH
//
//  Wraps TelemetryDeck. All opt-out logic lives here.
//  To swap analytics providers: update track() only.
//

import Foundation
import TelemetryDeck

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
        let config = TelemetryManagerConfiguration(appID: "9893DF09-028C-4E41-84A6-2191465CC1EC")
        TelemetryDeck.initialize(config: config)
    }

    func track(_ event: AnalyticsEvent) {
        guard !isOptedOut else { return }
        TelemetryDeck.signal(event.signalName, parameters: event.metadata)
    }
}
