//
//  LiquidGlassModifiers.swift
//  PersonalAI
//
//  iOS 26 Liquid Glass design system integration
//

import SwiftUI

// MARK: - Glass Intensity Levels

enum GlassIntensity {
    case subtle      // 0.2 - Background cards
    case medium      // 0.5 - Primary UI elements
    case prominent   // 0.8 - Modals and overlays

    var tintOpacity: Double {
        switch self {
        case .subtle: return 0.2
        case .medium: return 0.5
        case .prominent: return 0.8
        }
    }
}

// MARK: - Glass Tint Colors

enum GlassTint {
    case ai          // Purple gradient for AI features
    case health      // Blue/green gradient for health
    case insights    // Orange/yellow gradient for insights
    case adaptive    // Adaptive system tint
    case custom(Color)

    var color: Color {
        switch self {
        case .ai: return .purple
        case .health: return .blue
        case .insights: return .orange
        case .adaptive: return .accentColor
        case .custom(let color): return color
        }
    }
}

// MARK: - View Extensions

@available(iOS 26.0, *)
extension View {

    /// Apply liquid glass effect with intensity and tint
    func liquidGlass(
        intensity: GlassIntensity = .medium,
        tint: GlassTint = .adaptive,
        shape: some Shape = .capsule
    ) -> some View {
        self.glassEffect(
            .regular.tint(tint.color.opacity(intensity.tintOpacity)),
            in: shape
        )
    }

    /// Apply interactive liquid glass (iOS only)
    func liquidGlassInteractive(
        intensity: GlassIntensity = .medium,
        tint: GlassTint = .adaptive,
        shape: some Shape = .capsule
    ) -> some View {
        self.glassEffect(
            .regular.tint(tint.color.opacity(intensity.tintOpacity)).interactive(),
            in: shape
        )
    }

    /// Apply clear glass for media-rich backgrounds
    func liquidGlassClear(
        tint: GlassTint = .adaptive,
        shape: some Shape = .capsule
    ) -> some View {
        self.glassEffect(
            .clear.tint(tint.color.opacity(0.3)),
            in: shape
        )
    }

    /// Conditionally apply glass based on accessibility settings
    func liquidGlassAccessible(
        intensity: GlassIntensity = .medium,
        tint: GlassTint = .adaptive,
        shape: some Shape = .capsule
    ) -> some View {
        GlassAccessibleWrapper(
            intensity: intensity,
            tint: tint,
            shape: shape,
            content: self
        )
    }
}

// MARK: - Accessibility Wrapper

@available(iOS 26.0, *)
private struct GlassAccessibleWrapper<Content: View, S: Shape>: View {
    let intensity: GlassIntensity
    let tint: GlassTint
    let shape: S
    let content: Content

    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        content
            .glassEffect(
                reduceTransparency ? .identity : .regular.tint(tint.color.opacity(intensity.tintOpacity)),
                in: shape
            )
    }
}

// MARK: - Reusable Glass Containers

@available(iOS 26.0, *)
struct LiquidGlassCard<Content: View>: View {
    let intensity: GlassIntensity
    let tint: GlassTint
    let cornerRadius: CGFloat
    let content: Content

    init(
        intensity: GlassIntensity = .medium,
        tint: GlassTint = .adaptive,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .liquidGlass(
                intensity: intensity,
                tint: tint,
                shape: RoundedRectangle(cornerRadius: cornerRadius)
            )
    }
}

@available(iOS 26.0, *)
struct LiquidGlassOverlay<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer {
            content
        }
        .liquidGlass(
            intensity: .prominent,
            tint: .adaptive,
            shape: RoundedRectangle(cornerRadius: 24)
        )
    }
}
