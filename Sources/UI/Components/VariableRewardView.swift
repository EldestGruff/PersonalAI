//
//  VariableRewardView.swift
//  STASH
//
//  Tier-appropriate celebration UI for variable reward events.
//  Common → capsule nudge. Legendary → full-card moment with floating emoji.
//

import SwiftUI

// MARK: - Variable Reward View

struct VariableRewardView: View {
    let tier: VRSTier
    @Environment(\.themeEngine) private var themeEngine
    @State private var floatingEmoji: [FloatingEmoji] = []

    var body: some View {
        switch tier {
        case .common:
            commonView
        case .uncommon:
            uncommonView
        case .rare:
            rareView
        case .legendary:
            legendaryView
        }
    }

    // MARK: - Common: simple capsule nudge

    private var commonView: some View {
        let theme = themeEngine.getCurrentTheme()
        return HStack(spacing: 8) {
            Text(tier.emoji)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 1) {
                Text(tier.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textColor)
                Text("+\(tier.acorns) bonus acorns")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(theme.surfaceColor)
            .shadow(color: theme.shadowColor, radius: 6, y: 2))
    }

    // MARK: - Uncommon: capsule with energetic color

    private var uncommonView: some View {
        HStack(spacing: 8) {
            Text(tier.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(tier.commentary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Text("+\(tier.acorns) acorns")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(LinearGradient(
                    colors: [Color(red: 0.2, green: 0.7, blue: 0.4),
                             Color(red: 0.1, green: 0.55, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: .green.opacity(0.35), radius: 8, y: 3)
        )
    }

    // MARK: - Rare: card with shimmer

    private var rareView: some View {
        VStack(spacing: 6) {
            Text(tier.emoji)
                .font(.title2)
            Text(tier.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text(tier.commentary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            Text("+\(tier.acorns) acorns")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.2)))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color(red: 0.45, green: 0.2, blue: 0.9),
                             Color(red: 0.25, green: 0.1, blue: 0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: .purple.opacity(0.5), radius: 16, y: 6)
        )
    }

    // MARK: - Legendary: full celebration card with floating emoji

    private var legendaryView: some View {
        ZStack {
            // Floating emoji particles
            ForEach(floatingEmoji) { item in
                Text(item.symbol)
                    .font(.title2)
                    .offset(x: item.x, y: item.y)
                    .opacity(item.opacity)
            }

            // Main card
            VStack(spacing: 8) {
                Text(tier.emoji)
                    .font(.system(size: 44))
                Text(tier.title)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                    .tracking(2)
                Text(tier.commentary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    Text("🌰")
                    Text("+\(tier.acorns) acorns")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.2)))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: 300)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(
                        colors: [Color(red: 1.0, green: 0.78, blue: 0.1),
                                 Color(red: 1.0, green: 0.45, blue: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color.orange.opacity(0.6), radius: 24, y: 8)
            )
        }
        .onAppear { spawnFloatingEmoji() }
    }

    // MARK: - Floating Emoji

    private func spawnFloatingEmoji() {
        let symbols = ["🌰", "✨", "🎉", "⭐️", "🎊", "💫"]
        floatingEmoji = (0..<8).map { i in
            FloatingEmoji(
                id: i,
                symbol: symbols[i % symbols.count],
                x: CGFloat.random(in: -130...130),
                y: 0,
                opacity: 1
            )
        }

        // Animate them floating upward and fading
        for i in floatingEmoji.indices {
            withAnimation(
                .easeOut(duration: Double.random(in: 1.0...1.8))
                .delay(Double(i) * 0.1)
            ) {
                floatingEmoji[i].y = CGFloat.random(in: -120 ... -60)
                floatingEmoji[i].opacity = 0
            }
        }
    }
}

// MARK: - Floating Emoji Model

private struct FloatingEmoji: Identifiable {
    let id: Int
    let symbol: String
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}
