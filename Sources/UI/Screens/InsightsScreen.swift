//
//  InsightsScreen.swift
//  PersonalAI
//
//  Analytics and insights visualization with Swift Charts
//

import SwiftUI
import Charts

struct InsightsScreen: View {

    @State private var viewModel: InsightsViewModel
    @State private var selectedSection: InsightSection = .overview

    enum InsightSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case mood = "Mood"
        case patterns = "Patterns"
        case health = "Health"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .mood: return "face.smiling"
            case .patterns: return "calendar"
            case .health: return "heart.fill"
            }
        }
    }

    init(viewModel: InsightsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date range picker
                    dateRangePicker

                    // Section picker
                    sectionPicker

                    if viewModel.isLoading {
                        ProgressView("Loading insights...")
                            .padding()
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        // Content based on selected section
                        switch selectedSection {
                        case .overview:
                            overviewSection
                        case .mood:
                            moodSection
                        case .patterns:
                            patternsSection
                        case .health:
                            healthSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .task {
                await viewModel.loadInsights()
            }
            .onChange(of: viewModel.dateRange) {
                _Concurrency.Task {
                    await viewModel.loadInsights()
                }
            }
        }
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        Picker("Date Range", selection: $viewModel.dateRange) {
            ForEach(InsightsViewModel.DateRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightSection.allCases) { section in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.caption)
                            Text(section.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedSection == section
                                ? Color.accentColor
                                : Color(.secondarySystemBackground)
                        )
                        .foregroundStyle(
                            selectedSection == section
                                ? .white
                                : .primary
                        )
                        .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Section Views

    private var overviewSection: some View {
        VStack(spacing: 20) {
            // AI Insights card at the top
            if #available(iOS 26.0, *) {
                aiInsightsCard
            }

            // Streak visualization
            if let streakData = viewModel.streakData {
                StreakVisualization(streakData: streakData)
            }

            thoughtCountChart
            typeDistributionChart
        }
    }

    private var moodSection: some View {
        VStack(spacing: 20) {
            sentimentTrendChart

            // Tag frequency
            if !viewModel.tagFrequencyData.isEmpty {
                TagFrequencyChart(data: viewModel.tagFrequencyData)
            }
        }
    }

    private var patternsSection: some View {
        VStack(spacing: 20) {
            // Capture heatmap
            if let heatmapData = viewModel.captureHeatmapData {
                CaptureHeatmapChart(data: heatmapData)
            }

            // Tag frequency
            if !viewModel.tagFrequencyData.isEmpty {
                TagFrequencyChart(data: viewModel.tagFrequencyData)
            }

            energyCorrelationChart
        }
    }

    private var healthSection: some View {
        VStack(spacing: 20) {
            // Health correlation chart
            if let healthData = viewModel.healthCorrelationData {
                HealthCorrelationChart(data: healthData)
            }

            sentimentTrendChart
            energyCorrelationChart
        }
    }

    // MARK: - AI Insights Card

    @available(iOS 26.0, *)
    private var aiInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.purple)
                Text("AI Insights")
                    .font(.headline)
                Spacer()
                if viewModel.isLoadingInsights {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Content based on state
            if viewModel.isLoadingInsights && viewModel.generatedInsights == nil {
                AIInsightsLoadingView()
            } else if let insights = viewModel.generatedInsights {
                AIInsightsView(insights: insights)
            } else if let error = viewModel.insightsError {
                AIInsightsErrorView(error: error) {
                    _Concurrency.Task {
                        await viewModel.loadInsights()
                    }
                }
            } else if let summaryMetrics = viewModel.summaryMetrics, summaryMetrics.totalThoughts < 5 {
                AIInsightsEmptyView(
                    minimumThoughts: 5,
                    currentThoughts: summaryMetrics.totalThoughts
                )
            } else {
                // Fallback to legacy insights if available
                if let legacyInsights = viewModel.aiInsights {
                    legacyInsightsView(legacyInsights)
                } else {
                    AIInsightsEmptyView(minimumThoughts: 5, currentThoughts: 0)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    @available(iOS 26.0, *)
    private func legacyInsightsView(_ insights: AIInsightsResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Overall pattern badge
            HStack {
                Text(insights.overallPattern.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(patternColor(for: insights.overallPattern).opacity(0.2))
                    .foregroundStyle(patternColor(for: insights.overallPattern))
                    .cornerRadius(4)

                Text("Confidence: \(Int(insights.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Insights list
            ForEach(Array(insights.insights.enumerated()), id: \.offset) { index, insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "\(index + 1).circle.fill")
                        .foregroundStyle(.purple)
                        .font(.caption)

                    Text(insight)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func patternColor(for pattern: String) -> Color {
        switch pattern.lowercased() {
        case "productive": return .green
        case "balanced": return .blue
        case "stressed": return .orange
        case "creative": return .purple
        case "scattered": return .yellow
        default: return .gray
        }
    }

    // MARK: - Chart 1: Thought Count Over Time

    private var thoughtCountChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thought Activity")
                .font(.headline)

            Text("Daily thought count over time")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.thoughtCountData.isEmpty {
                emptyChartView(icon: "chart.bar", message: "No thought data available")
            } else {
                Chart(viewModel.thoughtCountData) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Count", dataPoint.count)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Chart 2: Sentiment Trends

    private var sentimentTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sentiment & Mood Trends")
                .font(.headline)

            Text("AI sentiment vs. State of Mind valence")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.sentimentData.isEmpty {
                emptyChartView(icon: "waveform.path.ecg", message: "No sentiment data available")
            } else {
                Chart {
                    ForEach(viewModel.sentimentData) { dataPoint in
                        // AI Sentiment line
                        LineMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("Sentiment", dataPoint.averageSentiment)
                        )
                        .foregroundStyle(by: .value("Type", "AI Sentiment"))
                        .symbol(.circle)

                        // State of Mind line (if available)
                        if let valence = dataPoint.stateOfMindValence {
                            LineMark(
                                x: .value("Date", dataPoint.date, unit: .day),
                                y: .value("Valence", valence)
                            )
                            .foregroundStyle(by: .value("Type", "State of Mind"))
                            .symbol(.square)
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYScale(domain: -1.0...1.0)
                .chartForegroundStyleScale([
                    "AI Sentiment": Color.blue,
                    "State of Mind": Color.purple
                ])
                .chartLegend(position: .bottom, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Chart 3: Type Distribution

    private var typeDistributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thought Types")
                .font(.headline)

            Text("Distribution by classification")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.typeDistributionData.isEmpty {
                emptyChartView(icon: "square.stack.3d.up", message: "No type data available")
            } else {
                Chart(viewModel.typeDistributionData) { dataPoint in
                    BarMark(
                        x: .value("Count", dataPoint.count),
                        y: .value("Type", dataPoint.typeName)
                    )
                    .foregroundStyle(by: .value("Type", dataPoint.typeName))
                    .annotation(position: .trailing) {
                        Text("\(dataPoint.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .chartLegend(.hidden)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Chart 4: Energy & Mood Correlation

    private var energyCorrelationChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Energy & Emotional State")
                .font(.headline)

            Text("Thought patterns by energy level")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.energyCorrelationData.isEmpty {
                emptyChartView(icon: "bolt.heart", message: "No energy data available")
            } else {
                Chart(viewModel.energyCorrelationData) { dataPoint in
                    // Bar for thought count with color based on mood valence
                    BarMark(
                        x: .value("Energy", dataPoint.energyName),
                        y: .value("Count", dataPoint.thoughtCount)
                    )
                    .foregroundStyle(moodColor(for: dataPoint.averageValence).gradient)
                    .annotation(position: .top, alignment: .center, spacing: 4) {
                        if let valence = dataPoint.averageValence {
                            Text(moodEmoji(for: valence))
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }

                // Legend
                HStack(spacing: 12) {
                    Label("Thought Count", systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Mood:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("negative")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text("-")
                            .font(.caption2)
                        Text("neutral")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text("-")
                            .font(.caption2)
                        Text("positive")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func moodColor(for valence: Double?) -> Color {
        guard let valence = valence else { return Color.accentColor }
        // valence is -1.0 to 1.0
        if valence > 0.3 {
            return .green
        } else if valence < -0.3 {
            return .red
        } else {
            return .gray
        }
    }

    private func moodEmoji(for valence: Double) -> String {
        if valence > 0.5 { return "very positive" }
        if valence > 0.2 { return "positive" }
        if valence < -0.5 { return "very negative" }
        if valence < -0.2 { return "negative" }
        return "neutral"
    }

    // MARK: - Empty Chart View

    private func emptyChartView(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.tertiary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Capture some thoughts to see your data here")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Unable to load insights")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                _Concurrency.Task {
                    await viewModel.loadInsights()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Insights Screen") {
    InsightsScreen(viewModel: MockInsightsViewModel())
}

#Preview("Loading State") {
    let viewModel = MockInsightsViewModel()
    viewModel.isLoading = true
    return InsightsScreen(viewModel: viewModel)
}
