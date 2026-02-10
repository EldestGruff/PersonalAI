//
//  ThemeVariant.swift
//  STASH
//
//  Protocol defining visual theme variants for squirrel-sona customization.
//
//  This protocol provides a comprehensive theming system that supports:
//  - Standard themes (minimalist, dark mode)
//  - Extreme themes (terminal/hacker, retro arcade, minimalist sketch)
//  - Full accessibility and semantic color support
//
//  All properties have sensible defaults in the protocol extension,
//  allowing themes to override only what they need.
//

import SwiftUI

// MARK: - Theme Variant Protocol

protocol ThemeVariant {
    var name: String { get }
    var displayName: String { get }

    // MARK: - Core Colors

    var primaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }

    // MARK: - Semantic UI Colors

    /// Status/feedback colors
    var errorColor: Color { get }
    var successColor: Color { get }
    var warningColor: Color { get }
    var infoColor: Color { get }

    /// Interactive element colors
    var buttonBackgroundColor: Color { get }
    var buttonForegroundColor: Color { get }
    var linkColor: Color { get }

    /// Icon colors
    var iconColor: Color { get }
    var iconSecondaryColor: Color { get }

    /// Input field colors
    var inputBackgroundColor: Color { get }
    var inputBorderColor: Color { get }
    var placeholderColor: Color { get }

    /// Tag/chip colors
    var tagBackgroundColor: Color { get }
    var tagTextColor: Color { get }

    /// Navigation colors
    var navigationBarBackgroundColor: Color { get }
    var tabBarBackgroundColor: Color { get }

    /// Structural colors
    var dividerColor: Color { get }

    // MARK: - Typography

    var headingWeight: Font.Weight { get }
    var bodyWeight: Font.Weight { get }

    /// Font families for different text styles
    /// Themes can override these for custom typography (e.g., Terminal theme uses monospace)
    var headingFont: Font { get }
    var bodyFont: Font { get }
    var captionFont: Font { get }

    /// Monospaced font for code/terminal displays
    /// Essential for terminal/hacker themes
    var monospacedFont: Font { get }

    // MARK: - Visual Effects

    var cornerRadius: CGFloat { get }
    var shadowRadius: CGFloat { get }
    var animationDuration: Double { get }

    /// Glow color for neon/arcade effects
    /// Used for glowing borders, text effects, and highlights
    var glowColor: Color { get }

    /// Border width for outlined elements
    /// Terminal/arcade themes often use thicker borders
    var borderWidth: CGFloat { get }

    /// Whether the theme uses glassmorphism/blur effects
    /// Enables frosted glass backgrounds on supporting themes
    var usesGlassEffect: Bool { get }
}

// MARK: - Default Implementations

extension ThemeVariant {

    // MARK: - Semantic UI Color Defaults

    /// Error/destructive action color - defaults to a standard red
    var errorColor: Color { Color(red: 0.86, green: 0.21, blue: 0.27) }

    /// Success/confirmation color - defaults to a standard green
    var successColor: Color { Color(red: 0.20, green: 0.78, blue: 0.35) }

    /// Warning/caution color - defaults to a standard orange
    var warningColor: Color { Color(red: 1.0, green: 0.58, blue: 0.0) }

    /// Informational color - defaults to primary color
    var infoColor: Color { primaryColor }

    /// Button background - defaults to primary color
    var buttonBackgroundColor: Color { primaryColor }

    /// Button text/icon color - defaults to white for contrast
    var buttonForegroundColor: Color { .white }

    /// Link/tappable text color - defaults to primary color
    var linkColor: Color { primaryColor }

    /// Primary icon color - defaults to text color for visibility
    var iconColor: Color { textColor }

    /// Secondary/muted icon color - defaults to secondary text color
    var iconSecondaryColor: Color { secondaryTextColor }

    /// Input field background - defaults to surface color
    var inputBackgroundColor: Color { surfaceColor }

    /// Input field border - defaults to a subtle version of secondary text
    var inputBorderColor: Color { secondaryTextColor.opacity(0.3) }

    /// Placeholder text color - defaults to secondary text color
    var placeholderColor: Color { secondaryTextColor }

    /// Tag/chip background - defaults to primary color at low opacity
    var tagBackgroundColor: Color { primaryColor.opacity(0.15) }

    /// Tag/chip text color - defaults to primary color
    var tagTextColor: Color { primaryColor }

    /// Navigation bar background - defaults to surface color
    var navigationBarBackgroundColor: Color { surfaceColor }

    /// Tab bar background - defaults to surface color
    var tabBarBackgroundColor: Color { surfaceColor }

    /// Divider/separator color - defaults to subtle secondary text
    var dividerColor: Color { secondaryTextColor.opacity(0.2) }

    // MARK: - Typography Defaults

    /// Heading font - system font with theme's heading weight
    var headingFont: Font {
        .system(.title, design: .default, weight: headingWeight)
    }

    /// Body font - system font with theme's body weight
    var bodyFont: Font {
        .system(.body, design: .default, weight: bodyWeight)
    }

    /// Caption font - smaller system font with regular weight
    var captionFont: Font {
        .system(.caption, design: .default, weight: .regular)
    }

    /// Monospaced font - for code, terminal output, and data display
    var monospacedFont: Font {
        .system(.body, design: .monospaced, weight: bodyWeight)
    }

    // MARK: - Advanced Effects Defaults

    /// Glow color - defaults to primary color for neon effects
    /// Themes like Arcade can override for custom glow colors
    var glowColor: Color { primaryColor }

    /// Border width - defaults to 1pt for subtle borders
    /// Terminal/hacker themes may use thicker borders (2-3pt)
    var borderWidth: CGFloat { 1.0 }

    /// Glass effect toggle - disabled by default
    /// Enable for themes that want frosted glass/blur effects
    var usesGlassEffect: Bool { false }

    // MARK: - Category Colors (Existing)

    /// Semantic category colors (default fallbacks for themes that don't define them)
    var urgentColor: Color { primaryColor }
    var workColor: Color { accentColor }
    var creativityColor: Color { primaryColor }
    var healthColor: Color { accentColor }

    // MARK: - Dark Mode Support (Existing)

    /// Dark mode support (default fallbacks)
    var darkBackgroundColor: Color { Color.black }
    var darkSurfaceColor: Color { Color(white: 0.1) }
    var darkTextColor: Color { Color.white }
    var darkSecondaryTextColor: Color { Color(white: 0.7) }

    // MARK: - Helper Methods

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
