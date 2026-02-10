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
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(theme.accentColor)
                    .accessibilityHidden(true)

                Text("AI Classification")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)

                Spacer()

                Text("\(Int(classification.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }

            // Type and sentiment
            HStack(spacing: 12) {
                // Type
                Label(classification.type.displayName, systemImage: classification.type.icon)
                    .font(.subheadline)
                    .foregroundColor(classification.type.color(theme: theme))

                Spacer()

                // Sentiment
                HStack(spacing: 4) {
                    Text("Sentiment:")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                    Image(systemName: classification.sentiment.icon)
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text(classification.sentiment.displayName)
                        .font(.caption)
                }
                .foregroundColor(classification.sentiment.color(theme: theme))
            }

            // Suggested tags
            if !classification.suggestedTags.isEmpty {
                HStack(spacing: 6) {
                    Text("Suggested:")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)

                    ForEach(classification.suggestedTags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(theme.tagTextColor)
                    }
                }
            }
        }
        .padding(12)
        .background(theme.accentColor.opacity(0.1))
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

    func color(theme: any ThemeVariant) -> Color {
        switch self {
        case .reminder: return theme.warningColor
        case .event: return theme.successColor
        case .note: return theme.secondaryTextColor
        case .question: return theme.infoColor
        case .idea: return theme.accentColor
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

    func color(theme: any ThemeVariant) -> Color {
        switch self {
        case .very_positive: return theme.successColor
        case .positive: return theme.successColor.opacity(0.7)
        case .neutral: return theme.secondaryTextColor
        case .negative: return theme.warningColor
        case .very_negative: return theme.errorColor
        }
    }
}

// MARK: - Compact Badge

/// A smaller version of the classification badge for list views.
struct ClassificationBadgeCompact: View {
    let classification: Classification
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 6) {
            Image(systemName: classification.type.icon)
                .font(.caption)
                .accessibilityHidden(true)

            Text(classification.type.displayName)
                .font(.caption)

            Text("•")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)

            Text("\(Int(classification.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .foregroundColor(classification.type.color(theme: theme))
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
