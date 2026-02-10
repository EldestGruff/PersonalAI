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

// MARK: - Themed Input Modifier

/// Modifier for TextField and TextEditor styling with consistent theme appearance.
/// Applies input background, border, and corner radius from the current theme.
struct ThemedInputModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Whether to show the border around the input
    var showBorder: Bool

    init(showBorder: Bool = true) {
        self.showBorder = showBorder
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(theme.inputBackgroundColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.inputBorderColor, lineWidth: theme.borderWidth)
                    }
                }
            )
    }
}

// MARK: - Themed List Row Modifier

/// Modifier for list/card items like thought rows.
/// Provides surface color background, padding, corner radius, shadow, and optional divider.
struct ThemedListRowModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Whether to show a divider at the bottom
    var showDivider: Bool

    /// Custom padding amount (uses default if nil)
    var padding: CGFloat?

    init(showDivider: Bool = false, padding: CGFloat? = nil) {
        self.showDivider = showDivider
        self.padding = padding
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 0) {
            content
                .padding(padding ?? 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surfaceColor)
                .cornerRadius(theme.cornerRadius)
                .shadow(radius: theme.shadowRadius)

            if showDivider {
                Divider()
                    .background(theme.dividerColor)
            }
        }
    }
}

// MARK: - Themed Section Modifier

/// Modifier for Form sections and grouped content.
/// Applies section background, padding, and corner radius for consistent grouping.
struct ThemedSectionModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Custom padding amount (uses default if nil)
    var padding: CGFloat?

    init(padding: CGFloat? = nil) {
        self.padding = padding
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .padding(padding ?? 16)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius)
    }
}

// MARK: - Themed Badge Modifier

/// Modifier for tags, classifications, and status indicators.
/// Creates a capsule-shaped badge with appropriate colors and sizing.
struct ThemedBadgeModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Badge style variant
    var style: ThemedBadgeStyle

    init(style: ThemedBadgeStyle = .default) {
        self.style = style
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        let (backgroundColor, foregroundColor) = colorsForStyle(theme: theme)

        content
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private func colorsForStyle(theme: any ThemeVariant) -> (Color, Color) {
        switch style {
        case .default:
            return (theme.tagBackgroundColor, theme.tagTextColor)
        case .success:
            return (theme.successColor.opacity(0.15), theme.successColor)
        case .warning:
            return (theme.warningColor.opacity(0.15), theme.warningColor)
        case .error:
            return (theme.errorColor.opacity(0.15), theme.errorColor)
        case .info:
            return (theme.infoColor.opacity(0.15), theme.infoColor)
        case .custom(let background, let foreground):
            return (background, foreground)
        }
    }
}

/// Style variants for themed badges
enum ThemedBadgeStyle {
    case `default`
    case success
    case warning
    case error
    case info
    case custom(background: Color, foreground: Color)
}

// MARK: - Themed Icon Modifier

/// Modifier for SF Symbols with consistent theme colors and sizing.
/// Supports primary and secondary icon colors with size variants.
struct ThemedIconModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Icon size variant
    var size: ThemedIconSize

    /// Whether to use secondary (muted) icon color
    var isSecondary: Bool

    init(size: ThemedIconSize = .medium, isSecondary: Bool = false) {
        self.size = size
        self.isSecondary = isSecondary
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .font(.system(size: size.pointSize))
            .foregroundColor(isSecondary ? theme.iconSecondaryColor : theme.iconColor)
    }
}

/// Size variants for themed icons
enum ThemedIconSize {
    case small
    case medium
    case large

    var pointSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 20
        case .large: return 28
        }
    }
}

// MARK: - Themed Divider Modifier

/// Modifier for separators with consistent theme colors.
/// Supports optional custom thickness.
struct ThemedDividerModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Custom thickness (uses 1pt if nil)
    var thickness: CGFloat?

    init(thickness: CGFloat? = nil) {
        self.thickness = thickness
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .frame(height: thickness ?? 1)
            .background(theme.dividerColor)
    }
}

/// A themed divider view component for easy standalone use
struct ThemedDivider: View {
    @Environment(\.themeEngine) var themeEngine

    /// Custom thickness (uses 1pt if nil)
    var thickness: CGFloat?

    init(thickness: CGFloat? = nil) {
        self.thickness = thickness
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        Rectangle()
            .fill(theme.dividerColor)
            .frame(height: thickness ?? 1)
    }
}

// MARK: - Themed Navigation Modifier

/// Modifier for navigation bar styling with consistent theme appearance.
/// Applies navigation bar background and configures title colors.
struct ThemedNavigationModifier: ViewModifier {
    @Environment(\.themeEngine) var themeEngine

    /// Whether to use inline display mode
    var inline: Bool

    init(inline: Bool = false) {
        self.inline = inline
    }

    func body(content: Content) -> some View {
        let theme = themeEngine.getCurrentTheme()

        content
            .toolbarBackground(theme.navigationBarBackgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.backgroundColor.isDark ? .dark : .light, for: .navigationBar)
            .navigationBarTitleDisplayMode(inline ? .inline : .large)
    }
}

// MARK: - Color Extension for Dark Mode Detection

private extension Color {
    /// Determines if a color is considered "dark" for contrast purposes
    var isDark: Bool {
        // Convert to UIColor to get luminance components
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate relative luminance using sRGB formula
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance < 0.5
    }
}

// MARK: - View Extensions for New Modifiers

extension View {
    /// Applies themed input field styling (background, border, corner radius)
    /// - Parameter showBorder: Whether to display the border (default: true)
    func themedInput(showBorder: Bool = true) -> some View {
        modifier(ThemedInputModifier(showBorder: showBorder))
    }

    /// Applies themed list row styling (surface background, padding, corner radius, shadow)
    /// - Parameters:
    ///   - showDivider: Whether to show a divider at the bottom (default: false)
    ///   - padding: Custom padding amount (uses default 16pt if nil)
    func themedListRow(showDivider: Bool = false, padding: CGFloat? = nil) -> some View {
        modifier(ThemedListRowModifier(showDivider: showDivider, padding: padding))
    }

    /// Applies themed section styling for grouped content
    /// - Parameter padding: Custom padding amount (uses default 16pt if nil)
    func themedSection(padding: CGFloat? = nil) -> some View {
        modifier(ThemedSectionModifier(padding: padding))
    }

    /// Applies themed badge styling for tags and status indicators
    /// - Parameter style: The badge style variant (default: .default)
    func themedBadge(style: ThemedBadgeStyle = .default) -> some View {
        modifier(ThemedBadgeModifier(style: style))
    }

    /// Applies themed icon styling with consistent colors and sizing
    /// - Parameters:
    ///   - size: The icon size variant (default: .medium)
    ///   - isSecondary: Whether to use secondary icon color (default: false)
    func themedIcon(size: ThemedIconSize = .medium, isSecondary: Bool = false) -> some View {
        modifier(ThemedIconModifier(size: size, isSecondary: isSecondary))
    }

    /// Applies themed divider styling
    /// - Parameter thickness: Custom thickness (uses 1pt if nil)
    func themedDivider(thickness: CGFloat? = nil) -> some View {
        modifier(ThemedDividerModifier(thickness: thickness))
    }

    /// Applies themed navigation bar styling
    /// - Parameter inline: Whether to use inline display mode (default: false)
    func themedNavigation(inline: Bool = false) -> some View {
        modifier(ThemedNavigationModifier(inline: inline))
    }
}
