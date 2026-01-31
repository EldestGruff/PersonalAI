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

    init(viewModel: InsightsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date range picker
                    dateRangePicker

                    if viewModel.isLoading {
                        ProgressView("Loading insights...")
                            .padding()
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        chartsContent
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

    // MARK: - Charts Content

    private var chartsContent: some View {
        VStack(spacing: 32) {
            thoughtCountChart
            sentimentTrendChart
            typeDistributionChart
            energyCorrelationChart
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

            Chart(viewModel.thoughtCountData) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Count", dataPoint.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
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
                AxisMarks(values: .stride(by: .day)) { _ in
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

            Chart(viewModel.energyCorrelationData) { dataPoint in
                // Bar for thought count
                BarMark(
                    x: .value("Energy", dataPoint.energyName),
                    y: .value("Count", dataPoint.thoughtCount)
                )
                .foregroundStyle(Color.accentColor.gradient)

                // Point overlay for average valence
                if let valence = dataPoint.averageValence {
                    PointMark(
                        x: .value("Energy", dataPoint.energyName),
                        y: .value("Valence", valence * Double(dataPoint.thoughtCount))
                    )
                    .foregroundStyle(Color.purple)
                    .symbol(.circle)
                    .symbolSize(100)
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
            HStack(spacing: 16) {
                Label("Thought Count", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("Avg Mood", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.purple)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
