//
//  HealthCorrelation3D.swift
//  STASH
//
//  Issue #25: 3D Visualizations - Health Correlation Cube
//  Interactive 3D scatter plot: Sleep × HRV × Sentiment
//

import SwiftUI
import Charts

// MARK: - Health Correlation 3D View

@available(iOS 26.0, *)
struct HealthCorrelation3D: View {
    let dataPoints: [HealthCorrelation3DPoint]
    @State private var themeEngine = ThemeEngine.shared
    @State private var pose: Chart3DPose = .default

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 16) {
            // Header with title and info button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Correlation Cube")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)

                    Text("\(dataPoints.count) days analyzed")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Chart3DInfoButton(metadata: .healthCorrelation)
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
                x: .value("Sleep", $0.sleepHours),
                y: .value("HRV", $0.hrvScore),
                z: .value("Sentiment", $0.sentiment)
            )
            .foregroundStyle(
                colorForWellness($0.wellnessScore, theme: theme)
            )
            .symbolSize(0.02 + (Double($0.thoughtCount) / 500.0))  // Varies by thought count
        }
        .chartXAxis {
            AxisMarks(values: [4.0, 6.0, 8.0, 10.0]) { value in
                if let hours = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(hours))h")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: [20.0, 40.0, 60.0, 80.0, 100.0]) { value in
                if let hrv = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(hrv))")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chartZAxis {
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
        .chart3DPose($pose)
        .chartXScale(domain: 4.0...10.0, range: -0.5...0.5)
        .chartYScale(domain: 20.0...100.0, range: -0.5...0.5)
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
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))

            Text("No health data yet")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("Grant HealthKit access to see correlations between sleep, HRV, and mood")
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
            Text("Wellness Score")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(theme.secondaryTextColor)

            HStack(spacing: 16) {
                LegendItem(color: theme.successColor, label: "High", theme: theme)
                LegendItem(color: Color.yellow, label: "Medium", theme: theme)
                LegendItem(color: theme.warningColor, label: "Low", theme: theme)
            }

            Text("Sphere size = thought count that day")
                .font(.caption2)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.7))
                .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func colorForWellness(_ score: Double, theme: any ThemeVariant) -> Color {
        if score > 0.66 {
            return theme.successColor
        } else if score > 0.33 {
            return Color.yellow
        } else {
            return theme.warningColor
        }
    }

    private func sphereSize(for point: HealthCorrelation3DPoint) -> Double {
        return 5.0 + Double(min(point.thoughtCount, 20)) * 0.5
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

    private func findPoint(at location: CGPoint, in chart: ChartProxy) -> HealthCorrelation3DPoint? {
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

// MARK: - Health Detail Popover

@available(iOS 26.0, *)
private struct HealthDetailPopover: View {
    let point: HealthCorrelation3DPoint
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    // Wellness Score Card
                    VStack(spacing: 8) {
                        Text("Wellness Score")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)

                        Text(String(format: "%.1f%%", point.wellnessScore * 100))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(wellnessColor(point.wellnessScore, theme: theme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceColor)
                    )

                    // Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        MetadataRow(
                            icon: "bed.double.fill",
                            label: "Sleep",
                            value: String(format: "%.1f hours", point.sleepHours),
                            theme: theme
                        )

                        MetadataRow(
                            icon: "waveform.path.ecg",
                            label: "HRV",
                            value: String(format: "%.0f ms", point.hrvScore),
                            theme: theme
                        )

                        MetadataRow(
                            icon: "heart.fill",
                            label: "Sentiment",
                            value: sentimentDescription(point.sentiment),
                            theme: theme
                        )

                        MetadataRow(
                            icon: "bubble.left.fill",
                            label: "Thoughts",
                            value: "\(point.thoughtCount) captured",
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
            .navigationTitle("Health Summary")
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

    private func wellnessColor(_ score: Double, theme: any ThemeVariant) -> Color {
        if score > 0.66 {
            return theme.successColor
        } else if score > 0.33 {
            return Color.yellow
        } else {
            return theme.warningColor
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

    private func formatDate(_ date: Date) -> String {
        return DateFormatter.mediumDate.string(from: date)
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

#Preview("Health Correlation 3D") {
    if #available(iOS 26.0, *) {
        HealthCorrelation3D(dataPoints: [
            HealthCorrelation3DPoint(
                date: Date(),
                sleepHours: 8.2,
                hrvScore: 75.0,
                sentiment: 0.6,
                thoughtCount: 12
            ),
            HealthCorrelation3DPoint(
                date: Date().addingTimeInterval(-86400),
                sleepHours: 6.5,
                hrvScore: 45.0,
                sentiment: -0.2,
                thoughtCount: 5
            ),
            HealthCorrelation3DPoint(
                date: Date().addingTimeInterval(-172800),
                sleepHours: 9.0,
                hrvScore: 85.0,
                sentiment: 0.8,
                thoughtCount: 15
            )
        ])
    } else {
        Text("iOS 26+ required")
    }
}
