//
//  ThoughtRowView.swift
//  STASH
//
//  Phase 3A Spec 3: Thought Row Component
//  List row for displaying a thought summary
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Thought Row View

/// A list row displaying a thought summary.
///
/// Shows:
/// - Content preview (2 lines)
/// - Classification badge (if available)
/// - Tags
/// - Timestamp and location
struct ThoughtRowView: View {
    let thought: Thought
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 8) {
            // Content preview with optional shiny badge
            HStack(alignment: .top, spacing: 6) {
                ThoughtContentView(
                    thought: thought,
                    font: .body,
                    color: theme.textColor,
                    lineLimit: 2
                )
                if thought.isShiny {
                    Text("✨")
                        .font(.caption)
                        .accessibilityLabel("Shiny thought")
                }
            }

            // Classification (compact)
            if let classification = thought.classification {
                ClassificationBadgeCompact(classification: classification)
            }

            // Tags
            if !thought.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(thought.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(theme.tagTextColor)
                    }

                    if thought.tags.count > 3 {
                        Text("+\(thought.tags.count - 3)")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }

            // Metadata row
            HStack(spacing: 12) {
                // Timestamp
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    TimelineView(.everyMinute) { _ in
                        Text(thought.createdAt.relativeLabel)
                            .font(.caption)
                    }
                }
                .foregroundColor(theme.secondaryTextColor)

                // Location
                if let location = thought.context.location, let name = location.name {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text(name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                // Status indicator
                if thought.status == .archived {
                    Image(systemName: "archivebox.fill")
                        .font(.caption)
                        .foregroundColor(theme.warningColor)
                        .accessibilityLabel("Archived")
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thought Card View

/// A card-style view for displaying a thought (for grid layouts).
struct ThoughtCardView: View {
    let thought: Thought
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 10) {
            // Content (supports rich text)
            ThoughtContentView(
                thought: thought,
                font: .body,
                color: theme.textColor,
                lineLimit: 4
            )

            Spacer()

            // Classification
            if let classification = thought.classification {
                HStack {
                    Image(systemName: classification.type.icon)
                        .foregroundColor(classification.type.color(theme: theme))
                        .accessibilityHidden(true)
                    Text(classification.type.displayName)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            // Tags
            if !thought.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(thought.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.tagBackgroundColor)
                            .foregroundColor(theme.tagTextColor)
                            .cornerRadius(4)
                    }
                }
            }

            // Timestamp
            Text(thought.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .frame(minHeight: 150)
        .background(theme.surfaceColor)
        .cornerRadius(12)
        .shadow(color: theme.shadowColor, radius: 4, y: 2)
    }
}

// MARK: - Previews

#Preview("Thought Row") {
    List {
        ThoughtRowView(
            thought: Thought(
                id: UUID(),
                userId: UUID(),
                content: "Remember to schedule the team meeting for next week to discuss the project roadmap.",
                attributedContent: nil,
                tags: ["work", "meeting", "planning"],
                status: .active,
                context: Context(
                    timestamp: Date(),
                    location: Location(
                        latitude: 37.7749,
                        longitude: -122.4194,
                        name: "Office",
                        geofenceId: nil
                    ),
                    timeOfDay: .morning,
                    energy: .high,
                    focusState: .deep_work,
                    calendar: nil,
                    activity: nil,
                    weather: nil,
                    stateOfMind: nil,
                    energyBreakdown: nil
                ),
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date(),
                classification: Classification(
                    id: UUID(),
                    type: .reminder,
                    confidence: 0.89,
                    entities: ["team meeting"],
                    suggestedTags: ["work"],
                    sentiment: .neutral,
                    language: "en",
                    processingTime: 120,
                    model: "foundation-model-v1",
                    createdAt: Date(),
                    parsedDateTime: nil
                ),
                relatedThoughtIds: [],
                taskId: nil
            )
        )
    }
}

#Preview("Thought Card") {
    ThoughtCardView(
        thought: Thought(
            id: UUID(),
            userId: UUID(),
            content: "What if we could use on-device ML to automatically categorize thoughts based on context and content?",
            attributedContent: nil,
            tags: ["idea", "ml"],
            status: .active,
            context: Context.empty(),
            createdAt: Date(),
            updatedAt: Date(),
            classification: Classification(
                id: UUID(),
                type: .idea,
                confidence: 0.95,
                entities: ["ML"],
                suggestedTags: ["technology"],
                sentiment: .positive,
                language: "en",
                processingTime: 150,
                model: "foundation-model-v1",
                createdAt: Date(),
                parsedDateTime: nil
            ),
            relatedThoughtIds: [],
            taskId: nil
        )
    )
    .padding()
}

// MARK: - Date Extension

private extension Date {
    /// Relative label without seconds. Updates at minute granularity.
    var relativeLabel: String {
        let diff = Int(Date().timeIntervalSince(self))
        guard diff >= 0 else { return "Just now" }
        if diff < 60 { return "Just now" }
        let mins = diff / 60
        if mins < 60 { return "\(mins) min ago" }
        let hours = mins / 60
        if hours < 24 { return "\(hours) hr ago" }
        let days = hours / 24
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}
