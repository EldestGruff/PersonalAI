//
//  ChartDataModels.swift
//  PersonalAI
//
//  Issue #18: Swift Charts - Data Models
//  Chart data structures for insights and trends
//

import Foundation

// MARK: - Sentiment Trend Data

/// Data point for sentiment trend over time
struct SentimentDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let averageSentiment: Double  // Range: -1.0 (negative) to 1.0 (positive)
    let thoughtCount: Int

    /// Sentiment as a user-friendly string
    var sentimentLabel: String {
        switch averageSentiment {
        case 0.5...1.0: return "Very Positive"
        case 0.2..<0.5: return "Positive"
        case -0.2..<0.2: return "Neutral"
        case -0.5..<(-0.2): return "Negative"
        default: return "Very Negative"
        }
    }
}

// MARK: - Thought Type Distribution

/// Count of thoughts by type for pie/donut charts
struct ThoughtTypeCount: Identifiable {
    let id = UUID()
    let type: ThoughtType
    let count: Int
    let percentage: Double

    /// Display name for the type
    var label: String {
        type.displayName
    }

    /// Color for the type
    var color: String {
        type.colorHex
    }
}

// MARK: - Capture Frequency Heatmap

/// Capture count per day for heatmap visualization
struct CaptureHeatmapData {
    let date: Date
    let count: Int

    /// GitHub-style intensity level (0-4)
    var intensity: Int {
        switch count {
        case 0: return 0
        case 1...2: return 1
        case 3...5: return 2
        case 6...10: return 3
        default: return 4
        }
    }
}

// MARK: - Health Correlation

/// Health metric vs sentiment for scatter plots
struct HealthCorrelationPoint: Identifiable {
    let id = UUID()
    let date: Date
    let energyScore: Double  // 0.0 to 1.0
    let sentiment: Double    // -1.0 to 1.0
    let thoughtCount: Int
}

// MARK: - Tag Popularity

/// Tag usage frequency for bar charts
struct TagPopularity: Identifiable {
    let id = UUID()
    let tag: String
    let count: Int
    let percentage: Double
}

// MARK: - Date Range

/// Time range for filtering chart data
enum ChartDateRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case quarter = "90D"
    case year = "1Y"
    case all = "All"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        case .all: return "All Time"
        }
    }

    /// Calculate the start date for this range
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .quarter:
            return calendar.date(byAdding: .day, value: -90, to: now)
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .all:
            return nil  // No filter
        }
    }
}

// MARK: - Chart Summary Metrics

/// Summary statistics for insights overview
struct ChartSummaryMetrics {
    let totalThoughts: Int
    let averageSentiment: Double
    let mostCommonType: ThoughtType?
    let topTag: String?
    let currentStreak: Int  // Days with at least one thought
    let longestStreak: Int

    /// Formatted average sentiment
    var sentimentLabel: String {
        switch averageSentiment {
        case 0.5...1.0: return "Very Positive"
        case 0.2..<0.5: return "Positive"
        case -0.2..<0.2: return "Neutral"
        case -0.5..<(-0.2): return "Negative"
        default: return "Very Negative"
        }
    }
}

// MARK: - Capture Heatmap (Enhanced)

/// Complete heatmap data for time pattern analysis
struct CaptureHeatmapResult {
    let hourOfDayDistribution: [HourDataPoint]  // 0-23
    let dayOfWeekDistribution: [DayDataPoint]   // 1-7 (1=Sunday)
    let hourByDayMatrix: [[Int]]                 // 7x24 matrix for full heatmap
}

/// Data point for hour of day analysis
struct HourDataPoint: Identifiable {
    let id = UUID()
    let hour: Int           // 0-23
    let count: Int
    let averageSentiment: Double?
}

/// Data point for day of week analysis
struct DayDataPoint: Identifiable {
    let id = UUID()
    let dayOfWeek: Int      // 1=Sunday, 7=Saturday
    let count: Int
    let averageSentiment: Double?

    var dayName: String {
        let formatter = DateFormatter()
        formatter.weekdaySymbols = Calendar.current.shortWeekdaySymbols
        return formatter.weekdaySymbols[dayOfWeek - 1]
    }
}

// MARK: - Streak Data

/// Gamification data for capture consistency
struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysWithThoughts: Int
    let streakHistory: [StreakPeriod]
}

/// A continuous period of daily captures
struct StreakPeriod: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let length: Int
}

// MARK: - Confidence Trends

/// Classification confidence over time
struct ConfidenceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let averageConfidence: Double
    let thoughtCount: Int
    let byType: [ClassificationType: Double]

    var confidenceLabel: String {
        switch averageConfidence {
        case 0.8...1.0: return "Very High"
        case 0.6..<0.8: return "High"
        case 0.4..<0.6: return "Moderate"
        case 0.2..<0.4: return "Low"
        default: return "Very Low"
        }
    }
}

// MARK: - Health Correlation (Enhanced)

/// Complete health correlation data with coefficients
struct HealthCorrelationData {
    let sleepVsSentiment: [SleepSentimentPoint]
    let stepsVsVolume: [StepsVolumePoint]
    let correlationCoefficients: CorrelationSummary
}

/// Sleep hours vs mood correlation point
struct SleepSentimentPoint: Identifiable {
    let id = UUID()
    let date: Date
    let sleepHours: Double
    let sentiment: Double
}

/// Activity vs thought volume correlation point
struct StepsVolumePoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let thoughtCount: Int
}

/// Statistical correlation summary
struct CorrelationSummary {
    let sleepSentimentCorrelation: Double?  // Pearson correlation coefficient
    let stepsVolumeCorrelation: Double?
    let description: String                  // Human-readable insight

    var sleepStrength: String {
        guard let r = sleepSentimentCorrelation else { return "Unknown" }
        let abs = Swift.abs(r)
        switch abs {
        case 0.7...1.0: return "Strong"
        case 0.4..<0.7: return "Moderate"
        case 0.2..<0.4: return "Weak"
        default: return "Very Weak"
        }
    }

    var stepsStrength: String {
        guard let r = stepsVolumeCorrelation else { return "Unknown" }
        let abs = Swift.abs(r)
        switch abs {
        case 0.7...1.0: return "Strong"
        case 0.4..<0.7: return "Moderate"
        case 0.2..<0.4: return "Weak"
        default: return "Very Weak"
        }
    }
}

// MARK: - Helper Extensions

extension ThoughtType {
    /// Hex color for chart visualization
    var colorHex: String {
        switch self {
        case .note: return "#3B82F6"      // Blue
        case .idea: return "#8B5CF6"      // Purple
        case .reminder: return "#F59E0B"  // Amber
        case .event: return "#10B981"     // Green
        case .question: return "#EC4899"  // Pink
        }
    }
}
