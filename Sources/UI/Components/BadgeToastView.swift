//
//  BadgeToastView.swift
//  STASH
//
//  Celebration toast shown when a badge is earned at capture time.
//  Stacks above the acorn toast with a slightly longer display window
//  since the reveal is more meaningful.
//

import SwiftUI

struct BadgeToastView: View {
    let badge: BadgeDefinition
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 10) {
            Image(systemName: badge.symbol)
                .font(.title3)
                .foregroundStyle(theme.primaryColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("Badge Unlocked")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryTextColor)
                Text(badge.isSecret ? "Secret Squirrel 🤫" : badge.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.textColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.surfaceColor)
                .shadow(color: theme.shadowColor, radius: 8, y: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Badge unlocked: \(badge.name)")
    }
}
