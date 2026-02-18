//
//  MinimalistTheme.swift
//  STASH
//
//  Minimalist theme: Clean lines, monochromatic, low distraction
//

import SwiftUI

struct MinimalistTheme: ThemeVariant {
    let name = "minimalist"
    let displayName = "Minimalist"

    // Colors - Monochromatic grayscale palette
    let primaryColor = Color(white: 0.2)        // dark enough for clear on-state toggles
    let accentColor = Color(white: 0.2)
    let backgroundColor = Color(white: 0.96)
    let surfaceColor = Color(white: 0.92)       // off-white rows give contrast to toggle tracks
    let textColor = Color(white: 0.1)
    let secondaryTextColor = Color(white: 0.45)

    // Typography - Clean, readable
    let headingWeight = Font.Weight.semibold
    let bodyWeight = Font.Weight.regular

    // Visual Effects - Subtle
    let cornerRadius: CGFloat = 8
    let shadowRadius: CGFloat = 2
    let animationDuration: Double = 0.2
}
