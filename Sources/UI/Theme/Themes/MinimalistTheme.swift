//
//  MinimalistTheme.swift
//  PersonalAI
//
//  Minimalist theme: Clean lines, monochromatic, low distraction
//

import SwiftUI

struct MinimalistTheme: ThemeVariant {
    let name = "minimalist"
    let displayName = "Minimalist"

    // Colors - Monochromatic grayscale palette
    let primaryColor = Color.gray
    let accentColor = Color(white: 0.3)
    let backgroundColor = Color(white: 0.98)
    let surfaceColor = Color.white
    let textColor = Color(white: 0.15)
    let secondaryTextColor = Color(white: 0.5)

    // Typography - Clean, readable
    let headingWeight = Font.Weight.semibold
    let bodyWeight = Font.Weight.regular

    // Visual Effects - Subtle
    let cornerRadius: CGFloat = 8
    let shadowRadius: CGFloat = 2
    let animationDuration: Double = 0.2
}
