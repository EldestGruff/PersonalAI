//
//  InsightsViewModel.swift
//  STASH
//
//  Aggregates thought data for Swift Charts visualization
//

import Foundation
import SwiftUI
import FoundationModels

/// Data point for thought count over time chart
struct ThoughtCountDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// SentimentDataPoint is now defined in ChartDataModels.swift

/// Data point for type distribution chart
struct TypeDistributionDataPoint: Identifiable {
    let id = UUID()
    let type: ClassificationType
    let count: Int

    var typeName: String {
        switch type {
        case .note: return "Notes"
        case .idea: return "Ideas"
        case .reminder: return "Tasks"
        case .event: return "Events"
        case .question: return "Questions"
        }
    }
}

/// Data point for energy/state of mind correlation
struct EnergyCorrelationDataPoint: Identifiable {
    let id = UUID()
    let energy: EnergyLevel
    let thoughtCount: Int
    let averageValence: Double?

    var energyName: String {
        switch energy {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .peak: return "Peak"
        }
    }
}

/// View model for insights and analytics
@MainActor
@Observable
class InsightsViewModel {

    // MARK: - Dependencies

    private let thoughtService: ThoughtServiceProtocol
    private let chartDataService: ChartDataService

    // MARK: - State

    var isLoading = false
    var error: Error?

    // Existing chart data
    var thoughtCountData: [ThoughtCountDataPoint] = []
    var sentimentData: [SentimentDataPoint] = []
    var typeDistributionData: [TypeDistributionDataPoint] = []
    var energyCorrelationData: [EnergyCorrelationDataPoint] = []

    // New chart data (from ChartDataService)
    var tagFrequencyData: [TagPopularity] = []
    var captureHeatmapData: CaptureHeatmapResult?
    var healthCorrelationData: HealthCorrelationData?
    var streakData: StreakData?
    var summaryMetrics: ChartSummaryMetrics?

    // AI Insights (legacy - for backward compatibility)
    var aiInsights: AIInsightsResponse?
    var isLoadingInsights = false

    // New comprehensive AI insights (iOS 26+)
    var generatedInsights: GeneratedInsights?
    var insightsError: Error?

    // Date range for filtering
    var dateRange: DateRange = .last30Days

    enum DateRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case allTime = "All Time"

        var startDate: Date? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .last7Days:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: now)
            case .last90Days:
                return calendar.date(byAdding: .day, value: -90, to: now)
            case .allTime:
                return nil
            }
        }
    }

    // MARK: - Initialization

    init(
        thoughtService: ThoughtServiceProtocol,
        chartDataService: ChartDataService
    ) {
        self.thoughtService = thoughtService
        self.chartDataService = chartDataService
    }

    convenience init(thoughtService: ThoughtServiceProtocol) {
        // Create ChartDataService with dependencies
        let healthKitService = HealthKitService()
        let chartService = ChartDataService(
            thoughtService: thoughtService,
            healthKitService: healthKitService
        )
        self.init(thoughtService: thoughtService, chartDataService: chartService)
    }

    // MARK: - Data Loading

    func loadInsights() async {
        isLoading = true
        error = nil

        do {
            let thoughts = try await thoughtService.list(filter: nil)

            // Filter by date range
            let filteredThoughts: [Thought]
            if let startDate = dateRange.startDate {
                filteredThoughts = thoughts.filter { $0.createdAt >= startDate }
            } else {
                filteredThoughts = thoughts
            }

            // Convert date range to ChartDateRange
            let chartRange = convertToChartDateRange(dateRange)

            // Load data in parallel using async let
            async let thoughtCount = generateThoughtCountData(from: filteredThoughts)
            async let sentiment = generateSentimentData(from: filteredThoughts)
            async let typeDistribution = generateTypeDistributionData(from: filteredThoughts)
            async let energyCorrelation = generateEnergyCorrelationData(from: filteredThoughts)

            // Load new chart data from ChartDataService
            async let tagFrequency = chartDataService.getTagFrequency(dateRange: chartRange, limit: 10)
            async let captureHeatmap = chartDataService.getCaptureHeatmap(dateRange: chartRange)
            async let healthCorrelation = chartDataService.getHealthCorrelation(dateRange: chartRange)
            async let streaks = chartDataService.getStreakData()
            async let summary = chartDataService.getSummaryMetrics(dateRange: chartRange)

            // Await all results
            thoughtCountData = await thoughtCount
            sentimentData = await sentiment
            typeDistributionData = await typeDistribution
            energyCorrelationData = await energyCorrelation
            tagFrequencyData = try await tagFrequency
            captureHeatmapData = try await captureHeatmap
            healthCorrelationData = try await healthCorrelation
            streakData = try await streaks
            summaryMetrics = try await summary

            isLoading = false

            // Generate AI insights in background so charts appear immediately
            if #available(iOS 26.0, *), filteredThoughts.count >= 5 {
                let range = chartRange
                _Concurrency.Task { await loadGeneratedInsights(dateRange: range) }
            }

        } catch {
            self.error = error
            isLoading = false
        }
    }

    private func convertToChartDateRange(_ range: DateRange) -> ChartDateRange {
        switch range {
        case .last7Days: return .week
        case .last30Days: return .month
        case .last90Days: return .quarter
        case .allTime: return .all
        }
    }

    @available(iOS 26.0, *)
    private func loadGeneratedInsights(dateRange: ChartDateRange) async {
        isLoadingInsights = true
        insightsError = nil

        do {
            // Try to generate AI-powered insights
            generatedInsights = try await chartDataService.generateInsights(dateRange: dateRange)
            AnalyticsService.shared.track(.aiInsightsGenerated)
        } catch {
            AppLogger.warning("Failed to generate AI insights", category: .general)
            insightsError = error

            // Fall back to rule-based insights
            do {
                generatedInsights = try await chartDataService.generateFallbackInsights(dateRange: dateRange)
                AnalyticsService.shared.track(.aiInsightsGenerated)
            } catch {
                AppLogger.warning("Failed to generate fallback insights", category: .general)
                generatedInsights = nil
            }
        }

        isLoadingInsights = false
    }

    @available(iOS 26.0, *)
    private func loadAIInsights(thoughts: [Thought]) async {
        // Legacy insights loading - keep for backward compatibility
        do {
            let analyzer = InsightsAnalyzer()
            aiInsights = try await analyzer.generateInsights(
                thoughts: thoughts,
                dateRange: dateRange.rawValue
            )
        } catch {
            AppLogger.warning("Failed to generate legacy AI insights", category: .general)
            aiInsights = nil
        }
    }

    // MARK: - Data Aggregation

    private func generateThoughtCountData(from thoughts: [Thought]) -> [ThoughtCountDataPoint] {
        let calendar = Calendar.current

        // Group thoughts by day
        let grouped = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        // Create data points
        return grouped.map { date, thoughts in
            ThoughtCountDataPoint(date: date, count: thoughts.count)
        }
        .sorted { $0.date < $1.date }
    }

    private func generateSentimentData(from thoughts: [Thought]) -> [SentimentDataPoint] {
        let calendar = Calendar.current

        // Group thoughts by day
        let grouped = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        // Calculate average sentiment and state of mind per day
        return grouped.compactMap { date, dayThoughts in
            // Average sentiment from AI classification (convert enum to numerical value)
            let sentiments = dayThoughts.compactMap { thought -> Double? in
                guard let sentiment = thought.classification?.sentiment else { return nil }
                switch sentiment {
                case .very_negative: return -1.0
                case .negative: return -0.5
                case .neutral: return 0.0
                case .positive: return 0.5
                case .very_positive: return 1.0
                }
            }
            guard !sentiments.isEmpty else { return nil }
            let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)

            // Average state of mind valence for the day
            let valences = dayThoughts.compactMap { $0.context.stateOfMind?.valence }
            let avgValence = valences.isEmpty ? nil : valences.reduce(0.0, +) / Double(valences.count)

            return SentimentDataPoint(
                date: date,
                averageSentiment: avgSentiment,
                thoughtCount: dayThoughts.count,
                stateOfMindValence: avgValence
            )
        }
        .sorted { $0.date < $1.date }
    }

    private func generateTypeDistributionData(from thoughts: [Thought]) -> [TypeDistributionDataPoint] {
        // Group by classification type
        let grouped = Dictionary(grouping: thoughts) { thought in
            thought.classification?.type ?? .note
        }

        return grouped.map { type, thoughts in
            TypeDistributionDataPoint(type: type, count: thoughts.count)
        }
        .sorted { $0.count > $1.count }
    }

    private func generateEnergyCorrelationData(from thoughts: [Thought]) -> [EnergyCorrelationDataPoint] {
        // Group by energy level
        let grouped = Dictionary(grouping: thoughts) { thought in
            thought.context.energy
        }

        return grouped.map { energy, thoughts in
            // Calculate average state of mind valence for this energy level
            let valences = thoughts.compactMap { $0.context.stateOfMind?.valence }
            let avgValence = valences.isEmpty ? nil : valences.reduce(0.0, +) / Double(valences.count)

            return EnergyCorrelationDataPoint(
                energy: energy,
                thoughtCount: thoughts.count,
                averageValence: avgValence
            )
        }
        .sorted { energyOrder($0.energy) < energyOrder($1.energy) }
    }

    private func energyOrder(_ energy: EnergyLevel) -> Int {
        switch energy {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .peak: return 3
        }
    }
}

// MARK: - Mock Insights View Model

@MainActor
@Observable
class MockInsightsViewModel: InsightsViewModel {
    init() {
        let mockThoughtService = MockThoughtService()
        let mockHealthKitService = HealthKitService()
        let mockChartService = ChartDataService(
            thoughtService: mockThoughtService,
            healthKitService: mockHealthKitService
        )
        super.init(thoughtService: mockThoughtService, chartDataService: mockChartService)

        // Mock AI insights
        if #available(iOS 26.0, *) {
            aiInsights = AIInsightsResponse(
                insights: [
                    "You're most productive in the morning, capturing 65% of your thoughts before noon",
                    "Your mood improves by 0.3 points on days when you exercise or move more",
                    "You tend to have more creative ideas when your energy is high",
                    "Your emotional state is most positive when you have free time between events"
                ],
                overallPattern: "productive",
                confidence: 0.87
            )
        }

        // Pre-populate with mock data
        let calendar = Calendar.current
        let today = Date()

        // Mock thought count data (last 7 days)
        thoughtCountData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return ThoughtCountDataPoint(
                date: calendar.startOfDay(for: date),
                count: Int.random(in: 3...15)
            )
        }.reversed()

        // Mock sentiment data
        sentimentData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return SentimentDataPoint(
                date: calendar.startOfDay(for: date),
                averageSentiment: Double.random(in: -0.5...0.8),
                thoughtCount: Int.random(in: 3...15),
                stateOfMindValence: Double.random(in: -0.3...0.7)
            )
        }.reversed()

        // Mock type distribution
        typeDistributionData = [
            TypeDistributionDataPoint(type: .note, count: 45),
            TypeDistributionDataPoint(type: .reminder, count: 32),
            TypeDistributionDataPoint(type: .idea, count: 28),
            TypeDistributionDataPoint(type: .question, count: 15),
            TypeDistributionDataPoint(type: .event, count: 8)
        ]

        // Mock energy correlation
        energyCorrelationData = [
            EnergyCorrelationDataPoint(energy: .low, thoughtCount: 12, averageValence: -0.2),
            EnergyCorrelationDataPoint(energy: .medium, thoughtCount: 45, averageValence: 0.3),
            EnergyCorrelationDataPoint(energy: .high, thoughtCount: 38, averageValence: 0.6),
            EnergyCorrelationDataPoint(energy: .peak, thoughtCount: 15, averageValence: 0.8)
        ]

        // Mock tag frequency data
        tagFrequencyData = [
            TagPopularity(tag: "work", count: 45, percentage: 0.35),
            TagPopularity(tag: "health", count: 32, percentage: 0.25),
            TagPopularity(tag: "ideas", count: 28, percentage: 0.22),
            TagPopularity(tag: "meeting", count: 15, percentage: 0.12),
            TagPopularity(tag: "urgent", count: 8, percentage: 0.06)
        ]

        // Mock capture heatmap
        captureHeatmapData = CaptureHeatmapResult(
            hourOfDayDistribution: (0..<24).map { hour in
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
                let count = day >= 2 && day <= 6 ? Int.random(in: 30...50) : Int.random(in: 10...20)
                return DayDataPoint(dayOfWeek: day, count: count, averageSentiment: nil)
            },
            hourByDayMatrix: []
        )

        // Mock health correlation with all new data types
        healthCorrelationData = HealthCorrelationData(
            sleepVsSentiment: (0..<15).map { i in
                let sleep = 5.0 + Double(i) * 0.3
                let sentiment = -0.5 + (sleep - 5.0) * 0.25 + Double.random(in: -0.1...0.1)
                return SleepSentimentPoint(
                    date: calendar.date(byAdding: .day, value: -i, to: today)!,
                    sleepHours: sleep,
                    sleepQuality: Double.random(in: 0.5...0.95),
                    sentiment: sentiment
                )
            },
            stepsVsVolume: (0..<15).map { i in
                let steps = 3000 + i * 500
                let thoughts = 5 + Int(Double(steps) / 800) + Int.random(in: -2...2)
                return StepsVolumePoint(
                    date: calendar.date(byAdding: .day, value: -i, to: today)!,
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
                    date: calendar.date(byAdding: .day, value: -i, to: today)!,
                    hrv: hrv,
                    recoveryLevel: recovery,
                    sentiment: min(1.0, max(-1.0, sentiment))
                )
            },
            workoutsVsVolume: (0..<10).map { i in
                let minutes = 20 + i * 8 + Int.random(in: -10...10)
                let thoughts = 6 + Int(Double(minutes) / 15) + Int.random(in: -2...2)
                return WorkoutVolumePoint(
                    date: calendar.date(byAdding: .day, value: -i, to: today)!,
                    workoutMinutes: max(0, minutes),
                    workoutCount: Int.random(in: 1...2),
                    workoutTypes: ["Running", "Strength"].shuffled().prefix(Int.random(in: 1...2)).map { $0 },
                    thoughtCount: max(0, thoughts)
                )
            },
            restingHRVsSentiment: (0..<15).map { i in
                let restingHR = 68.0 - Double(i) * 0.3 + Double.random(in: -3...3)
                let sentiment = 0.8 - (restingHR - 55.0) * 0.03 + Double.random(in: -0.2...0.2)
                let trend: String
                if restingHR > 70 { trend = "elevated" }
                else if restingHR < 60 { trend = "low" }
                else { trend = "normal" }
                return RestingHRSentimentPoint(
                    date: calendar.date(byAdding: .day, value: -i, to: today)!,
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
                description: "Your mood strongly improves with more sleep. You capture moderately more thoughts on active days. Higher HRV correlates with better mood."
            )
        )

        // Mock streak data
        streakData = StreakData(
            currentStreak: 12,
            longestStreak: 15,
            totalDaysWithThoughts: 45,
            streakHistory: [
                StreakPeriod(
                    startDate: calendar.date(byAdding: .day, value: -12, to: today)!,
                    endDate: today,
                    length: 12
                )
            ]
        )

        // Mock summary metrics
        summaryMetrics = ChartSummaryMetrics(
            totalThoughts: 128,
            averageSentiment: 0.42,
            mostCommonType: ThoughtType.note,
            topTag: "work",
            currentStreak: 12,
            longestStreak: 15
        )

        // Mock comprehensive AI insights (iOS 26+)
        if #available(iOS 26.0, *) {
            generatedInsights = GeneratedInsights(
                patterns: [
                    InsightItem(
                        type: .pattern,
                        title: "Morning Momentum",
                        description: "You capture 65% of your thoughts between 9-11 AM. This appears to be your peak clarity window.",
                        confidence: 0.92,
                        icon: "sunrise.fill",
                        actionable: false
                    ),
                    InsightItem(
                        type: .pattern,
                        title: "Tuesday Surge",
                        description: "Tuesdays show 2.3x more thought capture than other weekdays, often tagged with 'planning' and 'goals'.",
                        confidence: 0.87,
                        icon: "calendar",
                        actionable: false
                    ),
                    InsightItem(
                        type: .pattern,
                        title: "Work-Focused",
                        description: "The 'work' tag appears in 45 of your 128 thoughts (35%). You're highly focused on professional growth.",
                        confidence: 0.95,
                        icon: "briefcase.fill",
                        actionable: false
                    )
                ],
                recommendations: [
                    InsightItem(
                        type: .recommendation,
                        title: "Evening Reflections",
                        description: "Your sentiment is 0.4 points higher on days with evening thoughts. Consider a bedtime reflection practice.",
                        confidence: 0.81,
                        icon: "moon.stars.fill",
                        actionable: true
                    ),
                    InsightItem(
                        type: .recommendation,
                        title: "Sleep Priority",
                        description: "Your mood strongly improves with more sleep (r=0.78). Prioritizing 7-8 hours could boost your well-being.",
                        confidence: 0.85,
                        icon: "bed.double.fill",
                        actionable: true
                    )
                ],
                achievements: [
                    InsightItem(
                        type: .achievement,
                        title: "12-Day Streak!",
                        description: "You've captured thoughts for 12 consecutive days. Consistency builds powerful habits - you're almost at your record of 15!",
                        confidence: 1.0,
                        icon: "flame.fill",
                        actionable: false
                    )
                ],
                anomalies: [
                    InsightItem(
                        type: .anomaly,
                        title: "Monday Spike",
                        description: "This Monday had 3x your typical thought volume. Similar spikes appear after weekends with social events.",
                        confidence: 0.76,
                        icon: "exclamationmark.triangle.fill",
                        actionable: false
                    )
                ],
                summary: "Most productive in mornings with strong Tuesday patterns. Consider expanding evening reflections."
            )
        }
    }
}
