//
//  ThoughtSpace3D.swift
//  STASH
//
//  Issue #25: 3D Visualizations - Thought Space Explorer
//  Interactive 3D scatter plot: Hour of Day × Sentiment × Energy
//

import SwiftUI
import Charts

// MARK: - Thought Space 3D View

@available(iOS 26.0, *)
struct ThoughtSpace3D: View {
    let dataPoints: [ThoughtSpace3DPoint]
    @State private var themeEngine = ThemeEngine.shared
    @State private var pose: Chart3DPose = .default

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 16) {
            // Header with title and info button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thought Space Explorer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)

                    Text("\(dataPoints.count) thoughts visualized")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Chart3DInfoButton(metadata: .thoughtSpace)
            }
            .padding(.horizontal)

            // 3D Chart
            if dataPoints.isEmpty {
                emptyState(theme: theme)
            } else {
                chart3D(theme: theme)
                    .frame(height: 400)
            }

            // Legend
            legend(theme: theme)
        }
        .padding(.vertical)
    }

    // MARK: - Chart

    @ViewBuilder
    private func chart3D(theme: any ThemeVariant) -> some View {
        Chart3D(dataPoints) {
            PointMark(
                x: .value("Hour", $0.hourOfDay),
                y: .value("Sentiment", $0.sentiment),
                z: .value("Energy", $0.energyLevel)
            )
            .foregroundStyle(
                colorForSentiment($0.sentiment, theme: theme)
            )
            .symbolSize($0.sphereSize / 150.0)  // Scale to 0.03-0.07
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 6)) { value in
                if let hour = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(hour)):00")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: [-1.0, -0.5, 0.0, 0.5, 1.0]) { value in
                if let sentiment = value.as(Double.self) {
                    AxisValueLabel {
                        Text(sentimentLabel(sentiment))
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chartZAxis {
            AxisMarks(values: [0.0, 0.5, 1.0]) { value in
                if let energy = value.as(Double.self) {
                    AxisValueLabel {
                        Text(energyLabel(energy))
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chart3DPose($pose)
        .chartXScale(domain: 0.0...24.0, range: -0.5...0.5)
        .chartYScale(domain: -1.0...1.0, range: -0.5...0.5)
        .chartZScale(domain: 0.0...1.0, range: -0.5...0.5)
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
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))

            Text("No data yet")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("Capture thoughts with sentiment and energy data to see your thought space")
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
            Text("Color Key")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(theme.secondaryTextColor)

            HStack(spacing: 16) {
                LegendItem(color: theme.successColor, label: "Positive", theme: theme)
                LegendItem(color: theme.secondaryTextColor, label: "Neutral", theme: theme)
                LegendItem(color: theme.warningColor, label: "Negative", theme: theme)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func colorForSentiment(_ sentiment: Double, theme: any ThemeVariant) -> Color {
        if sentiment > 0.2 {
            return theme.successColor
        } else if sentiment < -0.2 {
            return theme.warningColor
        } else {
            return theme.secondaryTextColor
        }
    }

    private func sentimentLabel(_ value: Double) -> String {
        switch value {
        case 1.0: return "Very +"
        case 0.5: return "+"
        case 0.0: return "Neutral"
        case -0.5: return "-"
        case -1.0: return "Very -"
        default: return ""
        }
    }

    private func energyLabel(_ value: Double) -> String {
        switch value {
        case 1.0: return "High"
        case 0.5: return "Med"
        case 0.0: return "Low"
        default: return ""
        }
    }

    private func findPoint(at location: CGPoint, in chart: ChartProxy) -> ThoughtSpace3DPoint? {
        // Simplified point detection - would need chart proxy API for accurate selection
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

// MARK: - Thought Detail Popover

@available(iOS 26.0, *)
private struct ThoughtDetailPopover: View {
    let point: ThoughtSpace3DPoint
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    // Thought content
                    Text(point.content)
                        .font(.body)
                        .foregroundStyle(theme.textColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surfaceColor)
                        )

                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        MetadataRow(
                            icon: "clock.fill",
                            label: "Time",
                            value: "\(Int(point.hourOfDay)):00",
                            theme: theme
                        )

                        MetadataRow(
                            icon: "heart.fill",
                            label: "Sentiment",
                            value: sentimentDescription(point.sentiment),
                            theme: theme
                        )

                        MetadataRow(
                            icon: "bolt.fill",
                            label: "Energy",
                            value: energyDescription(point.energyLevel),
                            theme: theme
                        )

                        MetadataRow(
                            icon: "calendar",
                            label: "Date",
                            value: formatDate(point.date),
                            theme: theme
                        )
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Thought Details")
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

    private func sentimentDescription(_ value: Double) -> String {
        switch value {
        case 0.5...1.0: return "Very Positive"
        case 0.2..<0.5: return "Positive"
        case -0.2..<0.2: return "Neutral"
        case -0.5..<(-0.2): return "Negative"
        default: return "Very Negative"
        }
    }

    private func energyDescription(_ value: Double) -> String {
        switch value {
        case 0.7...1.0: return "High"
        case 0.3..<0.7: return "Medium"
        default: return "Low"
        }
    }

    private func formatDate(_ date: Date) -> String {
        return DateFormatter.mediumDateTime.string(from: date)
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

// MARK: - Previews

#Preview("Thought Space 3D") {
    if #available(iOS 26.0, *) {
        ThoughtSpace3D(dataPoints: [
            ThoughtSpace3DPoint(
                thoughtId: UUID(),
                hourOfDay: 9.0,
                sentiment: 0.7,
                energyLevel: 0.8,
                content: "Morning coffee thought - feeling great!",
                date: Date()
            ),
            ThoughtSpace3DPoint(
                thoughtId: UUID(),
                hourOfDay: 14.0,
                sentiment: -0.3,
                energyLevel: 0.4,
                content: "Afternoon slump...",
                date: Date()
            ),
            ThoughtSpace3DPoint(
                thoughtId: UUID(),
                hourOfDay: 20.0,
                sentiment: 0.5,
                energyLevel: 0.6,
                content: "Evening reflection",
                date: Date()
            )
        ])
    } else {
        Text("iOS 26+ required")
    }
}
