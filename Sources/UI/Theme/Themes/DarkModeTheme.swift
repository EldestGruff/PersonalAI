//
//  DarkModeTheme.swift
//  PersonalAI
//
//  Dark Mode theme: High contrast, battery-friendly, eye-strain reduction
//

import SwiftUI

struct DarkModeTheme: ThemeVariant {
    let name = "darkMode"
    let displayName = "Dark Mode"

    // Colors - High contrast dark palette
    let primaryColor = Color(red: 0.2, green: 0.6, blue: 1.0) // Bright blue
    let accentColor = Color(red: 0.3, green: 0.8, blue: 0.5)  // Mint green
    let backgroundColor = Color(white: 0.05)
    let surfaceColor = Color(white: 0.12)
    let textColor = Color(white: 0.95)
    let secondaryTextColor = Color(white: 0.6)

    // Typography - Sharp and readable
    let headingWeight = Font.Weight.bold
    let bodyWeight = Font.Weight.medium

    // Visual Effects - Pronounced shadows
    let cornerRadius: CGFloat = 10
    let shadowRadius: CGFloat = 6
    let animationDuration: Double = 0.25
}
