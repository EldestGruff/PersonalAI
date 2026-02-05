//
//  ThemeEngine.swift
//  PersonalAI
//
//  Central theme management and application system
//

import SwiftUI
import Observation

@Observable
class ThemeEngine {
    static let shared = ThemeEngine()

    private let themeKey = "selected_theme"

    var currentTheme: ThemeType {
        didSet {
            saveTheme()
        }
    }

    private init() {
        // Load saved theme or use default
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = ThemeType(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .minimalist
        }
    }

    // MARK: - Theme Management

    func setTheme(_ theme: ThemeType) {
        currentTheme = theme
    }

    func getCurrentTheme() -> any ThemeVariant {
        return currentTheme.theme
    }

    // MARK: - Persistence

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
}

// MARK: - Environment Key

struct ThemeEngineKey: EnvironmentKey {
    static let defaultValue = ThemeEngine.shared
}

extension EnvironmentValues {
    var themeEngine: ThemeEngine {
        get { self[ThemeEngineKey.self] }
        set { self[ThemeEngineKey.self] = newValue }
    }
}
