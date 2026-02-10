//
//  CaptureHeatmapChart.swift
//  STASH
//
//  Issue #18: Swift Charts - Capture Pattern Visualization
//  Shows when thoughts are captured (time of day, day of week)
//

import SwiftUI
import Charts

/// Visualization of capture patterns (when thoughts are captured)
struct CaptureHeatmapChart: View {
    let data: CaptureHeatmapResult
    @State private var selectedHour: Int?
    @State private var selectedDay: Int?
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 20) {
            // Header
            Label("Capture Patterns", systemImage: "clock.fill")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .accessibilityAddTraits(.isHeader)

            // Hour of day distribution
            hourOfDaySection

            Divider()
                .background(theme.dividerColor)

            // Day of week distribution
            dayOfWeekSection
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }

    private var hourOfDaySection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 8) {
            Text("By Hour of Day")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)

            Chart(data.hourOfDayDistribution) { point in
                BarMark(
                    x: .value("Hour", point.hour),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(by: .value("Time", timeOfDayPeriod(hour: point.hour)))
                .opacity(selectedHour == nil || selectedHour == point.hour ? 1.0 : 0.3)
            }
            .chartForegroundStyleScale([
                "Night": theme.infoColor.opacity(0.7),
                "Morning": theme.warningColor.opacity(0.7),
                "Afternoon": theme.successColor.opacity(0.7),
                "Evening": theme.accentColor.opacity(0.7)
            ])
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(formatHour(hour))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartXSelection(value: $selectedHour)
            .frame(height: 120)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hourAccessibilityDescription)

            // Peak hour insight
            if let peakHour = data.hourOfDayDistribution.max(by: { $0.count < $1.count }) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("Most active at \(formatHour(peakHour.hour)) with \(peakHour.count) thoughts")
                        .font(.caption)
                }
                .foregroundStyle(theme.secondaryTextColor)
            }
        }
    }

    private var dayOfWeekSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 8) {
            Text("By Day of Week")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)

            Chart(data.dayOfWeekDistribution) { point in
                BarMark(
                    x: .value("Day", point.dayName),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(
                    intensityColor(
                        count: point.count,
                        max: data.dayOfWeekDistribution.map(\.count).max() ?? 1
                    )
                )
                .opacity(selectedDay == nil || selectedDay == point.dayOfWeek ? 1.0 : 0.3)
                .annotation(position: .top) {
                    if point.count > 0 {
                        Text("\(point.count)")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .frame(height: 120)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(dayAccessibilityDescription)

            // Peak day insight
            if let peakDay = data.dayOfWeekDistribution.max(by: { $0.count < $1.count }) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("\(peakDay.dayName) is your most active day with \(peakDay.count) thoughts")
                        .font(.caption)
                }
                .foregroundStyle(theme.secondaryTextColor)
            }
        }
    }

    // MARK: - Helper Methods

    private func timeOfDayPeriod(hour: Int) -> String {
        switch hour {
        case 0..<6: return "Night"
        case 6..<12: return "Morning"
        case 12..<18: return "Afternoon"
        default: return "Evening"
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = hour < 12 ? "AM" : "PM"
        return "\(hour12)\(period)"
    }

    private func intensityColor(count: Int, max: Int) -> Color {
        let theme = themeEngine.getCurrentTheme()
        let intensity = Double(count) / Double(max)

        switch intensity {
        case 0.75...1.0: return theme.primaryColor
        case 0.5..<0.75: return theme.primaryColor.opacity(0.7)
        case 0.25..<0.5: return theme.primaryColor.opacity(0.5)
        default: return theme.primaryColor.opacity(0.3)
        }
    }

    private var hourAccessibilityDescription: String {
        guard let peakHour = data.hourOfDayDistribution.max(by: { $0.count < $1.count }) else {
            return "No capture data available"
        }

        let totalThoughts = data.hourOfDayDistribution.map(\.count).reduce(0, +)
        return "Capture patterns by hour. Most active at \(formatHour(peakHour.hour)) with \(peakHour.count) thoughts out of \(totalThoughts) total."
    }

    private var dayAccessibilityDescription: String {
        guard let peakDay = data.dayOfWeekDistribution.max(by: { $0.count < $1.count }) else {
            return "No capture data available"
        }

        let totalThoughts = data.dayOfWeekDistribution.map(\.count).reduce(0, +)
        return "Capture patterns by day of week. Most active on \(peakDay.dayName) with \(peakDay.count) thoughts out of \(totalThoughts) total."
    }
}

// MARK: - Previews

#Preview("Typical Pattern") {
    CaptureHeatmapChart(
        data: CaptureHeatmapResult(
            hourOfDayDistribution: (0..<24).map { hour in
                // Morning and evening peaks
                let count: Int
                switch hour {
                case 8...10: count = Int.random(in: 15...25)
                case 19...21: count = Int.random(in: 10...20)
                case 12...14: count = Int.random(in: 8...12)
                default: count = Int.random(in: 0...5)
                }
                return HourDataPoint(hour: hour, count: count, averageSentiment: nil)
            },
            dayOfWeekDistribution: (1...7).map { day in
                // Weekdays higher than weekends
                let count = day >= 2 && day <= 6 ? Int.random(in: 30...50) : Int.random(in: 10...20)
                return DayDataPoint(dayOfWeek: day, count: count, averageSentiment: nil)
            },
            hourByDayMatrix: []
        )
    )
}

#Preview("Night Owl Pattern") {
    CaptureHeatmapChart(
        data: CaptureHeatmapResult(
            hourOfDayDistribution: (0..<24).map { hour in
                let count: Int
                switch hour {
                case 22...23, 0...2: count = Int.random(in: 15...25) // Late night
                case 10...16: count = Int.random(in: 5...10) // Afternoon
                default: count = Int.random(in: 0...3)
                }
                return HourDataPoint(hour: hour, count: count, averageSentiment: nil)
            },
            dayOfWeekDistribution: (1...7).map { day in
                DayDataPoint(dayOfWeek: day, count: Int.random(in: 20...40), averageSentiment: nil)
            },
            hourByDayMatrix: []
        )
    )
}
