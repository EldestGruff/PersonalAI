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

    /// Backing store — written directly by the external change handler to avoid ping-pong.
    /// @Observable's didSet doesn't expose oldValue/newValue in macro-generated accessors.
    private var _currentTheme: ThemeType

    /// The active theme. Setting via this API persists to KV Store.
    /// External changes write to _currentTheme directly (no write-back loop).
    var currentTheme: ThemeType {
        get { _currentTheme }
        set {
            guard _currentTheme != newValue else { return }
            _currentTheme = newValue
            saveTheme()
        }
    }

    private init() {
        // Initialize backing var directly — computed setter isn't usable before init completes
        if let savedTheme = SyncedDefaults.shared.string(forKey: "selected_theme"),
           let theme = ThemeType(rawValue: savedTheme) {
            self._currentTheme = theme
        } else {
            self._currentTheme = .minimalist
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
                // Write to backing var directly — avoids triggering the computed setter's
                // saveTheme() call, which would write back to KV Store and ping-pong.
                _currentTheme = theme
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
