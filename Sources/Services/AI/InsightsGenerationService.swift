//
//  InsightsGenerationService.swift
//  PersonalAI
//
//  AI-powered insights generation using Apple Foundation Models
//  Analyzes patterns across health, time, mood, and productivity
//

import Foundation
import FoundationModels

// MARK: - Insights Context

/// Input data structure for AI insights generation
struct InsightsContext: Codable, Sendable {
    // Summary metrics
    let totalThoughts: Int
    let averageSentiment: Double
    let currentStreak: Int
    let longestStreak: Int

    // Patterns
    let topTags: [String: Int]  // tag -> count
    let thoughtsByHour: [Int: Int]  // hour -> count
    let thoughtsByDay: [String: Int]  // weekday -> count
    let typeDistribution: [String: Int]  // type -> count

    // Health correlations
    let sleepCorrelation: Double?
    let stepsCorrelation: Double?
    let hrvCorrelation: Double?
    let workoutCorrelation: Double?
    let restingHRCorrelation: Double?

    // Recent trends
    let sentimentTrend: String  // "improving", "declining", "stable"
    let volumeTrend: String  // "increasing", "decreasing", "stable"

    // Time period
    let dateRangeDescription: String  // "this week", "this month", etc.
}

// MARK: - Generated Insights

/// Output structure from AI insights generation
struct GeneratedInsights: Codable, Sendable {
    let patterns: [InsightItem]  // 2-3 key patterns identified
    let recommendations: [InsightItem]  // 1-2 actionable suggestions
    let achievements: [InsightItem]  // 0-1 positive highlights
    let anomalies: [InsightItem]  // 0-1 unusual patterns
    let summary: String  // One-sentence overview

    /// Total number of insights
    var totalCount: Int {
        patterns.count + recommendations.count + achievements.count + anomalies.count
    }

    /// Check if there are any insights
    var isEmpty: Bool {
        totalCount == 0
    }
}

/// Individual insight item
struct InsightItem: Identifiable, Codable, Sendable {
    let id: UUID
    let type: InsightType
    let title: String  // Short headline
    let description: String  // Detailed explanation
    let confidence: Double  // 0.0-1.0
    let icon: String  // SF Symbol name
    let actionable: Bool  // Can user act on this?

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        confidence: Double,
        icon: String,
        actionable: Bool
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.icon = icon
        self.actionable = actionable
    }
}

/// Types of insights the AI can generate
enum InsightType: String, Codable, Sendable, CaseIterable {
    case pattern  // Recurring behaviors
    case recommendation  // Suggested actions
    case achievement  // Positive milestones
    case anomaly  // Unusual patterns
    case correlation  // Health relationships

    var displayName: String {
        switch self {
        case .pattern: return "Pattern"
        case .recommendation: return "Recommendation"
        case .achievement: return "Achievement"
        case .anomaly: return "Anomaly"
        case .correlation: return "Correlation"
        }
    }

    var defaultIcon: String {
        switch self {
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .recommendation: return "lightbulb.fill"
        case .achievement: return "trophy.fill"
        case .anomaly: return "exclamationmark.triangle.fill"
        case .correlation: return "link"
        }
    }

    var color: String {
        switch self {
        case .pattern: return "blue"
        case .recommendation: return "orange"
        case .achievement: return "yellow"
        case .anomaly: return "purple"
        case .correlation: return "green"
        }
    }
}

// MARK: - Foundation Models Response

/// Structured response from Foundation Models
@Generable
struct InsightsGenerationResponse: Codable {
    @Guide(description: "2-3 key patterns identified in the user's data (recurring behaviors, peak times, common themes)")
    var patterns: [GeneratedInsightItem]

    @Guide(description: "1-2 actionable recommendations based on the data and correlations")
    var recommendations: [GeneratedInsightItem]

    @Guide(description: "0-1 positive achievements or milestones worth celebrating", .count(0...1))
    var achievements: [GeneratedInsightItem]

    @Guide(description: "0-1 unusual patterns or anomalies worth noting", .count(0...1))
    var anomalies: [GeneratedInsightItem]

    @Guide(description: "A single sentence (under 100 characters) summarizing the key insight")
    var summary: String
}

@Generable
struct GeneratedInsightItem: Codable {
    @Guide(description: "Short headline (3-6 words)")
    var title: String

    @Guide(description: "Detailed explanation (1-2 sentences, reference specific data)")
    var description: String

    @Guide(description: "Confidence score from 0.0 to 1.0")
    var confidence: Double

    @Guide(description: "SF Symbol name for the insight icon (e.g., 'sunrise.fill', 'figure.walk', 'brain.head.profile')")
    var icon: String

    @Guide(description: "Whether this insight suggests a concrete action the user can take")
    var actionable: Bool
}

// MARK: - Insights Generation Service

/// Actor-based service for generating AI-powered insights using Foundation Models
@available(iOS 26.0, *)
actor InsightsGenerationService {

    // MARK: - Properties

    private var session: LanguageModelSession?

    /// Cache for generated insights
    private var insightsCache: [String: CachedInsights] = [:]

    /// Cache TTL: 30 minutes
    private let cacheTTL: TimeInterval = 1800

    /// Availability status of Apple Intelligence
    nonisolated var isAvailable: Bool {
        SystemLanguageModel().availability == .available
    }

    // MARK: - Initialization

    init() {
        // Session will be created lazily on first use
    }

    // MARK: - Session Setup

    private func ensureSession() {
        guard session == nil else { return }

        guard SystemLanguageModel().availability == .available else {
            print("Warning: Apple Intelligence not available for insights generation")
            return
        }

        session = LanguageModelSession(
            instructions: """
            You are an AI assistant analyzing personal thought capture patterns. Generate insights that are:
            - Specific and data-driven (reference actual numbers from the provided data)
            - Actionable (suggest concrete next steps when appropriate)
            - Empowering and positive in tone (celebrate wins, frame challenges constructively)
            - Protective of privacy (never suggest sharing data externally)
            - Based only on provided data (don't make assumptions)

            Your analysis should identify:
            1. KEY PATTERNS - Recurring behaviors, peak productivity times, common themes
            2. RECOMMENDATIONS - Actionable suggestions based on health correlations and patterns
            3. ACHIEVEMENTS - Celebrate positive milestones when present (streaks, improvements)
            4. ANOMALIES - Unusual patterns worth noting (without alarming the user)

            Guidelines for correlation interpretation:
            - Correlation > 0.7: Strong relationship
            - Correlation 0.4-0.7: Moderate relationship
            - Correlation 0.2-0.4: Weak relationship
            - Correlation < 0.2: No meaningful relationship

            Always provide specific numbers and be concise. Use conversational, friendly language.
            """
        )
    }

    // MARK: - Insights Generation

    /// Generate insights from the provided context
    /// - Parameter context: The aggregated data context
    /// - Returns: Generated insights with patterns, recommendations, achievements, and anomalies
    func generateInsights(from context: InsightsContext) async throws -> GeneratedInsights {
        // Check cache first
        let cacheKey = generateCacheKey(for: context)
        if let cached = insightsCache[cacheKey], !cached.isExpired {
            return cached.insights
        }

        // Ensure we have a session
        ensureSession()

        guard let session = session else {
            throw InsightsGenerationError.notAvailable
        }

        // Validate we have enough data
        guard context.totalThoughts >= 5 else {
            throw InsightsGenerationError.insufficientData(
                required: 5,
                actual: context.totalThoughts
            )
        }

        // Build prompt
        let prompt = buildPrompt(from: context)

        do {
            // Generate insights using Foundation Models
            let response = try await session.respond(
                to: prompt,
                generating: InsightsGenerationResponse.self
            )

            // Convert response to our data model
            let insights = convertToGeneratedInsights(response.content)

            // Cache the result
            insightsCache[cacheKey] = CachedInsights(
                insights: insights,
                timestamp: Date()
            )

            return insights

        } catch {
            NSLog("Failed to generate AI insights: \(error)")
            throw InsightsGenerationError.generationFailed(underlying: error)
        }
    }

    /// Generate fallback insights when AI is unavailable
    func generateFallbackInsights(from context: InsightsContext) -> GeneratedInsights {
        var patterns: [InsightItem] = []
        var recommendations: [InsightItem] = []
        var achievements: [InsightItem] = []
        let anomalies: [InsightItem] = []

        // Pattern: Peak hours
        if let peakHour = context.thoughtsByHour.max(by: { $0.value < $1.value }) {
            let hourName = formatHour(peakHour.key)
            patterns.append(InsightItem(
                type: .pattern,
                title: "Peak Capture Time",
                description: "You capture most thoughts around \(hourName), with \(peakHour.value) thoughts in \(context.dateRangeDescription).",
                confidence: 0.85,
                icon: "clock.fill",
                actionable: false
            ))
        }

        // Pattern: Top tag
        if let topTag = context.topTags.max(by: { $0.value < $1.value }) {
            patterns.append(InsightItem(
                type: .pattern,
                title: "Common Theme",
                description: "'\(topTag.key)' is your most used tag with \(topTag.value) thoughts.",
                confidence: 0.90,
                icon: "tag.fill",
                actionable: false
            ))
        }

        // Recommendation based on sleep correlation
        if let sleep = context.sleepCorrelation, abs(sleep) > 0.4 {
            let direction = sleep > 0 ? "better" : "lower"
            recommendations.append(InsightItem(
                type: .recommendation,
                title: "Sleep Matters",
                description: "Your mood is \(direction) with more sleep. Consider prioritizing 7-8 hours for optimal well-being.",
                confidence: 0.75,
                icon: "bed.double.fill",
                actionable: true
            ))
        }

        // Achievement: Streak
        if context.currentStreak >= 7 {
            achievements.append(InsightItem(
                type: .achievement,
                title: "\(context.currentStreak)-Day Streak!",
                description: "You've captured thoughts for \(context.currentStreak) consecutive days. Consistency builds powerful habits.",
                confidence: 1.0,
                icon: "flame.fill",
                actionable: false
            ))
        } else if context.currentStreak >= 3 {
            achievements.append(InsightItem(
                type: .achievement,
                title: "Building Momentum",
                description: "You're on a \(context.currentStreak)-day streak. Keep it up to build a lasting habit!",
                confidence: 1.0,
                icon: "arrow.up.forward",
                actionable: false
            ))
        }

        // Trend-based insights
        if context.sentimentTrend == "improving" {
            patterns.append(InsightItem(
                type: .pattern,
                title: "Mood Improving",
                description: "Your sentiment has been trending upward \(context.dateRangeDescription). Great progress!",
                confidence: 0.80,
                icon: "chart.line.uptrend.xyaxis",
                actionable: false
            ))
        }

        // Summary
        let summary = generateFallbackSummary(context: context)

        return GeneratedInsights(
            patterns: patterns,
            recommendations: recommendations,
            achievements: achievements,
            anomalies: anomalies,
            summary: summary
        )
    }

    // MARK: - Cache Management

    /// Invalidate all cached insights
    func invalidateCache() {
        insightsCache.removeAll()
    }

    /// Check if insights are cached and valid
    func hasCachedInsights(for context: InsightsContext) -> Bool {
        let cacheKey = generateCacheKey(for: context)
        guard let cached = insightsCache[cacheKey] else { return false }
        return !cached.isExpired
    }

    // MARK: - Private Methods

    private func buildPrompt(from context: InsightsContext) -> String {
        // Format peak hours
        let peakHours = context.thoughtsByHour
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "Hour \($0.key): \($0.value) thoughts" }
            .joined(separator: ", ")

        // Format active days
        let activeDays = context.thoughtsByDay
            .sorted { $0.value > $1.value }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")

        // Format type distribution
        let types = context.typeDistribution
            .sorted { $0.value > $1.value }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")

        // Format top tags
        let tags = context.topTags
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")

        return """
        Analyze this thought capture data and generate personalized insights:

        SUMMARY:
        - Total thoughts: \(context.totalThoughts)
        - Average sentiment: \(String(format: "%.2f", context.averageSentiment)) (scale -1.0 to +1.0)
        - Current streak: \(context.currentStreak) days
        - Longest streak: \(context.longestStreak) days
        - Time period: \(context.dateRangeDescription)

        PATTERNS:
        - Top tags: \(tags)
        - Peak hours: \(peakHours)
        - Active days: \(activeDays)
        - Type distribution: \(types)

        HEALTH CORRELATIONS:
        - Sleep vs Sentiment: \(formatCorrelation(context.sleepCorrelation))
        - Steps vs Volume: \(formatCorrelation(context.stepsCorrelation))
        - HRV vs Sentiment: \(formatCorrelation(context.hrvCorrelation))
        - Workouts vs Volume: \(formatCorrelation(context.workoutCorrelation))
        - Resting HR vs Sentiment: \(formatCorrelation(context.restingHRCorrelation))

        TRENDS:
        - Sentiment trend: \(context.sentimentTrend)
        - Volume trend: \(context.volumeTrend)

        Generate insights with specific numbers from this data. Be conversational and empowering.
        """
    }

    private func formatCorrelation(_ correlation: Double?) -> String {
        guard let r = correlation else { return "N/A (insufficient data)" }
        let strength: String
        let direction = r > 0 ? "positive" : "negative"

        switch abs(r) {
        case 0.7...: strength = "strong"
        case 0.4..<0.7: strength = "moderate"
        case 0.2..<0.4: strength = "weak"
        default: strength = "no significant"
        }

        return "\(String(format: "%.2f", r)) (\(strength) \(direction) correlation)"
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func convertToGeneratedInsights(_ response: InsightsGenerationResponse) -> GeneratedInsights {
        return GeneratedInsights(
            patterns: response.patterns.map { item in
                InsightItem(
                    type: .pattern,
                    title: item.title,
                    description: item.description,
                    confidence: item.confidence,
                    icon: item.icon.isEmpty ? InsightType.pattern.defaultIcon : item.icon,
                    actionable: item.actionable
                )
            },
            recommendations: response.recommendations.map { item in
                InsightItem(
                    type: .recommendation,
                    title: item.title,
                    description: item.description,
                    confidence: item.confidence,
                    icon: item.icon.isEmpty ? InsightType.recommendation.defaultIcon : item.icon,
                    actionable: item.actionable
                )
            },
            achievements: response.achievements.map { item in
                InsightItem(
                    type: .achievement,
                    title: item.title,
                    description: item.description,
                    confidence: item.confidence,
                    icon: item.icon.isEmpty ? InsightType.achievement.defaultIcon : item.icon,
                    actionable: item.actionable
                )
            },
            anomalies: response.anomalies.map { item in
                InsightItem(
                    type: .anomaly,
                    title: item.title,
                    description: item.description,
                    confidence: item.confidence,
                    icon: item.icon.isEmpty ? InsightType.anomaly.defaultIcon : item.icon,
                    actionable: item.actionable
                )
            },
            summary: response.summary
        )
    }

    private func generateCacheKey(for context: InsightsContext) -> String {
        // Create a stable cache key from the context
        return "\(context.totalThoughts)-\(context.currentStreak)-\(context.dateRangeDescription)"
    }

    private func generateFallbackSummary(context: InsightsContext) -> String {
        if context.sentimentTrend == "improving" {
            return "Your mood is trending upward with \(context.totalThoughts) thoughts captured \(context.dateRangeDescription)."
        } else if context.currentStreak >= 7 {
            return "Great consistency! \(context.currentStreak)-day streak with \(context.totalThoughts) thoughts."
        } else {
            return "You captured \(context.totalThoughts) thoughts \(context.dateRangeDescription) with steady patterns."
        }
    }
}

// MARK: - Cache Data

private struct CachedInsights {
    let insights: GeneratedInsights
    let timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 1800  // 30 minutes
    }
}

// MARK: - Errors

enum InsightsGenerationError: LocalizedError {
    case notAvailable
    case insufficientData(required: Int, actual: Int)
    case generationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Intelligence is not available on this device"
        case .insufficientData(let required, let actual):
            return "Need at least \(required) thoughts for insights (currently have \(actual))"
        case .generationFailed(let error):
            return "Failed to generate insights: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Service

/// Mock service for testing and previews
@available(iOS 26.0, *)
actor MockInsightsGenerationService {

    func generateInsights(from context: InsightsContext) async throws -> GeneratedInsights {
        // Simulate network delay
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)

        return GeneratedInsights(
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
                )
            ],
            achievements: [
                InsightItem(
                    type: .achievement,
                    title: "7-Day Streak!",
                    description: "You've captured thoughts for 7 consecutive days. Consistency builds powerful habits.",
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
