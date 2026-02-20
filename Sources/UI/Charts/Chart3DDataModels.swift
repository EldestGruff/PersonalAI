//
//  Chart3DDataModels.swift
//  STASH
//
//  Issue #25: 3D Thought Visualizations - Data Models
//  Data structures for 3D chart visualizations with Swift Charts 3D
//

import Foundation

// MARK: - 3D Chart Metadata

/// Metadata describing what a 3D chart visualizes
struct Chart3DMetadata {
    let title: String
    let description: String
    let xAxisLabel: String
    let yAxisLabel: String
    let zAxisLabel: String
    let insights: [String]
    let interpretation: String

    /// Example interpretations for each chart type
    static let thoughtSpace = Chart3DMetadata(
        title: "Thought Space Explorer",
        description: "Visualizes when you capture thoughts and how you're feeling when you do it.",
        xAxisLabel: "Hour of Day",
        yAxisLabel: "Sentiment",
        zAxisLabel: "Energy Level",
        insights: [
            "Discover when you're most energetic AND positive",
            "Find energy/mood dead zones in your day",
            "See thought clustering by time and emotion"
        ],
        interpretation: "Each sphere represents a captured thought. Position shows time of day (left to right), sentiment (bottom to top), and energy level (back to front). Clusters reveal your peak states."
    )

    static let healthCorrelation = Chart3DMetadata(
        title: "Health Correlation Cube",
        description: "Reveals how sleep, heart rate variability, and mood interact.",
        xAxisLabel: "Sleep Hours",
        yAxisLabel: "HRV Score",
        zAxisLabel: "Sentiment",
        insights: [
            "Visualize the sleep-HRV-mood triangle",
            "Identify optimal sleep/recovery zones",
            "See how health metrics correlate with sentiment"
        ],
        interpretation: "Each point represents a day. High clustering in certain zones reveals your personal optimal health-mood combinations. Distance from origin shows overall wellness."
    )

    static let trendSurface = Chart3DMetadata(
        title: "Thought Volume Surface",
        description: "Shows thought capture patterns as a 3D landscape over time.",
        xAxisLabel: "Date",
        yAxisLabel: "Hour of Day",
        zAxisLabel: "Thought Count",
        insights: [
            "See volume trends as a 3D surface",
            "Identify peak productivity zones",
            "Spot seasonal patterns and habit changes"
        ],
        interpretation: "Height represents thought volume. Peaks show productive periods. The surface reveals your capture rhythms - daily, weekly, and monthly patterns emerge."
    )

    static let tagSemantic = Chart3DMetadata(
        title: "Tag Semantic Space",
        description: "Visualizes semantic relationships between your tags in 3D.",
        xAxisLabel: "Semantic Dimension 1",
        yAxisLabel: "Semantic Dimension 2",
        zAxisLabel: "Semantic Dimension 3",
        insights: [
            "Discover tag clusters (work, health, personal)",
            "Find surprising tag associations",
            "See conceptual relationships spatially"
        ],
        interpretation: "Tags closer together are semantically related. Clusters reveal thematic groups in your thinking. Distance shows conceptual differences."
    )
}

// MARK: - Thought Space 3D (Time × Sentiment × Energy)

/// Data point for 3D thought space visualization
struct ThoughtSpace3DPoint: Identifiable {
    let id = UUID()
    let thoughtId: UUID
    let hourOfDay: Double      // 0-23
    let sentiment: Double       // -1.0 to 1.0
    let energyLevel: Double     // 0.0 to 1.0
    let content: String         // For tooltip on interaction
    let date: Date

    /// Size of the sphere based on thought importance (could be length, tags, etc.)
    var sphereSize: Double {
        return 5.0 + (Double(content.count) / 50.0) // Base 5, scales with length
    }
}

// MARK: - Health Correlation 3D (Sleep × HRV × Sentiment)

/// Data point for health correlation cube
struct HealthCorrelation3DPoint: Identifiable {
    let id = UUID()
    let date: Date
    let sleepHours: Double      // 0-12 hours
    let hrvScore: Double        // 0-100 (normalized)
    let sentiment: Double       // -1.0 to 1.0
    let thoughtCount: Int       // Number of thoughts that day

    /// Color intensity based on overall wellness
    var wellnessScore: Double {
        // Normalize all metrics to 0-1, then average
        let sleepNorm = min(sleepHours / 9.0, 1.0)  // 9 hours = optimal
        let hrvNorm = hrvScore / 100.0
        let sentimentNorm = (sentiment + 1.0) / 2.0  // Map -1..1 to 0..1
        return (sleepNorm + hrvNorm + sentimentNorm) / 3.0
    }
}

// MARK: - Trend Surface 3D (Date × Hour → Volume)

/// Data point for trend surface plot
struct TrendSurface3DPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hourOfDay: Int          // 0-23
    let thoughtCount: Int       // Height of surface

    /// Normalized date for X axis (days since first thought)
    var dayIndex: Int {
        return Calendar.current.dateComponents([.day], from: .distantPast, to: date).day ?? 0
    }
}

/// Result containing grid of surface points
struct TrendSurface3DData {
    let points: [TrendSurface3DPoint]
    let dateRange: ClosedRange<Date>
    let maxCount: Int

    /// Grid dimensions for surface rendering
    var gridWidth: Int {
        Calendar.current.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 0
    }

    var gridHeight: Int {
        return 24  // Hours in a day
    }
}

// MARK: - Tag Semantic Space 3D

/// Data point for semantic tag visualization
struct TagSemantic3DPoint: Identifiable {
    let id = UUID()
    let tag: String
    let dimension1: Double      // PCA/t-SNE dimension 1
    let dimension2: Double      // PCA/t-SNE dimension 2
    let dimension3: Double      // PCA/t-SNE dimension 3
    let frequency: Int          // How often this tag is used
    let relatedTags: [String]   // For connection lines

    /// Sphere size based on tag frequency
    var sphereSize: Double {
        return 3.0 + log(Double(max(frequency, 1))) * 2.0
    }
}

// MARK: - 3D Chart Type Enum

/// Available 3D chart visualizations
enum Chart3DType: String, CaseIterable, Identifiable {
    case thoughtSpace = "thought_space"
    case healthCorrelation = "health_correlation"
    case trendSurface = "trend_surface"
    case tagSemantic = "tag_semantic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thoughtSpace: return "Thought Space"
        case .healthCorrelation: return "Health Cube"
        case .trendSurface: return "Volume Surface"
        case .tagSemantic: return "Tag Space"
        }
    }

    var icon: String {
        switch self {
        case .thoughtSpace: return "cube.fill"
        case .healthCorrelation: return "heart.fill"
        case .trendSurface: return "chart.line.uptrend.xyaxis"
        case .tagSemantic: return "tag.fill"
        }
    }

    var metadata: Chart3DMetadata {
        switch self {
        case .thoughtSpace: return .thoughtSpace
        case .healthCorrelation: return .healthCorrelation
        case .trendSurface: return .trendSurface
        case .tagSemantic: return .tagSemantic
        }
    }

    /// iOS 26+ availability check
    @available(iOS 26.0, *)
    var isAvailable: Bool {
        return true
    }
}
