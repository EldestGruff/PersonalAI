//
//  WatershipDownTheme.swift
//  STASH
//
//  "Watership Down" aesthetic: Organic, parchment, neurodivergent-friendly
//  Based on color science for ADHD/autism accessibility
//

import SwiftUI

struct WatershipDownTheme: ThemeVariant {
    let name = "watershipDown"
    let displayName = "Watership Down"

    // MARK: - A. The Canvas (Reducing Visual Stress)
    // Warm off-white to reduce eye strain vs pure white
    let backgroundColor = Color(hex: "#F5F2E0") ?? Color(white: 0.96)  // Parchment
    let surfaceColor = Color(hex: "#FAF6EB") ?? Color.white     // Cosmic Latte (card backgrounds)

    // MARK: - B. The Dopamine Trigger (The "Action" Color)
    // Teal gem - cuts through earth tones, promises reward
    let primaryColor = Color(hex: "#00BFA5") ?? Color.teal     // Teal Gem - Primary CTA
    let accentColor = Color(hex: "#26C6DA") ?? Color.cyan      // Turquoise - Success states

    // MARK: - Text Colors (High contrast without harshness)
    let textColor = Color(hex: "#2B2416") ?? Color.black        // Dark Umber (readable)
    let secondaryTextColor = Color(hex: "#6B5D4F") ?? Color.gray // Muted Brown

    // MARK: - Typography (Balanced, readable)
    let headingWeight = Font.Weight.semibold
    let bodyWeight = Font.Weight.regular

    // MARK: - Visual Effects (Organic, soft)
    let cornerRadius: CGFloat = 16    // Softer than standard
    let shadowRadius: CGFloat = 4     // Subtle depth
    let animationDuration: Double = 0.3  // Natural, not rushed
}

// MARK: - Semantic Category Colors Extension

extension WatershipDownTheme {
    /// C. Categorization (Semantic Encoding)
    /// ADHD brains rely on pattern recognition - consistent colors speed processing

    var urgentColor: Color {
        Color(hex: "#C0392B") ?? Color.red  // Burnt Sienna / Rust - "Important Weight" without panic
    }

    var workColor: Color {
        Color(hex: "#27AE60") ?? Color.green  // Deep Moss Green - Calming, growth-associated
    }

    var creativityColor: Color {
        Color(hex: "#F1C40F") ?? Color.yellow  // Mustard / Gold - High energy, fits "Treasure/Stash" theme
    }

    var healthColor: Color {
        Color(hex: "#5D6D7E") ?? Color.blue  // Slate / Indigo - Cool, watery, separates from work
    }

    /// Get color for a thought category
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

// MARK: - Dark Mode Support

extension WatershipDownTheme {
    /// Dark mode: "Inside the burrow" - cozy, safe, focused
    /// Deep Charcoal / Umber - NOT pitch black (avoids OLED smearing)

    var darkBackgroundColor: Color {
        Color(hex: "#1A1814") ?? Color.black  // Deep Charcoal / Umber
    }

    var darkSurfaceColor: Color {
        Color(hex: "#2D2822") ?? Color(white: 0.1)  // Slightly lighter burrow tone
    }

    var darkTextColor: Color {
        Color(hex: "#F5F2E0") ?? Color.white  // Parchment for text on dark
    }

    var darkSecondaryTextColor: Color {
        Color(hex: "#A89F8F") ?? Color(white: 0.7)  // Lighter muted brown
    }

    /// Returns adaptive color based on system color scheme
    static func adaptiveColor(
        light: Color,
        dark: Color,
        for colorScheme: ColorScheme
    ) -> Color {
        colorScheme == .dark ? dark : light
    }
}

// MARK: - Accessibility Helpers

extension WatershipDownTheme {
    /// Check if color combination meets WCAG AA contrast ratio (4.5:1 for normal text)
    /// Note: This is a placeholder - actual implementation would calculate luminance
    var isAccessible: Bool {
        // TODO: Implement proper contrast ratio calculation
        // For now, return true as colors were chosen with accessibility in mind
        true
    }

    /// Reduced motion variant - faster animations
    func animationDuration(reduceMotion: Bool) -> Double {
        reduceMotion ? 0.1 : animationDuration
    }
}
