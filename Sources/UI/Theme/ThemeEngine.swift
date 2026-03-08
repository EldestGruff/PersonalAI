//
//  ThemeEngine.swift
//  STASH
//
//  Central theme management and application system.
//  Phase 3B: selected_theme syncs via iCloud KV Store.
//

import SwiftUI
import Observation

@Observable
@MainActor
class ThemeEngine {
    static let shared = ThemeEngine()

    private let themeKey = "selected_theme"
    private let defaults = SyncedDefaults.shared

    var currentTheme: ThemeType {
        didSet {
            // Guard against no-op writes to prevent KV Store ping-pong between devices.
            // Without this, handleExternalChange sets currentTheme → didSet fires → writes
            // the same value back → triggers another external change on the other device.
            guard oldValue != newValue else { return }
            saveTheme()
        }
    }

    private init() {
        // Load saved theme or use default
        if let savedTheme = SyncedDefaults.shared.string(forKey: "selected_theme"),
           let theme = ThemeType(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .minimalist
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange(_:)),
            name: .syncedDefaultsDidChangeExternally,
            object: nil
        )
    }

    // MARK: - Theme Management

    func setTheme(_ theme: ThemeType) {
        currentTheme = theme
        AnalyticsService.shared.track(.themeChanged(theme: theme.rawValue))
    }

    func getCurrentTheme() -> any ThemeVariant {
        return currentTheme.theme
    }

    // MARK: - Persistence

    private func saveTheme() {
        defaults.set(currentTheme.rawValue, forKey: themeKey)
    }

    // MARK: - External Change Handler

    @objc private func handleExternalChange(_ notification: Notification) {
        guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }
        if changedKeys.contains(themeKey) {
            if let rawValue = defaults.string(forKey: themeKey),
               let theme = ThemeType(rawValue: rawValue) {
                currentTheme = theme
            }
        }
    }
}

// MARK: - Environment Key

struct ThemeEngineKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = ThemeEngine.shared
}

extension EnvironmentValues {
    var themeEngine: ThemeEngine {
        get { self[ThemeEngineKey.self] }
        set { self[ThemeEngineKey.self] = newValue }
    }
}
