//
//  ThemeVariant.swift
//  PersonalAI
//
//  Protocol defining visual theme variants for squirrel-sona customization
//

import SwiftUI

// MARK: - Theme Variant Protocol

protocol ThemeVariant {
    var name: String { get }
    var displayName: String { get }

    // Colors
    var primaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }

    // Typography
    var headingWeight: Font.Weight { get }
    var bodyWeight: Font.Weight { get }

    // Visual Effects
    var cornerRadius: CGFloat { get }
    var shadowRadius: CGFloat { get }
    var animationDuration: Double { get }
}

// MARK: - Theme Type Enum

enum ThemeType: String, Codable, CaseIterable, Identifiable {
    case minimalist
    case arcade
    case darkMode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimalist: return "Minimalist"
        case .arcade: return "Arcade"
        case .darkMode: return "Dark Mode"
        }
    }

    var emoji: String {
        switch self {
        case .minimalist: return "🎨"
        case .arcade: return "🕹️"
        case .darkMode: return "🌙"
        }
    }

    var theme: any ThemeVariant {
        switch self {
        case .minimalist: return MinimalistTheme()
        case .arcade: return ArcadeTheme()
        case .darkMode: return DarkModeTheme()
        }
    }
}
