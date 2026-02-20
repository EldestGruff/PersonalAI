//
//  Chart3DDataService.swift
//  STASH
//
//  Issue #25: 3D Thought Visualizations - Data Service
//  Transforms thought data into 3D visualization structures
//

import Foundation

/// Service for generating 3D chart data from thoughts
@MainActor
final class Chart3DDataService {

    // MARK: - Dependencies

    private let thoughtService: ThoughtServiceProtocol
    private let healthKitService: HealthKitServiceProtocol?

    // MARK: - Initialization

    init(
        thoughtService: ThoughtServiceProtocol,
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        self.thoughtService = thoughtService
        self.healthKitService = healthKitService
    }

    // MARK: - Helper: Sentiment to Double Conversion

    private func sentimentToDouble(_ sentiment: Sentiment) -> Double {
        switch sentiment {
        case .very_negative: return -1.0
        case .negative: return -0.5
        case .neutral: return 0.0
        case .positive: return 0.5
        case .very_positive: return 1.0
        }
    }

    private func energyToDouble(_ energy: EnergyLevel) -> Double {
        switch energy {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .peak: return 1.0
        }
    }

    // MARK: - Thought Space 3D (Time × Sentiment × Energy)

    /// Generate 3D thought space data points
    func getThoughtSpace3D(dateRange: ChartDateRange) async throws -> [ThoughtSpace3DPoint] {
        let thoughts = try await thoughtService.list(filter: nil)
        let filtered = filterThoughts(thoughts, by: dateRange)

        return filtered.compactMap { thought -> ThoughtSpace3DPoint? in
            guard let sentiment = thought.classification?.sentiment else {
                return nil
            }

            let calendar = Calendar.current
            let hour = Double(calendar.component(.hour, from: thought.createdAt))
            let energyLevel = energyToDouble(thought.context.energy)

            return ThoughtSpace3DPoint(
                thoughtId: thought.id,
                hourOfDay: hour,
                sentiment: sentimentToDouble(sentiment),
                energyLevel: energyLevel,
                content: thought.content,
                date: thought.createdAt
            )
        }
    }

    // MARK: - Health Correlation 3D (Sleep × HRV × Sentiment)

    /// Generate 3D health correlation cube data
    func getHealthCorrelation3D(dateRange: ChartDateRange) async throws -> [HealthCorrelation3DPoint] {
        let thoughts = try await thoughtService.list(filter: nil)
        let filtered = filterThoughts(thoughts, by: dateRange)

        // Group thoughts by date
        let calendar = Calendar.current
        var dailyData: [Date: (thoughts: [Thought], sleepHours: Double?, hrvScore: Double?)] = [:]

        for thought in filtered {
            let dayStart = calendar.startOfDay(for: thought.createdAt)

            if dailyData[dayStart] == nil {
                dailyData[dayStart] = (thoughts: [], sleepHours: nil, hrvScore: nil)
            }
            dailyData[dayStart]?.thoughts.append(thought)
        }

        // Fetch health data for each day if available
        if let healthKit = healthKitService {
            for (date, _) in dailyData {
                // Fetch sleep hours for the night before this day
                let sleepStart = calendar.date(byAdding: .day, value: -1, to: date)!
                let sleepEnd = date
                let sleepHours = try? await healthKit.getSleepHours(from: sleepStart, to: sleepEnd)

                // Fetch HRV for this day
                let hrvScore = try? await healthKit.getHRV(for: date)

                dailyData[date]?.sleepHours = sleepHours
                dailyData[date]?.hrvScore = hrvScore
            }
        }

        // Create 3D points
        return dailyData.compactMap { (date, data) -> HealthCorrelation3DPoint? in
            // Calculate average sentiment for the day
            let sentiments = data.thoughts.compactMap { $0.classification?.sentiment }
            guard !sentiments.isEmpty else { return nil }

            let sentimentValues = sentiments.map { sentimentToDouble($0) }
            let avgSentiment = sentimentValues.reduce(0.0, +) / Double(sentimentValues.count)

            return HealthCorrelation3DPoint(
                date: date,
                sleepHours: data.sleepHours ?? 7.0,  // Default to 7 hours if no data
                hrvScore: data.hrvScore ?? 50.0,      // Default to mid-range if no data
                sentiment: avgSentiment,
                thoughtCount: data.thoughts.count
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Trend Surface 3D (Date × Hour → Volume)

    /// Generate 3D surface data for thought volume trends
    func getTrendSurface3D(dateRange: ChartDateRange) async throws -> TrendSurface3DData {
        let thoughts = try await thoughtService.list(filter: nil)
        let filtered = filterThoughts(thoughts, by: dateRange)

        // Create grid of date x hour
        let calendar = Calendar.current
        var grid: [Date: [Int: Int]] = [:]  // date -> hour -> count

        for thought in filtered {
            let dayStart = calendar.startOfDay(for: thought.createdAt)
            let hour = calendar.component(.hour, from: thought.createdAt)

            if grid[dayStart] == nil {
                grid[dayStart] = [:]
            }
            grid[dayStart]?[hour, default: 0] += 1
        }

        // Convert to surface points
        var points: [TrendSurface3DPoint] = []
        var maxCount = 0

        for (date, hours) in grid {
            for hour in 0..<24 {
                let count = hours[hour] ?? 0
                maxCount = max(maxCount, count)

                points.append(TrendSurface3DPoint(
                    date: date,
                    hourOfDay: hour,
                    thoughtCount: count
                ))
            }
        }

        let dates = grid.keys.sorted()
        guard let firstDate = dates.first, let lastDate = dates.last else {
            // Return empty data if no thoughts found
            return TrendSurface3DData(
                points: [],
                dateRange: Date()...Date(),
                maxCount: 0
            )
        }

        return TrendSurface3DData(
            points: points,
            dateRange: firstDate...lastDate,
            maxCount: maxCount
        )
    }

    // MARK: - Tag Semantic Space 3D

    /// Generate 3D semantic space for tags (simplified version - no real embeddings yet)
    func getTagSemantic3D(dateRange: ChartDateRange) async throws -> [TagSemantic3DPoint] {
        let thoughts = try await thoughtService.list(filter: nil)
        let filtered = filterThoughts(thoughts, by: dateRange)

        // Count tag frequencies
        var tagCounts: [String: Int] = [:]
        var tagCooccurrences: [String: Set<String>] = [:]

        for thought in filtered {
            let tags = thought.tags
            for tag in tags {
                tagCounts[tag, default: 0] += 1

                // Track co-occurrences
                if tagCooccurrences[tag] == nil {
                    tagCooccurrences[tag] = Set()
                }
                for otherTag in tags where otherTag != tag {
                    tagCooccurrences[tag]?.insert(otherTag)
                }
            }
        }

        // Get top tags (limit to prevent overcrowding)
        let topTags = tagCounts.sorted { $0.value > $1.value }.prefix(30)

        // Generate pseudo-3D positions based on co-occurrence patterns
        // (This is a simplified version - real implementation would use embeddings or PCA)
        return topTags.enumerated().map { (index, tagData) in
            let (tag, frequency) = tagData

            // Simple circular distribution with some randomness
            let angle = Double(index) * (2.0 * .pi / Double(topTags.count))
            let radius = Double.random(in: 0.5...1.5)

            let x = cos(angle) * radius
            let y = sin(angle) * radius
            let z = Double.random(in: -0.5...0.5)

            let related = Array(tagCooccurrences[tag] ?? []).prefix(3)

            return TagSemantic3DPoint(
                tag: tag,
                dimension1: x,
                dimension2: y,
                dimension3: z,
                frequency: frequency,
                relatedTags: Array(related)
            )
        }
    }

    // MARK: - Helper Methods

    private func filterThoughts(_ thoughts: [Thought], by dateRange: ChartDateRange) -> [Thought] {
        let now = Date()
        let calendar = Calendar.current

        let startDate: Date
        switch dateRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        case .all:
            return thoughts
        }

        return thoughts.filter { thought in
            return thought.createdAt >= startDate
        }
    }
}

// MARK: - HealthKit Extension

extension HealthKitServiceProtocol {
    /// Get total sleep hours for a date range
    func getSleepHours(from startDate: Date, to endDate: Date) async throws -> Double {
        // Placeholder - implement actual HealthKit sleep query
        // For now, return mock data
        return Double.random(in: 5.0...9.0)
    }

    /// Get HRV score for a specific date
    func getHRV(for date: Date) async throws -> Double {
        // Placeholder - implement actual HealthKit HRV query
        // For now, return mock data
        return Double.random(in: 20.0...100.0)
    }
}
