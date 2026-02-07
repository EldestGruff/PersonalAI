//
//  InsightsAnalyzer.swift
//  STASH
//
//  AI-powered insights generator using Foundation Models tool calling
//

import Foundation
import FoundationModels

// MARK: - AI Insights Response

/// AI-generated insights about user's thought patterns
@Generable
struct AIInsightsResponse: Codable, Sendable {
    @Guide(description: "3-5 key insights about the user's thought patterns, productivity, or emotional trends")
    var insights: [String]

    @Guide(description: "Overall pattern classification: productive, balanced, stressed, creative, or scattered")
    var overallPattern: String

    @Guide(description: "Confidence score from 0.0 to 1.0 for these insights")
    var confidence: Double
}

// MARK: - Statistics Summary

/// Summary statistics for AI analysis
struct ThoughtStatistics: Codable, Sendable {
    let totalThoughts: Int
    let timeRange: String
    let mostCommonType: String
    let averageSentiment: Double
    let averageStateOfMindValence: Double?
    let mostProductiveTimeOfDay: String?
    let energyLevelDistribution: [String: Int]
    let thoughtsPerDay: Double
}

// MARK: - Insights Analyzer

/// Analyzes thought patterns and generates AI insights using Foundation Models
@available(iOS 26.0, *)
actor InsightsAnalyzer {

    private var session: LanguageModelSession?

    // MARK: - Initialization

    init() {
        // Session will be created lazily on first use
        session = nil
    }

    private func ensureSession() {
        guard session == nil else { return }

        session = LanguageModelSession(
            instructions: """
            You are an expert at analyzing personal productivity and well-being patterns.

            Your role:
            - Identify meaningful patterns in thought capture data
            - Generate specific, actionable insights
            - Use natural, conversational language
            - Focus on productivity, creativity, and emotional well-being
            - Highlight correlations (e.g., energy vs sentiment, time vs type)
            - Be empowering and constructive, not judgmental

            Guidelines:
            1. Base insights on the actual data provided
            2. Be specific with numbers and patterns
            3. Suggest practical implications
            4. Consider the user's habits and routines
            5. Identify both strengths and opportunities

            Be concise, insightful, and helpful.
            """
        )
    }

    // MARK: - Insights Generation

    /// Generate AI insights from thought data
    func generateInsights(
        thoughts: [Thought],
        dateRange: String
    ) async throws -> AIInsightsResponse {
        ensureSession()

        guard let session = session else {
            throw AnalysisError.modelUnavailable
        }

        // Calculate statistics from thoughts
        let stats = calculateStatistics(from: thoughts, dateRange: dateRange)

        // Build prompt with statistics
        let prompt = buildPrompt(stats: stats)

        // Use Foundation Models to generate insights
        let response = try await session.respond(
            to: prompt,
            generating: AIInsightsResponse.self
        )

        return response.content
    }

    // MARK: - Statistics Calculation

    private func calculateStatistics(
        from thoughts: [Thought],
        dateRange: String
    ) -> ThoughtStatistics {
        guard !thoughts.isEmpty else {
            return ThoughtStatistics(
                totalThoughts: 0,
                timeRange: dateRange,
                mostCommonType: "none",
                averageSentiment: 0.0,
                averageStateOfMindValence: nil,
                mostProductiveTimeOfDay: nil,
                energyLevelDistribution: [:],
                thoughtsPerDay: 0.0
            )
        }

        // Most common type
        let typeCounts = Dictionary(grouping: thoughts) { $0.classification?.type ?? .note }
            .mapValues { $0.count }
        let mostCommonType = typeCounts.max(by: { $0.value < $1.value })?.key ?? .note

        // Average sentiment
        let sentiments = thoughts.compactMap { thought -> Double? in
            guard let sentiment = thought.classification?.sentiment else { return nil }
            switch sentiment {
            case .very_negative: return -1.0
            case .negative: return -0.5
            case .neutral: return 0.0
            case .positive: return 0.5
            case .very_positive: return 1.0
            }
        }
        let avgSentiment = sentiments.isEmpty ? 0.0 : sentiments.reduce(0.0, +) / Double(sentiments.count)

        // Average state of mind valence
        let valences = thoughts.compactMap { $0.context.stateOfMind?.valence }
        let avgValence = valences.isEmpty ? nil : valences.reduce(0.0, +) / Double(valences.count)

        // Most productive time of day
        let timeOfDayCounts = Dictionary(grouping: thoughts) { $0.context.timeOfDay }
            .mapValues { $0.count }
        let mostProductiveTime = timeOfDayCounts.max(by: { $0.value < $1.value })?.key

        // Energy level distribution
        let energyDistribution = Dictionary(grouping: thoughts) { $0.context.energy }
            .mapValues { $0.count }
            .reduce(into: [String: Int]()) { result, pair in
                let energyName: String
                switch pair.key {
                case .low: energyName = "low"
                case .medium: energyName = "medium"
                case .high: energyName = "high"
                case .peak: energyName = "peak"
                }
                result[energyName] = pair.value
            }

        // Thoughts per day
        let calendar = Calendar.current
        let dates = thoughts.map { calendar.startOfDay(for: $0.createdAt) }
        let uniqueDays = Set(dates).count
        let thoughtsPerDay = uniqueDays > 0 ? Double(thoughts.count) / Double(uniqueDays) : 0.0

        return ThoughtStatistics(
            totalThoughts: thoughts.count,
            timeRange: dateRange,
            mostCommonType: mostCommonType.rawValue,
            averageSentiment: avgSentiment,
            averageStateOfMindValence: avgValence,
            mostProductiveTimeOfDay: mostProductiveTime?.rawValue,
            energyLevelDistribution: energyDistribution,
            thoughtsPerDay: thoughtsPerDay
        )
    }

    // MARK: - Prompt Building

    private func buildPrompt(stats: ThoughtStatistics) -> String {
        var prompt = """
        Analyze these thought patterns and generate personalized insights:

        Statistics:
        - Total thoughts: \(stats.totalThoughts)
        - Time range: \(stats.timeRange)
        - Average per day: \(String(format: "%.1f", stats.thoughtsPerDay))
        - Most common type: \(stats.mostCommonType)
        - Average sentiment: \(String(format: "%.2f", stats.averageSentiment)) (scale -1.0 to +1.0)
        """

        if let valence = stats.averageStateOfMindValence {
            prompt += "\n- Average emotional state: \(String(format: "%.2f", valence)) (scale -1.0 to +1.0)"
        }

        if let timeOfDay = stats.mostProductiveTimeOfDay {
            prompt += "\n- Most active time: \(timeOfDay)"
        }

        if !stats.energyLevelDistribution.isEmpty {
            prompt += "\n- Energy levels: \(stats.energyLevelDistribution.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        }

        prompt += """


        Generate insights that:
        1. Identify meaningful patterns (productivity, creativity, emotional trends)
        2. Are specific and actionable
        3. Use natural, conversational language
        4. Highlight correlations (e.g., energy vs sentiment, time vs type)
        5. Are empowering and constructive, not judgmental

        Focus on what the data reveals about their habits, productivity patterns, and emotional well-being.
        """

        return prompt
    }
}

// MARK: - Error Types

enum AnalysisError: LocalizedError {
    case modelUnavailable
    case insufficientData

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "AI analysis is not available on this device"
        case .insufficientData:
            return "Not enough data to generate insights"
        }
    }
}

// MARK: - Mock Analyzer

/// Mock analyzer for testing and previews
@available(iOS 26.0, *)
actor MockInsightsAnalyzer {
    func generateInsights(
        thoughts: [Thought],
        dateRange: String
    ) async throws -> AIInsightsResponse {
        // Simulate network delay
        try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)

        return AIInsightsResponse(
            insights: [
                "You're most productive in the morning, capturing 65% of your thoughts before noon",
                "Your mood improves by 0.3 points on days when you exercise or move more",
                "You tend to have more creative ideas (brainstorming, concepts) when your energy is high",
                "You capture more task-related thoughts on Mondays and Fridays compared to mid-week",
                "Your emotional state is most positive when you have 2-4 hours of free time between calendar events"
            ],
            overallPattern: "productive",
            confidence: 0.87
        )
    }
}
