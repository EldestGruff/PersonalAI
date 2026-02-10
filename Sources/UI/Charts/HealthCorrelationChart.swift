//
//  HealthCorrelationChart.swift
//  STASH
//
//  Issue #18: Swift Charts - Health Data Correlation
//  Scatter plots showing relationships between health metrics and thoughts
//

import SwiftUI
import Charts

/// Scatter plot visualization of health data correlations
struct HealthCorrelationChart: View {
    let data: HealthCorrelationData
    @State private var selectedMetric: HealthMetric = .sleepVsSentiment
    @Environment(\.themeEngine) private var themeEngine

    enum HealthMetric: String, CaseIterable, Identifiable {
        case sleepVsSentiment = "Sleep"
        case stepsVsVolume = "Steps"
        case hrvVsSentiment = "HRV"
        case workoutsVsVolume = "Workouts"
        case restingHRVsSentiment = "Heart Rate"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .sleepVsSentiment: return "bed.double.fill"
            case .stepsVsVolume: return "figure.walk"
            case .hrvVsSentiment: return "waveform.path.ecg"
            case .workoutsVsVolume: return "figure.run"
            case .restingHRVsSentiment: return "heart.fill"
            }
        }

        var fullName: String {
            switch self {
            case .sleepVsSentiment: return "Sleep vs Mood"
            case .stepsVsVolume: return "Activity vs Volume"
            case .hrvVsSentiment: return "HRV vs Mood"
            case .workoutsVsVolume: return "Exercise vs Volume"
            case .restingHRVsSentiment: return "Resting HR vs Mood"
            }
        }

        var xAxisLabel: String {
            switch self {
            case .sleepVsSentiment: return "Sleep (hours)"
            case .stepsVsVolume: return "Steps"
            case .hrvVsSentiment: return "HRV (ms)"
            case .workoutsVsVolume: return "Workout (min)"
            case .restingHRVsSentiment: return "Resting HR (BPM)"
            }
        }

        var yAxisLabel: String {
            switch self {
            case .sleepVsSentiment: return "Mood"
            case .stepsVsVolume: return "Thoughts"
            case .hrvVsSentiment: return "Mood"
            case .workoutsVsVolume: return "Thoughts"
            case .restingHRVsSentiment: return "Mood"
            }
        }

        var description: String {
            switch self {
            case .sleepVsSentiment:
                return "How sleep duration affects your mood"
            case .stepsVsVolume:
                return "Activity level vs thought capture rate"
            case .hrvVsSentiment:
                return "Heart rate variability indicates recovery"
            case .workoutsVsVolume:
                return "Exercise days vs productivity"
            case .restingHRVsSentiment:
                return "Lower resting HR often indicates better health"
            }
        }
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Health Correlations", systemImage: "heart.text.square.fill")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Spacer()

                // Correlation strength indicator
                if let correlation = currentCorrelation {
                    CorrelationBadge(
                        value: correlation,
                        strength: correlationStrength
                    )
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Health Correlations showing \(correlationStrength.lowercased()) relationship")

            // Metric picker - scrollable for all options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HealthMetric.allCases) { metric in
                        MetricPill(
                            metric: metric,
                            isSelected: selectedMetric == metric,
                            hasData: hasDataFor(metric)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMetric = metric
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Description for selected metric
            Text(selectedMetric.description)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.bottom, 4)

            if hasData {
                // Scatter plot
                scatterChart
                    .frame(height: 220)

                // Data summary
                dataSummary
                    .padding(.top, 4)

                // Insight text
                if !data.correlationCoefficients.description.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(theme.warningColor)

                        Text(currentInsight)
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
            } else {
                emptyState
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }

    // MARK: - Metric Pill Component

    private struct MetricPill: View {
        let metric: HealthMetric
        let isSelected: Bool
        let hasData: Bool
        let action: () -> Void
        @Environment(\.themeEngine) private var themeEngine

        var body: some View {
            let theme = themeEngine.getCurrentTheme()

            Button(action: action) {
                HStack(spacing: 4) {
                    Image(systemName: metric.icon)
                        .font(.caption)
                    Text(metric.rawValue)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? theme.primaryColor : theme.inputBackgroundColor)
                .foregroundStyle(isSelected ? Color.white : (hasData ? theme.textColor : theme.secondaryTextColor))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(hasData ? Color.clear : theme.secondaryTextColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .opacity(hasData ? 1.0 : 0.6)
        }
    }

    // MARK: - Data Summary

    private var dataSummary: some View {
        HStack(spacing: 16) {
            SummaryItem(
                title: "Data Points",
                value: "\(currentDataPoints.count)",
                icon: "chart.dots.scatter"
            )

            if let correlation = currentCorrelation {
                SummaryItem(
                    title: "Correlation",
                    value: String(format: "%.2f", correlation),
                    icon: correlation > 0 ? "arrow.up.right" : "arrow.down.right"
                )
            }

            Spacer()
        }
        .font(.caption2)
    }

    private struct SummaryItem: View {
        let title: String
        let value: String
        let icon: String
        @Environment(\.themeEngine) private var themeEngine

        var body: some View {
            let theme = themeEngine.getCurrentTheme()

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(theme.secondaryTextColor)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.8))
                    Text(value)
                        .foregroundColor(theme.textColor)
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Current Insight

    private var currentInsight: String {
        switch selectedMetric {
        case .sleepVsSentiment:
            if let r = data.correlationCoefficients.sleepSentimentCorrelation {
                let direction = r > 0 ? "improves" : "declines"
                let strength = abs(r) > 0.5 ? "notably" : "slightly"
                return "Your mood \(strength) \(direction) with more sleep (r=\(String(format: "%.2f", r)))"
            }
        case .stepsVsVolume:
            if let r = data.correlationCoefficients.stepsVolumeCorrelation {
                let direction = r > 0 ? "more" : "fewer"
                return "You capture \(direction) thoughts on active days (r=\(String(format: "%.2f", r)))"
            }
        case .hrvVsSentiment:
            if let r = data.correlationCoefficients.hrvSentimentCorrelation {
                let direction = r > 0 ? "better" : "lower"
                return "Higher HRV (better recovery) correlates with \(direction) mood (r=\(String(format: "%.2f", r)))"
            }
        case .workoutsVsVolume:
            if let r = data.correlationCoefficients.workoutVolumeCorrelation {
                let direction = r > 0 ? "more productive" : "less active"
                return "You tend to be \(direction) on workout days (r=\(String(format: "%.2f", r)))"
            }
        case .restingHRVsSentiment:
            if let r = data.correlationCoefficients.restingHRSentimentCorrelation {
                // Lower resting HR is generally better, so interpret accordingly
                if r < 0 {
                    return "Lower resting heart rate correlates with better mood (r=\(String(format: "%.2f", r)))"
                } else {
                    return "Higher resting heart rate correlates with better mood (r=\(String(format: "%.2f", r)))"
                }
            }
        }
        return "Not enough data to determine correlation"
    }

    private var scatterChart: some View {
        Chart {
            // Data points
            ForEach(currentDataPoints, id: \.id) { point in
                PointMark(
                    x: .value(selectedMetric.xAxisLabel, point.x),
                    y: .value(selectedMetric.yAxisLabel, point.y)
                )
                .foregroundStyle(chartColor.opacity(0.7))
                .symbolSize(60)
            }

            // Trend line (if correlation exists)
            if let trendLine = calculateTrendLine() {
                // Draw trend line as a series of two points connected
                LineMark(
                    x: .value("X", trendLine.minX),
                    y: .value("Y", trendLine.minY),
                    series: .value("Series", "TrendLine")
                )
                .foregroundStyle(chartColor.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))

                LineMark(
                    x: .value("X", trendLine.maxX),
                    y: .value("Y", trendLine.maxY),
                    series: .value("Series", "TrendLine")
                )
                .foregroundStyle(chartColor.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXAxisLabel(selectedMetric.xAxisLabel)
        .chartYAxisLabel(selectedMetric.yAxisLabel)
        .chartXAxis {
            AxisMarks(position: .bottom) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var emptyState: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.largeTitle)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.6))

            Text("Not enough data")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)

            Text("Capture more thoughts with HealthKit data to see correlations")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Helpers

    private var hasData: Bool {
        hasDataFor(selectedMetric)
    }

    private func hasDataFor(_ metric: HealthMetric) -> Bool {
        switch metric {
        case .sleepVsSentiment:
            return !data.sleepVsSentiment.isEmpty
        case .stepsVsVolume:
            return !data.stepsVsVolume.isEmpty
        case .hrvVsSentiment:
            return !data.hrvVsSentiment.isEmpty
        case .workoutsVsVolume:
            return !data.workoutsVsVolume.isEmpty
        case .restingHRVsSentiment:
            return !data.restingHRVsSentiment.isEmpty
        }
    }

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
        let label: String?

        init(x: Double, y: Double, label: String? = nil) {
            self.x = x
            self.y = y
            self.label = label
        }
    }

    private var currentDataPoints: [ChartPoint] {
        switch selectedMetric {
        case .sleepVsSentiment:
            return data.sleepVsSentiment.map { point in
                ChartPoint(x: point.sleepHours, y: point.sentiment)
            }
        case .stepsVsVolume:
            return data.stepsVsVolume.map { point in
                ChartPoint(x: Double(point.steps), y: Double(point.thoughtCount))
            }
        case .hrvVsSentiment:
            return data.hrvVsSentiment.map { point in
                ChartPoint(x: point.hrv, y: point.sentiment, label: point.recoveryLevel)
            }
        case .workoutsVsVolume:
            return data.workoutsVsVolume.map { point in
                ChartPoint(x: Double(point.workoutMinutes), y: Double(point.thoughtCount))
            }
        case .restingHRVsSentiment:
            return data.restingHRVsSentiment.map { point in
                ChartPoint(x: point.restingHeartRate, y: point.sentiment, label: point.trend)
            }
        }
    }

    private var currentCorrelation: Double? {
        switch selectedMetric {
        case .sleepVsSentiment:
            return data.correlationCoefficients.sleepSentimentCorrelation
        case .stepsVsVolume:
            return data.correlationCoefficients.stepsVolumeCorrelation
        case .hrvVsSentiment:
            return data.correlationCoefficients.hrvSentimentCorrelation
        case .workoutsVsVolume:
            return data.correlationCoefficients.workoutVolumeCorrelation
        case .restingHRVsSentiment:
            return data.correlationCoefficients.restingHRSentimentCorrelation
        }
    }

    private var correlationStrength: String {
        switch selectedMetric {
        case .sleepVsSentiment:
            return data.correlationCoefficients.sleepStrength
        case .stepsVsVolume:
            return data.correlationCoefficients.stepsStrength
        case .hrvVsSentiment:
            return data.correlationCoefficients.hrvStrength
        case .workoutsVsVolume:
            return data.correlationCoefficients.workoutStrength
        case .restingHRVsSentiment:
            return data.correlationCoefficients.restingHRStrength
        }
    }

    private var chartColor: Color {
        let theme = themeEngine.getCurrentTheme()

        switch selectedMetric {
        case .sleepVsSentiment: return theme.infoColor
        case .stepsVsVolume: return theme.successColor
        case .hrvVsSentiment: return theme.warningColor
        case .workoutsVsVolume: return theme.accentColor
        case .restingHRVsSentiment: return theme.errorColor
        }
    }

    private struct TrendLine {
        let minX: Double
        let maxX: Double
        let minY: Double
        let maxY: Double
    }

    private func calculateTrendLine() -> TrendLine? {
        guard let r = currentCorrelation,
              abs(r) > 0.2, // Only show trend line if correlation is meaningful
              !currentDataPoints.isEmpty else {
            return nil
        }

        let points = currentDataPoints
        let n = Double(points.count)

        let sumX = points.map(\.x).reduce(0, +)
        let sumY = points.map(\.y).reduce(0, +)
        let sumXY = points.map { $0.x * $0.y }.reduce(0, +)
        let sumX2 = points.map { $0.x * $0.x }.reduce(0, +)

        // Linear regression: y = mx + b
        let m = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let b = (sumY - m * sumX) / n

        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 1

        return TrendLine(
            minX: minX,
            maxX: maxX,
            minY: m * minX + b,
            maxY: m * maxX + b
        )
    }

    private var accessibilityDescription: String {
        guard let r = currentCorrelation else {
            return "No correlation data available"
        }

        let direction = r > 0 ? "positive" : "negative"
        let strength = correlationStrength.lowercased()

        return "\(selectedMetric.rawValue) showing \(strength) \(direction) correlation with coefficient \(String(format: "%.2f", r))"
    }
}

// MARK: - Correlation Badge

struct CorrelationBadge: View {
    let value: Double
    let strength: String
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 4) {
            Circle()
                .fill(strengthColor)
                .frame(width: 8, height: 8)

            Text(strength)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(strengthColor.opacity(0.2))
        .cornerRadius(8)
    }

    private var strengthColor: Color {
        let theme = themeEngine.getCurrentTheme()
        let abs = Swift.abs(value)
        switch abs {
        case 0.7...1.0: return theme.successColor
        case 0.4..<0.7: return theme.warningColor
        case 0.2..<0.4: return theme.warningColor.opacity(0.7)
        default: return theme.secondaryTextColor
        }
    }
}

// MARK: - Previews

#Preview("All Health Correlations") {
    ScrollView {
        HealthCorrelationChart(
            data: HealthCorrelationData(
                sleepVsSentiment: (0..<15).map { i in
                    let sleep = 5.0 + Double(i) * 0.3
                    let sentiment = -0.5 + (sleep - 5.0) * 0.25 + Double.random(in: -0.1...0.1)
                    return SleepSentimentPoint(
                        date: Date().addingTimeInterval(Double(i) * -86400),
                        sleepHours: sleep,
                        sleepQuality: Double.random(in: 0.5...0.95),
                        sentiment: sentiment
                    )
                },
                stepsVsVolume: (0..<15).map { i in
                    let steps = 3000 + i * 500
                    let thoughts = 5 + Int(Double(steps) / 800) + Int.random(in: -2...2)
                    return StepsVolumePoint(
                        date: Date().addingTimeInterval(Double(i) * -86400),
                        steps: steps,
                        thoughtCount: max(0, thoughts)
                    )
                },
                hrvVsSentiment: (0..<15).map { i in
                    let hrv = 40.0 + Double(i) * 3.0 + Double.random(in: -5...5)
                    let sentiment = -0.3 + (hrv - 40.0) * 0.02 + Double.random(in: -0.15...0.15)
                    let recovery: String
                    if hrv < 30 { recovery = "poor" }
                    else if hrv < 50 { recovery = "below_average" }
                    else if hrv < 70 { recovery = "average" }
                    else if hrv < 90 { recovery = "good" }
                    else { recovery = "excellent" }
                    return HRVSentimentPoint(
                        date: Date().addingTimeInterval(Double(i) * -86400),
                        hrv: hrv,
                        recoveryLevel: recovery,
                        sentiment: min(1.0, max(-1.0, sentiment))
                    )
                },
                workoutsVsVolume: (0..<10).map { i in
                    let minutes = 20 + i * 8 + Int.random(in: -10...10)
                    let thoughts = 6 + Int(Double(minutes) / 15) + Int.random(in: -2...2)
                    return WorkoutVolumePoint(
                        date: Date().addingTimeInterval(Double(i) * -86400),
                        workoutMinutes: max(0, minutes),
                        workoutCount: Int.random(in: 1...2),
                        workoutTypes: ["Running", "Strength"].shuffled().prefix(Int.random(in: 1...2)).map { $0 },
                        thoughtCount: max(0, thoughts)
                    )
                },
                restingHRVsSentiment: (0..<15).map { i in
                    let restingHR = 68.0 - Double(i) * 0.3 + Double.random(in: -3...3)
                    // Lower resting HR often correlates with better mood
                    let sentiment = 0.8 - (restingHR - 55.0) * 0.03 + Double.random(in: -0.2...0.2)
                    let trend: String
                    if restingHR > 70 { trend = "elevated" }
                    else if restingHR < 60 { trend = "low" }
                    else { trend = "normal" }
                    return RestingHRSentimentPoint(
                        date: Date().addingTimeInterval(Double(i) * -86400),
                        restingHeartRate: restingHR,
                        trend: trend,
                        sentiment: min(1.0, max(-1.0, sentiment))
                    )
                },
                correlationCoefficients: CorrelationSummary(
                    sleepSentimentCorrelation: 0.78,
                    stepsVolumeCorrelation: 0.65,
                    hrvSentimentCorrelation: 0.52,
                    workoutVolumeCorrelation: 0.45,
                    restingHRSentimentCorrelation: -0.38,
                    description: "Your mood strongly improves with more sleep. You capture more thoughts on active days. Higher HRV correlates with better mood."
                )
            )
        )
        .padding()
    }
}

#Preview("No Data") {
    HealthCorrelationChart(
        data: HealthCorrelationData(
            sleepVsSentiment: [],
            stepsVsVolume: [],
            hrvVsSentiment: [],
            workoutsVsVolume: [],
            restingHRVsSentiment: [],
            correlationCoefficients: CorrelationSummary(
                sleepSentimentCorrelation: nil,
                stepsVolumeCorrelation: nil,
                hrvSentimentCorrelation: nil,
                workoutVolumeCorrelation: nil,
                restingHRSentimentCorrelation: nil,
                description: ""
            )
        )
    )
    .padding()
}
