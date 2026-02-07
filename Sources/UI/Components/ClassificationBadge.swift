//
//  ClassificationBadge.swift
//  STASH
//
//  Phase 3A Spec 3: Classification Badge Component
//  Displays AI classification results
//

import SwiftUI

// MARK: - Classification Badge

/// Displays classification results in a compact badge format.
///
/// Shows:
/// - Classification type with icon
/// - Confidence percentage
/// - Sentiment indicator
/// - Suggested tags (if available)
struct ClassificationBadge: View {
    let classification: Classification

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .accessibilityHidden(true)

                Text("AI Classification")
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(classification.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Type and sentiment
            HStack(spacing: 12) {
                // Type
                Label(classification.type.displayName, systemImage: classification.type.icon)
                    .font(.subheadline)
                    .foregroundColor(classification.type.color)

                Spacer()

                // Sentiment
                HStack(spacing: 4) {
                    Text("Sentiment:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: classification.sentiment.icon)
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text(classification.sentiment.displayName)
                        .font(.caption)
                }
                .foregroundColor(classification.sentiment.color)
            }

            // Suggested tags
            if !classification.suggestedTags.isEmpty {
                HStack(spacing: 6) {
                    Text("Suggested:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(classification.suggestedTags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Classification Type Extensions

extension ClassificationType {
    var displayName: String {
        switch self {
        case .reminder: return "Reminder"
        case .event: return "Event"
        case .note: return "Note"
        case .question: return "Question"
        case .idea: return "Idea"
        }
    }

    var icon: String {
        switch self {
        case .reminder: return "bell.fill"
        case .event: return "calendar"
        case .note: return "note.text"
        case .question: return "questionmark.circle.fill"
        case .idea: return "lightbulb.fill"
        }
    }

    var color: Color {
        switch self {
        case .reminder: return .orange
        case .event: return .green
        case .note: return .gray
        case .question: return .blue
        case .idea: return .purple
        }
    }
}

// MARK: - Sentiment Extensions

extension Sentiment {
    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var icon: String {
        switch self {
        case .very_positive: return "face.smiling.fill"
        case .positive: return "face.smiling"
        case .neutral: return "face.dashed"
        case .negative: return "face.frown"
        case .very_negative: return "face.frown.fill"
        }
    }

    var color: Color {
        switch self {
        case .very_positive: return .green
        case .positive: return .mint
        case .neutral: return .gray
        case .negative: return .orange
        case .very_negative: return .red
        }
    }
}

// MARK: - Compact Badge

/// A smaller version of the classification badge for list views.
struct ClassificationBadgeCompact: View {
    let classification: Classification

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: classification.type.icon)
                .font(.caption)
                .accessibilityHidden(true)

            Text(classification.type.displayName)
                .font(.caption)

            Text("•")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(Int(classification.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .foregroundColor(classification.type.color)
    }
}

// MARK: - Previews

#Preview("Classification Badge") {
    ClassificationBadge(
        classification: Classification(
            id: UUID(),
            type: .idea,
            confidence: 0.87,
            entities: ["SwiftUI", "iOS"],
            suggestedTags: ["development", "ios", "swift"],
            sentiment: .positive,
            language: "en",
            processingTime: 150,
            model: "foundation-model-v1",
            createdAt: Date(),
            parsedDateTime: nil
        )
    )
    .padding()
}

#Preview("Classification Badge Compact") {
    ClassificationBadgeCompact(
        classification: Classification(
            id: UUID(),
            type: .reminder,
            confidence: 0.92,
            entities: [],
            suggestedTags: [],
            sentiment: .neutral,
            language: "en",
            processingTime: 100,
            model: "foundation-model-v1",
            createdAt: Date(),
            parsedDateTime: nil
        )
    )
    .padding()
}
