//
//  ThemeModifiers.swift
//  STASH
//
//  SwiftUI view modifiers for applying themes
//

import SwiftUI

// MARK: - Themed Card Modifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius)
            .shadow(radius: theme.shadowRadius)
    }
}

// MARK: - Themed Text Modifier

struct ThemedTextModifier: ViewModifier {
    let style: ThemedTextStyle
    @Environment(\.themeEngine) var themeEngine

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        switch style {
        case .heading:
            content
                .fontWeight(theme.headingWeight)
                .foregroundColor(theme.textColor)
        case .body:
            content
                .fontWeight(theme.bodyWeight)
                .foregroundColor(theme.textColor)
        case .secondary:
            content
                .fontWeight(theme.bodyWeight)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

enum ThemedTextStyle {
    case heading
    case body
    case secondary
}

// MARK: - Themed Button Modifier

struct ThemedButtonModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .padding()
            .background(theme.accentColor)
            .foregroundColor(.white)
            .cornerRadius(theme.cornerRadius)
            .shadow(radius: theme.shadowRadius)
    }
}

// MARK: - Themed Background Modifier

struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .background(theme.backgroundColor)
    }
}

// MARK: - View Extensions

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedText(style: ThemedTextStyle = .body) -> some View {
        modifier(ThemedTextModifier(style: style))
    }

    func themedButton() -> some View {
        modifier(ThemedButtonModifier())
    }

    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}
