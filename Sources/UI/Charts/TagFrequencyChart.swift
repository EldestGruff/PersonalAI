//
//  TagFrequencyChart.swift
//  STASH
//
//  Issue #18: Swift Charts - Tag Frequency Visualization
//  Horizontal bar chart showing most common tags
//

import SwiftUI
import Charts

/// Horizontal bar chart displaying tag usage frequency
struct TagFrequencyChart: View {
    let data: [TagPopularity]
    let maxToShow: Int
    @Binding var selectedTag: String?
    @Environment(\.themeEngine) private var themeEngine

    init(data: [TagPopularity], maxToShow: Int = 10, selectedTag: Binding<String?> = .constant(nil)) {
        self.data = data
        self.maxToShow = maxToShow
        self._selectedTag = selectedTag
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Top Tags", systemImage: "tag.fill")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Spacer()

                Text("\(data.count) unique")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Top Tags section with \(data.count) unique tags")

            if data.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }

    private var chartView: some View {
        let theme = themeEngine.getCurrentTheme()

        return Chart(Array(data.prefix(maxToShow))) { tag in
            BarMark(
                x: .value("Count", tag.count),
                y: .value("Tag", tag.tag)
            )
            .foregroundStyle(
                selectedTag == tag.tag
                    ? theme.primaryColor.gradient
                    : theme.primaryColor.opacity(0.7).gradient
            )
            .annotation(position: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(tag.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textColor)

                    Text("(\(Int(tag.percentage * 100))%)")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let tag = value.as(String.self) {
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(selectedTag == tag ? theme.primaryColor : theme.textColor)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .frame(height: CGFloat(min(data.count, maxToShow) * 35))
        .chartYSelection(value: $selectedTag)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Chart showing frequency of tags")
    }

    private var emptyState: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 8) {
            Image(systemName: "tag.slash")
                .font(.title)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.6))

            Text("No tags yet")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)

            Text("Add tags to your thoughts to see patterns")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var accessibilityDescription: String {
        guard !data.isEmpty else {
            return "No tag data available"
        }

        let topTags = data.prefix(3).map { "#\($0.tag) with \($0.count) uses" }
        return "Top tags: \(topTags.joined(separator: ", ")). Total of \(data.count) unique tags."
    }
}

// MARK: - Previews

#Preview("With Data") {
    TagFrequencyChart(
        data: [
            TagPopularity(tag: "work", count: 45, percentage: 0.35),
            TagPopularity(tag: "health", count: 32, percentage: 0.25),
            TagPopularity(tag: "ideas", count: 28, percentage: 0.22),
            TagPopularity(tag: "meeting", count: 15, percentage: 0.12),
            TagPopularity(tag: "urgent", count: 8, percentage: 0.06)
        ]
    )
}

#Preview("Empty State") {
    TagFrequencyChart(data: [])
}

#Preview("Many Tags") {
    TagFrequencyChart(
        data: (0..<20).map { i in
            TagPopularity(
                tag: "tag\(i)",
                count: 50 - (i * 2),
                percentage: Double(50 - (i * 2)) / 100.0
            )
        },
        maxToShow: 15
    )
}
