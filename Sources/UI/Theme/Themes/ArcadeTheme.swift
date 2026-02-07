//
//  ArcadeTheme.swift
//  STASH
//
//  Arcade theme: Neon colors, retro-inspired, energetic
//

import SwiftUI

struct ArcadeTheme: ThemeVariant {
    let name = "arcade"
    let displayName = "Arcade"

    // Colors - Neon palette
    let primaryColor = Color(red: 0.0, green: 0.9, blue: 1.0) // Electric cyan
    let accentColor = Color(red: 1.0, green: 0.2, blue: 0.8)  // Hot pink
    let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.15)
    let surfaceColor = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textColor = Color.white
    let secondaryTextColor = Color(red: 0.7, green: 0.7, blue: 0.9)

    // Typography - Bold, energetic
    let headingWeight = Font.Weight.black
    let bodyWeight = Font.Weight.semibold

    // Visual Effects - Pronounced glow
    let cornerRadius: CGFloat = 12
    let shadowRadius: CGFloat = 8
    let animationDuration: Double = 0.15
}
