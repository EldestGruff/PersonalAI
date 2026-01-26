//
//  ThoughtRowView.swift
//  PersonalAI
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content preview
            Text(thought.content)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.primary)

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
                            .foregroundColor(.blue)
                    }

                    if thought.tags.count > 3 {
                        Text("+\(thought.tags.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Metadata row
            HStack(spacing: 12) {
                // Timestamp
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(thought.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                // Location
                if let location = thought.context.location, let name = location.name {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicator
                if thought.status == .archived {
                    Image(systemName: "archivebox.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Content
            Text(thought.content)
                .font(.body)
                .lineLimit(4)
                .foregroundColor(.primary)

            Spacer()

            // Classification
            if let classification = thought.classification {
                HStack {
                    Image(systemName: classification.type.icon)
                        .foregroundColor(classification.type.color)
                    Text(classification.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }

            // Timestamp
            Text(thought.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minHeight: 150)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
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
                    weather: nil
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
