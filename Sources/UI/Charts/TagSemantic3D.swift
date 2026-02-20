//
//  TagSemantic3D.swift
//  STASH
//
//  Issue #25: 3D Visualizations - Tag Semantic Space
//  Interactive 3D scatter plot: Semantic relationships between tags
//

import SwiftUI
import Charts

// MARK: - Tag Semantic 3D View

@available(iOS 26.0, *)
struct TagSemantic3D: View {
    let dataPoints: [TagSemantic3DPoint]
    @State private var themeEngine = ThemeEngine.shared
    @State private var pose: Chart3DPose = .default
    @State private var selectedPoint: TagSemantic3DPoint?
    @State private var showConnections = true

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 16) {
            // Header with title and info button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tag Semantic Space")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)

                    Text("\(dataPoints.count) tags visualized")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Chart3DInfoButton(metadata: .tagSemantic)
            }
            .padding(.horizontal)

            // 3D Chart
            if dataPoints.isEmpty {
                emptyState(theme: theme)
            } else {
                chart3D(theme: theme)
                    .frame(height: 400)
            }

            // Controls and Legend
            VStack(spacing: 12) {
                // Connection toggle
                Toggle("Show Connections", isOn: $showConnections)
                    .font(.caption)
                    .foregroundStyle(theme.textColor)
                    .tint(theme.primaryColor)
                    .padding(.horizontal)

                legend(theme: theme)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Chart

    @ViewBuilder
    private func chart3D(theme: any ThemeVariant) -> some View {
        Chart3D(dataPoints) { point in
            PointMark(
                x: .value("Dimension 1", point.dimension1),
                y: .value("Dimension 2", point.dimension2),
                z: .value("Dimension 3", point.dimension3)
            )
            .foregroundStyle(
                colorForFrequency(point.frequency, theme: theme)
            )
            .symbolSize(point.sphereSize / 200.0)  // Scale to 0.015-0.065
        }
        .chartXAxis {
            AxisMarks(values: [-2.0, -1.0, 0.0, 1.0, 2.0]) {
                AxisTick()
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: [-2.0, -1.0, 0.0, 1.0, 2.0]) {
                AxisTick()
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartZAxis {
            AxisMarks(values: [-1.0, -0.5, 0.0, 0.5, 1.0]) {
                AxisTick()
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chart3DPose($pose)
        .chartXScale(domain: -2.0...2.0, range: -0.5...0.5)
        .chartYScale(domain: -2.0...2.0, range: -0.5...0.5)
        .chartZScale(domain: -1.0...1.0, range: -0.5...0.5)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.dividerColor, lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private func emptyState(theme: any ThemeVariant) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))

            Text("No tags yet")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("Start tagging your thoughts to see semantic relationships emerge")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 400)
    }

    // MARK: - Legend

    private func legend(theme: any ThemeVariant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tag Frequency")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(theme.secondaryTextColor)

            HStack(spacing: 16) {
                LegendItem(color: theme.primaryColor, label: "High", theme: theme)
                LegendItem(color: theme.accentColor, label: "Medium", theme: theme)
                LegendItem(color: theme.secondaryTextColor, label: "Low", theme: theme)
            }

            Text("Sphere size indicates usage frequency")
                .font(.caption2)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.7))
                .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var connectionPairs: [(TagSemantic3DPoint, TagSemantic3DPoint)] {
        var pairs: [(TagSemantic3DPoint, TagSemantic3DPoint)] = []
        let tagLookup = Dictionary(uniqueKeysWithValues: dataPoints.map { ($0.tag, $0) })

        for source in dataPoints {
            for relatedTag in source.relatedTags.prefix(2) { // Limit connections to prevent clutter
                if let target = tagLookup[relatedTag] {
                    pairs.append((source, target))
                }
            }
        }

        return pairs
    }

    private func colorForFrequency(_ frequency: Int, theme: any ThemeVariant) -> Color {
        if frequency > 10 {
            return theme.primaryColor
        } else if frequency > 5 {
            return theme.accentColor
        } else {
            return theme.secondaryTextColor
        }
    }

    private func findPoint(at location: CGPoint, in chart: ChartProxy) -> TagSemantic3DPoint? {
        // Simplified point detection
        return dataPoints.randomElement()
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    let theme: any ThemeVariant

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
    }
}

// MARK: - Tag Detail Popover

@available(iOS 26.0, *)
private struct TagDetailPopover: View {
    let point: TagSemantic3DPoint
    let allPoints: [TagSemantic3DPoint]
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Tag name and frequency
                        VStack(spacing: 8) {
                            Text(point.tag)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.primaryColor)

                            HStack(spacing: 16) {
                                Label("\(point.frequency) uses", systemImage: "number.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.secondaryTextColor)

                                Label("Top \(rankDescription)", systemImage: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.successColor)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surfaceColor)
                        )

                        // Semantic position
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Semantic Position")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            MetadataRow(
                                icon: "arrow.left.and.right",
                                label: "Dimension 1",
                                value: String(format: "%.2f", point.dimension1),
                                theme: theme
                            )

                            MetadataRow(
                                icon: "arrow.up.and.down",
                                label: "Dimension 2",
                                value: String(format: "%.2f", point.dimension2),
                                theme: theme
                            )

                            MetadataRow(
                                icon: "arrow.forward.to.line",
                                label: "Dimension 3",
                                value: String(format: "%.2f", point.dimension3),
                                theme: theme
                            )
                        }

                        Divider()
                            .background(theme.dividerColor)

                        // Related tags
                        if !point.relatedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Related Tags")
                                    .font(.headline)
                                    .foregroundStyle(theme.textColor)

                                FlowLayout(spacing: 8) {
                                    ForEach(point.relatedTags, id: \.self) { relatedTag in
                                        RelatedTagChip(tag: relatedTag, theme: theme)
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Tag Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(theme.primaryColor)
                }
            }
        }
    }

    private var rankDescription: String {
        let sorted = allPoints.sorted { $0.frequency > $1.frequency }
        if let rank = sorted.firstIndex(where: { $0.id == point.id }) {
            let percentage = Int((Double(rank + 1) / Double(sorted.count)) * 100)
            return "\(percentage)%"
        }
        return "N/A"
    }
}

private struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    let theme: any ThemeVariant

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(theme.primaryColor)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(theme.textColor)
        }
    }
}

private struct RelatedTagChip: View {
    let tag: String
    let theme: any ThemeVariant

    var body: some View {
        Text(tag)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(theme.primaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(theme.primaryColor.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Previews

#Preview("Tag Semantic 3D") {
    if #available(iOS 26.0, *) {
        TagSemantic3D(dataPoints: [
            TagSemantic3DPoint(
                tag: "work",
                dimension1: 1.2,
                dimension2: 0.8,
                dimension3: -0.3,
                frequency: 45,
                relatedTags: ["productivity", "meetings", "projects"]
            ),
            TagSemantic3DPoint(
                tag: "health",
                dimension1: -0.8,
                dimension2: 1.4,
                dimension3: 0.2,
                frequency: 32,
                relatedTags: ["exercise", "sleep", "nutrition"]
            ),
            TagSemantic3DPoint(
                tag: "personal",
                dimension1: 0.2,
                dimension2: -1.1,
                dimension3: 0.6,
                frequency: 28,
                relatedTags: ["relationships", "family", "goals"]
            ),
            TagSemantic3DPoint(
                tag: "learning",
                dimension1: 1.5,
                dimension2: 0.3,
                dimension3: -0.8,
                frequency: 18,
                relatedTags: ["reading", "courses", "skills"]
            )
        ])
    } else {
        Text("iOS 26+ required")
    }
}
