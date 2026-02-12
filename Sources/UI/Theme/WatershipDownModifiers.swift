//
//  WatershipDownModifiers.swift
//  STASH
//
//  Custom view modifiers for "Watership Down" aesthetic
//  Parchment cards, category color bars, organic styling
//

import SwiftUI

// MARK: - Parchment Card Modifier

/// Creates a "parchment scrap" card with optional category color bar
/// Follows "Squint Test" clarity principle for ADHD brains
struct ParchmentCardModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine
    @Environment(\.colorScheme) var colorScheme

    let category: String?
    let showCategoryBar: Bool

    init(category: String? = nil, showCategoryBar: Bool = true) {
        self.category = category
        self.showCategoryBar = showCategoryBar
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .padding()
            .background(
                ZStack(alignment: .leading) {
                    // Base parchment card
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(surfaceColor(theme))

                    // Category color bar on left edge (if enabled)
                    if showCategoryBar, category != nil {
                        categoryBar(theme)
                    }

                    // TODO: Add parchment texture overlay when asset is available
                    // Image("parchment_texture")
                    //     .resizable(resizingMode: .tile)
                    //     .opacity(0.15)
                    //     .blendMode(.multiply)
                    //     .allowsHitTesting(false)
                }
            )
            .shadow(
                color: Color.black.opacity(0.08),
                radius: theme.shadowRadius,
                x: 2,
                y: 2
            )
    }

    // MARK: - Helper Views

    private func surfaceColor(_ theme: any ThemeVariant) -> Color {
        // Use dark mode surface if in dark mode and theme supports it
        if colorScheme == .dark,
           let watershipTheme = theme as? WatershipDownTheme {
            return watershipTheme.darkSurfaceColor
        }
        return theme.surfaceColor
    }

    private func categoryBar(_ theme: any ThemeVariant) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(theme.colorForCategory(category))
                .frame(width: 6)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: theme.cornerRadius,
                        bottomLeadingRadius: theme.cornerRadius
                    )
                )
            Spacer()
        }
    }
}

// MARK: - Category Badge Modifier

/// Creates an organic "pill" badge for categories
/// Follows semantic color encoding for pattern recognition
struct CategoryBadgeModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    let category: String
    let variant: BadgeVariant

    enum BadgeVariant {
        case filled
        case outlined
        case subtle
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()
        let categoryColor = theme.colorForCategory(category)

        content
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor(categoryColor))
            .foregroundColor(foregroundColor(categoryColor))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor(categoryColor), lineWidth: variant == .outlined ? 1.5 : 0)
            )
    }

    // MARK: - Helper Methods

    private func backgroundColor(_ color: Color) -> Color {
        switch variant {
        case .filled:
            return color
        case .outlined:
            return Color.clear
        case .subtle:
            return color.opacity(0.15)
        }
    }

    private func foregroundColor(_ color: Color) -> Color {
        switch variant {
        case .filled:
            return .white
        case .outlined, .subtle:
            return color
        }
    }

    private func borderColor(_ color: Color) -> Color {
        variant == .outlined ? color : Color.clear
    }
}

// MARK: - Gem Button Modifier

/// Creates the iconic teal gem "STASH A THOUGHT" button
/// High dopamine trigger - the primary action color
struct GemButtonModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine
    @Environment(\.colorScheme) var colorScheme

    let style: ButtonStyle

    enum ButtonStyle {
        case primary    // Teal gem
        case secondary  // Outlined
        case subtle     // Text only
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(backgroundColor(theme))
            .foregroundColor(foregroundColor(theme))
            .clipShape(Capsule())
            .shadow(
                color: shadowColor(theme),
                radius: style == .primary ? theme.shadowRadius * 2 : 0,
                x: 0,
                y: style == .primary ? 4 : 0
            )
            .overlay(
                Capsule()
                    .strokeBorder(borderColor(theme), lineWidth: style == .secondary ? 2 : 0)
            )
            // TODO: Add gem sparkle animation on tap when asset is available
    }

    // MARK: - Helper Methods

    private func backgroundColor(_ theme: any ThemeVariant) -> Color {
        switch style {
        case .primary:
            return theme.primaryColor
        case .secondary:
            return Color.clear
        case .subtle:
            return Color.clear
        }
    }

    private func foregroundColor(_ theme: any ThemeVariant) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .subtle:
            return theme.primaryColor
        }
    }

    private func shadowColor(_ theme: any ThemeVariant) -> Color {
        theme.primaryColor.opacity(0.3)
    }

    private func borderColor(_ theme: any ThemeVariant) -> Color {
        style == .secondary ? theme.primaryColor : Color.clear
    }
}

// MARK: - Watercolor Accent Modifier

/// Adds a subtle watercolor wash to corners (when asset is available)
struct WatercolorAccentModifier: ViewModifier {
    let category: String?
    let position: Position

    enum Position {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                // TODO: Replace with actual watercolor wash asset
                // For now, use a subtle gradient as placeholder
                placeholderWash
            }
    }

    private var alignment: Alignment {
        switch position {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    @ViewBuilder
    private var placeholderWash: some View {
        // Placeholder until watercolor asset is available
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.gray.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 80, height: 80)
            .allowsHitTesting(false)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply parchment card styling with optional category color bar
    func parchmentCard(category: String? = nil, showCategoryBar: Bool = true) -> some View {
        modifier(ParchmentCardModifier(category: category, showCategoryBar: showCategoryBar))
    }

    /// Create a category badge pill
    func categoryBadge(_ category: String, variant: CategoryBadgeModifier.BadgeVariant = .filled) -> some View {
        modifier(CategoryBadgeModifier(category: category, variant: variant))
    }

    /// Apply gem button styling (the dopamine trigger!)
    func gemButton(style: GemButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(GemButtonModifier(style: style))
    }

    /// Add watercolor accent (placeholder until asset available)
    func watercolorAccent(category: String? = nil, position: WatercolorAccentModifier.Position = .topRight) -> some View {
        modifier(WatercolorAccentModifier(category: category, position: position))
    }
}
