//
//  AcornToastView.swift
//  STASH
//
//  Brief toast shown after a successful capture to celebrate the acorn award.
//  Appears at the top of the capture screen for ~700ms, then the sheet dismisses.
//

import SwiftUI

struct AcornToastView: View {
    let reward: AcornReward
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        HStack(spacing: 8) {
            Text("🌰")
                .font(.title3)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.surfaceColor)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }

    private var label: String {
        if reward.isNoteworthy {
            return "+\(reward.total) acorns!"
        }
        return "+\(reward.total)"
    }
}
