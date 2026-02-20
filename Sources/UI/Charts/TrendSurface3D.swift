//
//  TrendSurface3D.swift
//  STASH
//
//  Issue #25: 3D Visualizations - Thought Volume Surface
//  Interactive 3D surface plot: Date × Hour → Volume
//

import SwiftUI
import Charts

// MARK: - Trend Surface 3D View

@available(iOS 26.0, *)
struct TrendSurface3D: View {
    let surfaceData: TrendSurface3DData
    @State private var themeEngine = ThemeEngine.shared
    @State private var pose: Chart3DPose = .default
    @State private var selectedPoint: TrendSurface3DPoint?

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 16) {
            // Header with title and info button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thought Volume Surface")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)

                    Text("\(surfaceData.points.count) data points")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Chart3DInfoButton(metadata: .trendSurface)
            }
            .padding(.horizontal)

            // 3D Chart
            if surfaceData.points.isEmpty {
                emptyState(theme: theme)
            } else {
                chart3D(theme: theme)
                    .frame(height: 400)
            }

            // Stats
            statsView(theme: theme)
        }
        .padding(.vertical)
    }

    // MARK: - Chart

    @ViewBuilder
    private func chart3D(theme: any ThemeVariant) -> some View {
        let nonZeroPoints = surfaceData.points.filter { $0.thoughtCount > 0 }

        Chart3D(nonZeroPoints) {
            PointMark(
                x: .value("Date", $0.date),
                y: .value("Hour", Double($0.hourOfDay)),
                z: .value("Count", Double($0.thoughtCount))
            )
            .foregroundStyle(
                colorForVolume($0.thoughtCount, theme: theme)
            )
            .symbolSize(0.02 + (Double($0.thoughtCount) / 300.0))  // Varies by volume
        }
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatAxisDate(date))
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                if let hour = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(hour):00")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chartZAxis {
            AxisMarks { value in
                if let count = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
        }
        .chart3DPose($pose)
        .chartXScale(domain: surfaceData.dateRange, range: -0.5...0.5)
        .chartYScale(domain: 0.0...24.0, range: -0.5...0.5)
        .chartZScale(domain: 0.0...Double(surfaceData.maxCount), range: -0.5...0.5)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.dividerColor, lineWidth: 1)
        )
        .sheet(item: $selectedPoint) { point in
            VolumeDetailPopover(point: point, maxCount: surfaceData.maxCount)
        }
    }

    // MARK: - Empty State

    private func emptyState(theme: any ThemeVariant) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))

            Text("No trend data yet")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("Capture thoughts over time to see volume patterns emerge")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 400)
    }

    // MARK: - Stats View

    private func statsView(theme: any ThemeVariant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Surface Statistics")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(theme.secondaryTextColor)

            HStack(spacing: 16) {
                StatCard(
                    title: "Peak Volume",
                    value: "\(surfaceData.maxCount)",
                    icon: "arrow.up.circle.fill",
                    color: theme.successColor,
                    theme: theme
                )

                StatCard(
                    title: "Time Span",
                    value: "\(surfaceData.gridWidth) days",
                    icon: "calendar.circle.fill",
                    color: theme.primaryColor,
                    theme: theme
                )

                StatCard(
                    title: "Grid Points",
                    value: "\(surfaceData.points.count)",
                    icon: "grid.circle.fill",
                    color: theme.accentColor,
                    theme: theme
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func symbolSizeForCount(_ count: Int) -> Double {
        // Base size of 5, scaled by count (with a reasonable max)
        return 5.0 + min(Double(count) * 2.0, 30.0)
    }

    private func colorForVolume(_ count: Int, theme: any ThemeVariant) -> Color {
        let normalized = Double(count) / Double(max(surfaceData.maxCount, 1))

        if normalized > 0.66 {
            return theme.successColor
        } else if normalized > 0.33 {
            return theme.primaryColor
        } else if count > 0 {
            return theme.secondaryTextColor
        } else {
            return theme.dividerColor
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func findPoint(at location: CGPoint, in chart: ChartProxy) -> TrendSurface3DPoint? {
        // Simplified point detection
        return surfaceData.points.randomElement()
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: any ThemeVariant

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.textColor)

            Text(title)
                .font(.caption2)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceColor)
        )
    }
}

// MARK: - Volume Detail Popover

@available(iOS 26.0, *)
private struct VolumeDetailPopover: View {
    let point: TrendSurface3DPoint
    let maxCount: Int
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    // Volume visualization
                    VStack(spacing: 8) {
                        Text("Thought Count")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)

                        Text("\(point.thoughtCount)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryColor)

                        // Volume bar
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let fillWidth = width * (Double(point.thoughtCount) / Double(max(maxCount, 1)))

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.dividerColor)
                                    .frame(height: 16)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.primaryColor)
                                    .frame(width: fillWidth, height: 16)
                            }
                        }
                        .frame(height: 16)
                        .padding(.horizontal)

                        Text("\(Int((Double(point.thoughtCount) / Double(max(maxCount, 1))) * 100))% of peak volume")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceColor)
                    )

                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        MetadataRow(
                            icon: "calendar",
                            label: "Date",
                            value: formatDate(point.date),
                            theme: theme
                        )

                        MetadataRow(
                            icon: "clock.fill",
                            label: "Hour",
                            value: "\(point.hourOfDay):00 - \(point.hourOfDay + 1):00",
                            theme: theme
                        )

                        MetadataRow(
                            icon: "chart.bar.fill",
                            label: "Relative Volume",
                            value: volumeDescription(point.thoughtCount, maxCount: maxCount),
                            theme: theme
                        )
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Volume Detail")
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func volumeDescription(_ count: Int, maxCount: Int) -> String {
        let normalized = Double(count) / Double(max(maxCount, 1))

        if normalized > 0.66 {
            return "Peak Activity"
        } else if normalized > 0.33 {
            return "Moderate Activity"
        } else if count > 0 {
            return "Low Activity"
        } else {
            return "No Activity"
        }
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

#Preview("Trend Surface 3D") {
    if #available(iOS 26.0, *) {
        let mockPoints = (0..<7).flatMap { day in
            (0..<24).map { hour in
                TrendSurface3DPoint(
                    date: Date().addingTimeInterval(TimeInterval(-day * 86400)),
                    hourOfDay: hour,
                    thoughtCount: Int.random(in: 0...15)
                )
            }
        }

        let mockData = TrendSurface3DData(
            points: mockPoints,
            dateRange: Date().addingTimeInterval(-6 * 86400)...Date(),
            maxCount: 15
        )

        TrendSurface3D(surfaceData: mockData)
    } else {
        Text("iOS 26+ required")
    }
}
