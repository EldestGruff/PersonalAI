//
//  ThemeVariant.swift
//  STASH
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

// MARK: - Optional Protocol Extensions for Advanced Themes

extension ThemeVariant {
    /// Semantic category colors (default fallbacks for themes that don't define them)
    var urgentColor: Color { primaryColor }
    var workColor: Color { accentColor }
    var creativityColor: Color { primaryColor }
    var healthColor: Color { accentColor }

    /// Dark mode support (default fallbacks)
    var darkBackgroundColor: Color { Color.black }
    var darkSurfaceColor: Color { Color(white: 0.1) }
    var darkTextColor: Color { Color.white }
    var darkSecondaryTextColor: Color { Color(white: 0.7) }

    /// Helper to get color for a category string
    func colorForCategory(_ category: String?) -> Color {
        guard let category = category?.lowercased() else { return accentColor }

        switch category {
        case "urgent", "important", "now":
            return urgentColor
        case "work", "focus", "project":
            return workColor
        case "creative", "idea", "brainstorm":
            return creativityColor
        case "health", "wellness", "self-care":
            return healthColor
        default:
            return accentColor
        }
    }
}

// MARK: - Theme Type Enum

enum ThemeType: String, Codable, CaseIterable, Identifiable {
    case minimalist
    case arcade
    case darkMode
    case watershipDown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimalist: return "Minimalist"
        case .arcade: return "Arcade"
        case .darkMode: return "Dark Mode"
        case .watershipDown: return "Watership Down"
        }
    }

    var emoji: String {
        switch self {
        case .minimalist: return "🎨"
        case .arcade: return "🕹️"
        case .darkMode: return "🌙"
        case .watershipDown: return "🐿️"
        }
    }

    var theme: any ThemeVariant {
        switch self {
        case .minimalist: return MinimalistTheme()
        case .arcade: return ArcadeTheme()
        case .darkMode: return DarkModeTheme()
        case .watershipDown: return WatershipDownTheme()
        }
    }
}
