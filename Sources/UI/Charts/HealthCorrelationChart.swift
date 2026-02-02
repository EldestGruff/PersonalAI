//
//  HealthCorrelationChart.swift
//  PersonalAI
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

    enum HealthMetric: String, CaseIterable, Identifiable {
        case sleepVsSentiment = "Sleep vs Mood"
        case stepsVsVolume = "Activity vs Volume"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .sleepVsSentiment: return "bed.double.fill"
            case .stepsVsVolume: return "figure.walk"
            }
        }

        var xAxisLabel: String {
            switch self {
            case .sleepVsSentiment: return "Sleep (hours)"
            case .stepsVsVolume: return "Steps"
            }
        }

        var yAxisLabel: String {
            switch self {
            case .sleepVsSentiment: return "Mood"
            case .stepsVsVolume: return "Thoughts"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Health Correlations", systemImage: "heart.text.square.fill")
                    .font(.headline)

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

            // Metric picker
            Picker("Metric", selection: $selectedMetric) {
                ForEach(HealthMetric.allCases) { metric in
                    Label(metric.rawValue, systemImage: metric.icon)
                        .tag(metric)
                }
            }
            .pickerStyle(.segmented)

            if hasData {
                // Scatter plot
                scatterChart
                    .frame(height: 220)

                // Insight text
                if !data.correlationCoefficients.description.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text(data.correlationCoefficients.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            } else {
                emptyState
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var scatterChart: some View {
        Chart {
            // Data points
            ForEach(currentDataPoints, id: \.id) { point in
                PointMark(
                    x: .value(selectedMetric.xAxisLabel, point.x),
                    y: .value(selectedMetric.yAxisLabel, point.y)
                )
                .foregroundStyle(Color.accentColor.opacity(0.6))
                .symbolSize(60)
            }

            // Trend line (if correlation exists)
            if let trendLine = calculateTrendLine() {
                LineMark(
                    x: .value("X", trendLine.minX),
                    y: .value("Y", trendLine.minY)
                )
                LineMark(
                    x: .value("X", trendLine.maxX),
                    y: .value("Y", trendLine.maxY)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXAxisLabel(selectedMetric.xAxisLabel)
        .chartYAxisLabel(selectedMetric.yAxisLabel)
        .chartXAxis {
            AxisMarks(position: .bottom) { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            Text("Not enough data")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Capture more thoughts with HealthKit data to see correlations")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Helpers

    private var hasData: Bool {
        switch selectedMetric {
        case .sleepVsSentiment:
            return !data.sleepVsSentiment.isEmpty
        case .stepsVsVolume:
            return !data.stepsVsVolume.isEmpty
        }
    }

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
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
        }
    }

    private var currentCorrelation: Double? {
        switch selectedMetric {
        case .sleepVsSentiment:
            return data.correlationCoefficients.sleepSentimentCorrelation
        case .stepsVsVolume:
            return data.correlationCoefficients.stepsVolumeCorrelation
        }
    }

    private var correlationStrength: String {
        switch selectedMetric {
        case .sleepVsSentiment:
            return data.correlationCoefficients.sleepStrength
        case .stepsVsVolume:
            return data.correlationCoefficients.stepsStrength
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

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(strengthColor)
                .frame(width: 8, height: 8)

            Text(strength)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(strengthColor.opacity(0.2))
        .cornerRadius(8)
    }

    private var strengthColor: Color {
        let abs = Swift.abs(value)
        switch abs {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        case 0.2..<0.4: return .yellow
        default: return .gray
        }
    }
}

// MARK: - Previews

#Preview("Strong Sleep Correlation") {
    HealthCorrelationChart(
        data: HealthCorrelationData(
            sleepVsSentiment: (0..<15).map { i in
                let sleep = 5.0 + Double(i) * 0.3
                let sentiment = -0.5 + (sleep - 5.0) * 0.25 + Double.random(in: -0.1...0.1)
                return SleepSentimentPoint(
                    date: Date().addingTimeInterval(Double(i) * -86400),
                    sleepHours: sleep,
                    sentiment: sentiment
                )
            },
            stepsVsVolume: [],
            correlationCoefficients: CorrelationSummary(
                sleepSentimentCorrelation: 0.78,
                stepsVolumeCorrelation: nil,
                description: "Your mood strongly improves with more sleep"
            )
        )
    )
}

#Preview("Steps vs Volume") {
    HealthCorrelationChart(
        data: HealthCorrelationData(
            sleepVsSentiment: [],
            stepsVsVolume: (0..<15).map { i in
                let steps = 3000 + i * 500
                let thoughts = 5 + Int(Double(steps) / 800) + Int.random(in: -2...2)
                return StepsVolumePoint(
                    date: Date().addingTimeInterval(Double(i) * -86400),
                    steps: steps,
                    thoughtCount: max(0, thoughts)
                )
            },
            correlationCoefficients: CorrelationSummary(
                sleepSentimentCorrelation: nil,
                stepsVolumeCorrelation: 0.65,
                description: "You capture moderately more thoughts on active days"
            )
        )
    )
}

#Preview("No Data") {
    HealthCorrelationChart(
        data: HealthCorrelationData(
            sleepVsSentiment: [],
            stepsVsVolume: [],
            correlationCoefficients: CorrelationSummary(
                sleepSentimentCorrelation: nil,
                stepsVolumeCorrelation: nil,
                description: ""
            )
        )
    )
}
