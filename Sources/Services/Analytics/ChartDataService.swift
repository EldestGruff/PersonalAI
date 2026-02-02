//
//  ChartDataService.swift
//  PersonalAI
//
//  Issue #18: Swift Charts - Data Aggregation Service
//  Actor-based service for chart data with caching and performance optimization
//

import Foundation

/// Cache key for chart data
private struct CacheKey: Hashable {
    let chartType: ChartType
    let dateRange: ChartDateRange

    enum ChartType: Hashable {
        case sentimentTrend
        case typeDistribution
        case tagFrequency(limit: Int)
        case captureHeatmap
        case healthCorrelation
        case streakData
        case confidenceTrends
    }
}

/// Cached data with TTL
private struct CachedData {
    let data: Any
    let timestamp: Date
    let ttl: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

/// Actor-based service for chart data aggregation with caching
///
/// Design rationale:
/// - Actor isolation for thread safety with concurrent UI access
/// - In-memory cache with TTL to avoid re-aggregating on every view
/// - Background computation for expensive aggregations
/// - Optimized Core Data queries for 10,000+ thoughts
actor ChartDataService {

    // MARK: - Dependencies

    private let thoughtService: ThoughtServiceProtocol
    private let healthKitService: HealthKitServiceProtocol

    // MARK: - Cache

    private var cache: [CacheKey: CachedData] = [:]
    private let defaultCacheTTL: TimeInterval = 300 // 5 minutes
    private let streakCacheTTL: TimeInterval = 3600 // 1 hour (streaks change slowly)

    // MARK: - Initialization

    init(
        thoughtService: ThoughtServiceProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.thoughtService = thoughtService
        self.healthKitService = healthKitService
    }

    // MARK: - Public API

    /// Get sentiment trend data with caching
    func getSentimentTrend(dateRange: ChartDateRange) async throws -> [SentimentDataPoint] {
        let key = CacheKey(chartType: .sentimentTrend, dateRange: dateRange)

        if let cached = getCachedData(for: key) as? [SentimentDataPoint] {
            return cached
        }

        let data = try await computeSentimentTrend(dateRange: dateRange)
        setCachedData(data, for: key, ttl: defaultCacheTTL)
        return data
    }

    /// Get thought type distribution with caching
    func getTypeDistribution(dateRange: ChartDateRange) async throws -> [ThoughtTypeCount] {
        let key = CacheKey(chartType: .typeDistribution, dateRange: dateRange)

        if let cached = getCachedData(for: key) as? [ThoughtTypeCount] {
            return cached
        }

        let data = try await computeTypeDistribution(dateRange: dateRange)
        setCachedData(data, for: key, ttl: defaultCacheTTL)
        return data
    }

    /// Get tag frequency data with caching
    func getTagFrequency(dateRange: ChartDateRange, limit: Int = 10) async throws -> [TagPopularity] {
        let key = CacheKey(chartType: .tagFrequency(limit: limit), dateRange: dateRange)

        if let cached = getCachedData(for: key) as? [TagPopularity] {
            return cached
        }

        let data = try await computeTagFrequency(dateRange: dateRange, limit: limit)
        setCachedData(data, for: key, ttl: defaultCacheTTL)
        return data
    }

    /// Get capture pattern heatmap data with caching
    func getCaptureHeatmap(dateRange: ChartDateRange) async throws -> CaptureHeatmapResult {
        let key = CacheKey(chartType: .captureHeatmap, dateRange: dateRange)

        if let cached = getCachedData(for: key) as? CaptureHeatmapResult {
            return cached
        }

        let data = try await computeCaptureHeatmap(dateRange: dateRange)
        setCachedData(data, for: key, ttl: defaultCacheTTL)
        return data
    }

    /// Get health correlation data with caching
    func getHealthCorrelation(dateRange: ChartDateRange) async throws -> HealthCorrelationData {
        let key = CacheKey(chartType: .healthCorrelation, dateRange: dateRange)

        if let cached = getCachedData(for: key) as? HealthCorrelationData {
            return cached
        }

        let data = try await computeHealthCorrelation(dateRange: dateRange)
        setCachedData(data, for: key, ttl: defaultCacheTTL)
        return data
    }

    /// Get streak data with longer caching (streaks change slowly)
    func getStreakData() async throws -> StreakData {
        let key = CacheKey(chartType: .streakData, dateRange: .all)

        if let cached = getCachedData(for: key) as? StreakData {
            return cached
        }

        let data = try await computeStreakData()
        setCachedData(data, for: key, ttl: streakCacheTTL)
        return data
    }

    /// Get confidence trends data with caching
    func getConfidenceTrends(dateRange: ChartDateRange) async throws -> [ConfidenceDataPoint] {
        let key = CacheKey(chartType: .confidenceTrends, dateRange: dateRange)

        if let cached = getCachedData(for: key) as? [ConfidenceDataPoint] {
            return cached
        }

        let data = try await computeConfidenceTrends(dateRange: dateRange)
        setCachedData(data, for: key, ttl: defaultCacheTTL)
        return data
    }

    /// Get summary metrics across all charts
    func getSummaryMetrics(dateRange: ChartDateRange) async throws -> ChartSummaryMetrics {
        // Don't cache summary metrics - they're cheap to compute from other cached data
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)

        let totalThoughts = thoughts.count

        // Average sentiment
        let sentiments = thoughts.compactMap { thought -> Double? in
            guard let sentiment = thought.classification?.sentiment else { return nil }
            return sentiment.numericalValue
        }
        let averageSentiment = sentiments.isEmpty ? 0.0 : sentiments.reduce(0.0, +) / Double(sentiments.count)

        // Most common type
        let typeGroups = Dictionary(grouping: thoughts) { $0.classification?.type ?? .note }
        let mostCommonType = typeGroups.max(by: { $0.value.count < $1.value.count })?.key

        // Top tag
        let allTags = thoughts.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }
        let topTag = tagCounts.max(by: { $0.value < $1.value })?.key

        // Streaks (use cached streak data if available)
        let streakData = try await getStreakData()

        return ChartSummaryMetrics(
            totalThoughts: totalThoughts,
            averageSentiment: averageSentiment,
            mostCommonType: mostCommonType,
            topTag: topTag,
            currentStreak: streakData.currentStreak,
            longestStreak: streakData.longestStreak
        )
    }

    // MARK: - Cache Management

    /// Invalidate all cached data
    func invalidateCache() {
        cache.removeAll()
    }

    /// Invalidate cache for a specific date range
    func invalidateCache(for dateRange: ChartDateRange) {
        cache = cache.filter { key, _ in
            key.dateRange != dateRange
        }
    }

    /// Invalidate all caches (called when a thought is created/updated/deleted)
    func invalidateAllCaches() {
        cache.removeAll()
    }

    // MARK: - Private Computation Methods

    private func computeSentimentTrend(dateRange: ChartDateRange) async throws -> [SentimentDataPoint] {
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)
        let calendar = Calendar.current

        // Group by day
        let grouped = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        // Calculate average sentiment per day
        return grouped.compactMap { date, dayThoughts in
            let sentiments = dayThoughts.compactMap { $0.classification?.sentiment?.numericalValue }
            guard !sentiments.isEmpty else { return nil }

            let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)

            return SentimentDataPoint(
                date: date,
                averageSentiment: avgSentiment,
                thoughtCount: dayThoughts.count
            )
        }
        .sorted { $0.date < $1.date }
    }

    private func computeTypeDistribution(dateRange: ChartDateRange) async throws -> [ThoughtTypeCount] {
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)

        // Group by type
        let grouped = Dictionary(grouping: thoughts) { thought in
            thought.classification?.type ?? .note
        }

        let total = Double(thoughts.count)

        return grouped.map { type, typeThoughts in
            ThoughtTypeCount(
                type: ThoughtType(rawValue: type.rawValue) ?? .note,
                count: typeThoughts.count,
                percentage: Double(typeThoughts.count) / total
            )
        }
        .sorted { $0.count > $1.count }
    }

    private func computeTagFrequency(dateRange: ChartDateRange, limit: Int) async throws -> [TagPopularity] {
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)

        // Flatten all tags and count
        let allTags = thoughts.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }
        let total = Double(allTags.count)

        return tagCounts.map { tag, count in
            TagPopularity(
                tag: tag,
                count: count,
                percentage: Double(count) / total
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(limit)
        .map { $0 }
    }

    private func computeCaptureHeatmap(dateRange: ChartDateRange) async throws -> CaptureHeatmapResult {
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)
        let calendar = Calendar.current

        // Hour of day distribution (0-23)
        var hourCounts: [Int: Int] = [:] // hour -> count
        var hourSentiments: [Int: [Double]] = [:] // hour -> sentiments

        // Day of week distribution (1=Sunday, 7=Saturday)
        var dayCounts: [Int: Int] = [:] // day -> count
        var daySentiments: [Int: [Double]] = [:] // day -> sentiments

        // Full 7x24 matrix
        var hourByDayMatrix: [[Int]] = Array(repeating: Array(repeating: 0, count: 24), count: 7)

        for thought in thoughts {
            let hour = calendar.component(.hour, from: thought.createdAt)
            let weekday = calendar.component(.weekday, from: thought.createdAt)

            // Hour counts
            hourCounts[hour, default: 0] += 1
            if let sentiment = thought.classification?.sentiment?.numericalValue {
                hourSentiments[hour, default: []].append(sentiment)
            }

            // Day counts
            dayCounts[weekday, default: 0] += 1
            if let sentiment = thought.classification?.sentiment?.numericalValue {
                daySentiments[weekday, default: []].append(sentiment)
            }

            // Matrix (weekday-1 because array is 0-indexed)
            hourByDayMatrix[weekday - 1][hour] += 1
        }

        // Convert to data points
        let hourDataPoints = (0..<24).map { hour in
            let count = hourCounts[hour] ?? 0
            let avgSentiment: Double? = {
                guard let sentiments = hourSentiments[hour], !sentiments.isEmpty else { return nil }
                return sentiments.reduce(0.0, +) / Double(sentiments.count)
            }()

            return HourDataPoint(hour: hour, count: count, averageSentiment: avgSentiment)
        }

        let dayDataPoints = (1...7).map { day in
            let count = dayCounts[day] ?? 0
            let avgSentiment: Double? = {
                guard let sentiments = daySentiments[day], !sentiments.isEmpty else { return nil }
                return sentiments.reduce(0.0, +) / Double(sentiments.count)
            }()

            return DayDataPoint(dayOfWeek: day, count: count, averageSentiment: avgSentiment)
        }

        return CaptureHeatmapResult(
            hourOfDayDistribution: hourDataPoints,
            dayOfWeekDistribution: dayDataPoints,
            hourByDayMatrix: hourByDayMatrix
        )
    }

    private func computeHealthCorrelation(dateRange: ChartDateRange) async throws -> HealthCorrelationData {
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)
        let calendar = Calendar.current

        // Group thoughts by day
        let thoughtsByDay = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        // For each day, get health data and thought metrics
        var sleepSentimentPoints: [SleepSentimentPoint] = []
        var stepsVolumePoints: [StepsVolumePoint] = []

        for (date, dayThoughts) in thoughtsByDay {
            // Calculate average sentiment for the day
            let sentiments = dayThoughts.compactMap { $0.classification?.sentiment?.numericalValue }
            guard !sentiments.isEmpty else { continue }
            let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)

            // Get health data for this day
            // Note: HealthKitService currently only provides real-time data
            // For historical correlation, we'd need to query HealthKit's historical samples
            // For now, we'll use the context data that was captured with each thought

            // Sleep correlation (using energy breakdown from thought context)
            let sleepHours = dayThoughts.compactMap { thought -> Double? in
                thought.context.energyBreakdown?.sleepHours
            }
            if let avgSleep = sleepHours.isEmpty ? nil : sleepHours.reduce(0.0, +) / Double(sleepHours.count) {
                sleepSentimentPoints.append(
                    SleepSentimentPoint(
                        date: date,
                        sleepHours: avgSleep,
                        sentiment: avgSentiment
                    )
                )
            }

            // Steps correlation (using activity context)
            let steps = dayThoughts.compactMap { thought -> Int? in
                thought.context.activity?.stepCount
            }
            if let avgSteps = steps.isEmpty ? nil : steps.reduce(0, +) / steps.count {
                stepsVolumePoints.append(
                    StepsVolumePoint(
                        date: date,
                        steps: avgSteps,
                        thoughtCount: dayThoughts.count
                    )
                )
            }
        }

        // Calculate correlation coefficients
        let sleepCorrelation = calculatePearsonCorrelation(
            x: sleepSentimentPoints.map { $0.sleepHours },
            y: sleepSentimentPoints.map { $0.sentiment }
        )

        let stepsCorrelation = calculatePearsonCorrelation(
            x: stepsVolumePoints.map { Double($0.steps) },
            y: stepsVolumePoints.map { Double($0.thoughtCount) }
        )

        let description = generateCorrelationDescription(
            sleepCorrelation: sleepCorrelation,
            stepsCorrelation: stepsCorrelation
        )

        return HealthCorrelationData(
            sleepVsSentiment: sleepSentimentPoints,
            stepsVsVolume: stepsVolumePoints,
            correlationCoefficients: CorrelationSummary(
                sleepSentimentCorrelation: sleepCorrelation,
                stepsVolumeCorrelation: stepsCorrelation,
                description: description
            )
        )
    }

    private func computeStreakData() async throws -> StreakData {
        // Get all thoughts (not filtered by date range)
        let thoughts = try await thoughtService.list(filter: nil)
        let calendar = Calendar.current

        // Get unique dates with thoughts
        let datesWithThoughts = Set(thoughts.map { thought in
            calendar.startOfDay(for: thought.createdAt)
        })
        .sorted()

        // Calculate current streak
        var currentStreak = 0
        var date = calendar.startOfDay(for: Date())

        while datesWithThoughts.contains(date) {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDay
        }

        // Calculate longest streak
        var longestStreak = 0
        var currentStreakLength = 0
        var previousDate: Date?

        for date in datesWithThoughts {
            if let prev = previousDate,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: prev),
               nextDay == date {
                // Continue streak
                currentStreakLength += 1
            } else {
                // Start new streak
                currentStreakLength = 1
            }

            longestStreak = max(longestStreak, currentStreakLength)
            previousDate = date
        }

        // Build streak history (last 90 days for visualization)
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date())!
        let recentDates = datesWithThoughts.filter { $0 >= ninetyDaysAgo }

        var streakPeriods: [StreakPeriod] = []
        var streakStart: Date?
        var streakEnd: Date?
        previousDate = nil

        for date in recentDates {
            if let prev = previousDate,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: prev),
               nextDay == date {
                // Continue streak
                streakEnd = date
            } else {
                // Save previous streak if it exists
                if let start = streakStart, let end = streakEnd {
                    let length = calendar.dateComponents([.day], from: start, to: end).day! + 1
                    streakPeriods.append(StreakPeriod(startDate: start, endDate: end, length: length))
                }
                // Start new streak
                streakStart = date
                streakEnd = date
            }
            previousDate = date
        }

        // Add final streak
        if let start = streakStart, let end = streakEnd {
            let length = calendar.dateComponents([.day], from: start, to: end).day! + 1
            streakPeriods.append(StreakPeriod(startDate: start, endDate: end, length: length))
        }

        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysWithThoughts: datesWithThoughts.count,
            streakHistory: streakPeriods
        )
    }

    private func computeConfidenceTrends(dateRange: ChartDateRange) async throws -> [ConfidenceDataPoint] {
        let thoughts = try await getFilteredThoughts(dateRange: dateRange)
        let calendar = Calendar.current

        // Group by day
        let grouped = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        return grouped.compactMap { date, dayThoughts in
            // Get thoughts with confidence scores
            let withConfidence = dayThoughts.filter { $0.classification?.confidence != nil }
            guard !withConfidence.isEmpty else { return nil }

            // Average confidence
            let avgConfidence = withConfidence
                .compactMap { $0.classification?.confidence }
                .reduce(0.0, +) / Double(withConfidence.count)

            // Confidence by type
            var byType: [ClassificationType: Double] = [:]
            let typeGroups = Dictionary(grouping: withConfidence) { $0.classification?.type ?? .note }

            for (type, typeThoughts) in typeGroups {
                let typeConfidence = typeThoughts
                    .compactMap { $0.classification?.confidence }
                    .reduce(0.0, +) / Double(typeThoughts.count)
                byType[type] = typeConfidence
            }

            return ConfidenceDataPoint(
                date: date,
                averageConfidence: avgConfidence,
                thoughtCount: withConfidence.count,
                byType: byType
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Helper Methods

    private func getFilteredThoughts(dateRange: ChartDateRange) async throws -> [Thought] {
        let allThoughts = try await thoughtService.list(filter: nil)

        guard let startDate = dateRange.startDate else {
            return allThoughts // No filter for "all time"
        }

        return allThoughts.filter { $0.createdAt >= startDate }
    }

    private func getCachedData(for key: CacheKey) -> Any? {
        guard let cached = cache[key], !cached.isExpired else {
            return nil
        }
        return cached.data
    }

    private func setCachedData(_ data: Any, for key: CacheKey, ttl: TimeInterval) {
        cache[key] = CachedData(data: data, timestamp: Date(), ttl: ttl)
    }

    /// Calculate Pearson correlation coefficient
    private func calculatePearsonCorrelation(x: [Double], y: [Double]) -> Double? {
        guard x.count == y.count, x.count > 1 else { return nil }

        let n = Double(x.count)
        let sumX = x.reduce(0.0, +)
        let sumY = y.reduce(0.0, +)
        let sumXY = zip(x, y).map(*).reduce(0.0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0.0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0.0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return nil }

        return numerator / denominator
    }

    private func generateCorrelationDescription(
        sleepCorrelation: Double?,
        stepsCorrelation: Double?
    ) -> String {
        var parts: [String] = []

        if let sleep = sleepCorrelation {
            let strength = abs(sleep)
            let direction = sleep > 0 ? "improves" : "declines"

            if strength > 0.7 {
                parts.append("Your mood strongly \(direction) with more sleep")
            } else if strength > 0.4 {
                parts.append("Your mood moderately \(direction) with more sleep")
            } else if strength > 0.2 {
                parts.append("Your mood slightly \(direction) with more sleep")
            }
        }

        if let steps = stepsCorrelation {
            let strength = abs(steps)
            let direction = steps > 0 ? "increases" : "decreases"

            if strength > 0.7 {
                parts.append("You capture significantly more thoughts on active days")
            } else if strength > 0.4 {
                parts.append("You capture moderately more thoughts on active days")
            }
        }

        return parts.isEmpty ? "Not enough data to determine correlations" : parts.joined(separator: ". ")
    }
}

// MARK: - Sentiment Helper

extension Sentiment {
    var numericalValue: Double {
        switch self {
        case .very_negative: return -1.0
        case .negative: return -0.5
        case .neutral: return 0.0
        case .positive: return 0.5
        case .very_positive: return 1.0
        }
    }
}
