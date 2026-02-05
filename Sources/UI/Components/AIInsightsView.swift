//
//  AIInsightsView.swift
//  PersonalAI
//
//  AI-powered insights display component
//  Shows patterns, recommendations, achievements, and anomalies
//

import SwiftUI

/// View for displaying AI-generated insights with expandable cards
@available(iOS 26.0, *)
struct AIInsightsView: View {
    let insights: GeneratedInsights

    @State private var expandedSections: Set<InsightType> = [.pattern, .recommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            if !insights.summary.isEmpty {
                summaryView
            }

            // Patterns
            if !insights.patterns.isEmpty {
                insightSection(
                    title: "Patterns",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    items: insights.patterns,
                    type: .pattern
                )
            }

            // Achievements
            if !insights.achievements.isEmpty {
                insightSection(
                    title: "Achievements",
                    icon: "trophy.fill",
                    color: .yellow,
                    items: insights.achievements,
                    type: .achievement
                )
            }

            // Recommendations
            if !insights.recommendations.isEmpty {
                insightSection(
                    title: "Recommendations",
                    icon: "lightbulb.fill",
                    color: .orange,
                    items: insights.recommendations,
                    type: .recommendation
                )
            }

            // Anomalies
            if !insights.anomalies.isEmpty {
                insightSection(
                    title: "Anomalies",
                    icon: "exclamationmark.triangle.fill",
                    color: .purple,
                    items: insights.anomalies,
                    type: .anomaly
                )
            }

            // Attribution
            attributionView
        }
    }

    // MARK: - Summary View

    private var summaryView: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(.purple.opacity(0.6))

            Text(insights.summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .italic()

            Spacer()
        }
        .padding()
        .glassEffect(
            .regular.tint(.purple.opacity(0.2)),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    // MARK: - Section View

    private func insightSection(
        title: String,
        icon: String,
        color: Color,
        items: [InsightItem],
        type: InsightType
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if expandedSections.contains(type) {
                        expandedSections.remove(type)
                    } else {
                        expandedSections.insert(type)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(color)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("(\(items.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: expandedSections.contains(type) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(items.count) items, \(expandedSections.contains(type) ? "expanded" : "collapsed")")
            .accessibilityHint("Tap to \(expandedSections.contains(type) ? "collapse" : "expand")")

            // Items
            if expandedSections.contains(type) {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        InsightItemView(item: item, accentColor: color)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Attribution View

    private var attributionView: some View {
        HStack(spacing: 4) {
            Image(systemName: "apple.logo")
                .font(.caption2)
            Text("Powered by Apple Intelligence")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 8)
    }
}

// MARK: - Insight Item View

@available(iOS 26.0, *)
struct InsightItemView: View {
    let item: InsightItem
    let accentColor: Color

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                // Icon
                Image(systemName: item.icon)
                    .font(.body)
                    .foregroundStyle(accentColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    HStack {
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if item.actionable {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    // Description
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Confidence indicator
                confidenceIndicator
            }

            // Expand button for long descriptions
            if item.description.count > 100 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .padding(.leading, 34)
            }
        }
        .padding(12)
        .glassEffect(
            .regular.tint(.purple.opacity(0.5)),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.description)")
        .accessibilityHint(item.actionable ? "This is an actionable recommendation" : "")
    }

    private var confidenceIndicator: some View {
        VStack(spacing: 2) {
            // Confidence dots
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < confidenceLevel ? accentColor : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }

            Text("\(Int(item.confidence * 100))%")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Confidence: \(Int(item.confidence * 100)) percent")
    }

    private var confidenceLevel: Int {
        switch item.confidence {
        case 0.8...: return 3
        case 0.5..<0.8: return 2
        default: return 1
        }
    }
}

// MARK: - Loading View

@available(iOS 26.0, *)
struct AIInsightsLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating insights...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Analyzing your patterns with Apple Intelligence")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Empty State View

@available(iOS 26.0, *)
struct AIInsightsEmptyView: View {
    let minimumThoughts: Int
    let currentThoughts: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(.purple.opacity(0.5))

            Text("Need More Data")
                .font(.headline)

            Text("Capture at least \(minimumThoughts) thoughts to unlock AI-powered insights")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<minimumThoughts, id: \.self) { index in
                    Circle()
                        .fill(index < currentThoughts ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)

            Text("\(currentThoughts)/\(minimumThoughts) thoughts captured")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Unavailable View

@available(iOS 26.0, *)
struct AIInsightsUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("Apple Intelligence Required")
                .font(.headline)

            Text("AI-powered insights require a device with Apple Intelligence capabilities.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Error View

@available(iOS 26.0, *)
struct AIInsightsErrorView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.title)
                .foregroundStyle(.orange)

            Text("Unable to Generate Insights")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: onRetry)
                .buttonStyle(.bordered)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 26.0, *)
#Preview("AI Insights") {
    ScrollView {
        AIInsightsView(
            insights: GeneratedInsights(
                patterns: [
                    InsightItem(
                        type: .pattern,
                        title: "Morning Momentum",
                        description: "You capture 65% of your thoughts between 9-11 AM. This appears to be your peak clarity window.",
                        confidence: 0.92,
                        icon: "sunrise.fill",
                        actionable: false
                    ),
                    InsightItem(
                        type: .pattern,
                        title: "Tuesday Surge",
                        description: "Tuesdays show 2.3x more thought capture than other weekdays, often tagged with 'planning' and 'goals'.",
                        confidence: 0.87,
                        icon: "calendar",
                        actionable: false
                    )
                ],
                recommendations: [
                    InsightItem(
                        type: .recommendation,
                        title: "Evening Reflections",
                        description: "Your sentiment is 0.4 points higher on days with evening thoughts. Consider a bedtime reflection practice.",
                        confidence: 0.81,
                        icon: "moon.stars.fill",
                        actionable: true
                    )
                ],
                achievements: [
                    InsightItem(
                        type: .achievement,
                        title: "7-Day Streak!",
                        description: "You've captured thoughts for 7 consecutive days. Consistency builds powerful habits.",
                        confidence: 1.0,
                        icon: "flame.fill",
                        actionable: false
                    )
                ],
                anomalies: [
                    InsightItem(
                        type: .anomaly,
                        title: "Monday Spike",
                        description: "This Monday had 3x your typical thought volume. Similar spikes appear after weekends with social events.",
                        confidence: 0.76,
                        icon: "exclamationmark.triangle.fill",
                        actionable: false
                    )
                ],
                summary: "Most productive in mornings with strong Tuesday patterns. Consider expanding evening reflections."
            )
        )
        .padding()
    }
}

@available(iOS 26.0, *)
#Preview("Loading") {
    AIInsightsLoadingView()
        .padding()
}

@available(iOS 26.0, *)
#Preview("Empty State") {
    AIInsightsEmptyView(minimumThoughts: 5, currentThoughts: 2)
        .padding()
}

@available(iOS 26.0, *)
#Preview("Unavailable") {
    AIInsightsUnavailableView()
        .padding()
}
#endif
