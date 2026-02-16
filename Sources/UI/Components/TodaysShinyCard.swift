//
//  TodaysShinyCard.swift
//  STASH
//
//  "Today's Shiny" card for the BrowseScreen thought list header.
//  Shows a random shiny thought, rotating each app launch within the pool.
//  Tapping navigates to the full thought detail.
//

import SwiftUI

struct TodaysShinyCard: View {
    let thought: Thought
    let onTap: () -> Void
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("✨")
                        .font(.subheadline)
                    Text("STASH found a shiny")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                    Text(thought.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Text(thought.content)
                    .font(.subheadline)
                    .foregroundStyle(theme.textColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if !thought.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(thought.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(theme.tagTextColor)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.6), .orange.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today's shiny thought: \(thought.content)")
        .accessibilityHint("Tap to read the full thought")
    }
}
