//
//  SmartInsightsService.swift
//  STASH
//
//  Smart thought resurfacing and pattern detection.
//  Prevents notes from disappearing into the void by proactively surfacing related content.
//

import Foundation

/// Pattern detected across multiple thoughts
 struct ThoughtPattern: Identifiable {
     let id = UUID()
     let theme: String
     let thoughts: [Thought]
     let frequency: Int
     let firstSeen: Date
     let lastSeen: Date

     init(theme: String, thoughts: [Thought], frequency: Int, firstSeen: Date, lastSeen: Date) {
        self.theme = theme
        self.thoughts = thoughts
        self.frequency = frequency
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
    }

    /// Time span of this pattern
     var timeSpan: TimeInterval {
        lastSeen.timeIntervalSince(firstSeen)
    }

    /// Days this pattern has been occurring
     var daySpan: Int {
        Int(timeSpan / (24 * 60 * 60))
    }

    /// Whether this is a recent pattern (last 7 days)
     var isRecent: Bool {
        lastSeen.timeIntervalSinceNow > -7 * 24 * 60 * 60
    }

    /// Whether this is a long-term pattern (>30 days)
     var isLongTerm: Bool {
        daySpan > 30
    }
}

/// Insight about a single thought's context
 struct ThoughtInsight {
     let thought: Thought
     let relatedThoughts: [SearchResult]
     let possibleDuplicates: [SearchResult]
     let patterns: [ThoughtPattern]

     init(thought: Thought, relatedThoughts: [SearchResult], possibleDuplicates: [SearchResult], patterns: [ThoughtPattern]) {
        self.thought = thought
        self.relatedThoughts = relatedThoughts
        self.possibleDuplicates = possibleDuplicates
        self.patterns = patterns
    }

    /// Whether this thought has been mentioned before
     var hasRelated: Bool {
        !relatedThoughts.isEmpty
    }

    /// Whether this might be a duplicate
     var hasPossibleDuplicates: Bool {
        !possibleDuplicates.isEmpty
    }

    /// Whether this thought is part of a recurring pattern
     var isPartOfPattern: Bool {
        !patterns.isEmpty
    }
}

/// Service for surfacing related thoughts and detecting patterns
///
/// Solves the "notes graveyard" problem by:
/// - Finding related thoughts when viewing/capturing
/// - Detecting duplicate or similar notes
/// - Identifying recurring themes and patterns
/// - Surfacing unresolved ideas and questions
@MainActor
 final class SmartInsightsService {
     static let shared = SmartInsightsService()

    private let semanticSearch = SemanticSearchService.shared

    /// Threshold for considering thoughts as "related" (0.0-1.0)
    private let relatedThreshold: Double = 0.5

    /// Threshold for considering thoughts as "possible duplicates" (0.0-1.0)
    private let duplicateThreshold: Double = 0.75

    /// Minimum number of thoughts to consider it a "pattern"
    private let patternMinimumCount: Int = 3

     init() {}

    // MARK: - Related Thoughts

    /// Find thoughts related to the given thought
    ///
    /// - Parameters:
    ///   - thought: The thought to find relations for
    ///   - allThoughts: Complete list of thoughts to search
    ///   - limit: Maximum number of related thoughts to return
    /// - Returns: Related thoughts sorted by relevance
     func findRelatedThoughts(
        for thought: Thought,
        in allThoughts: [Thought],
        limit: Int = 5
    ) async -> [SearchResult] {
        // Don't compare thought to itself
        let otherThoughts = allThoughts.filter { $0.id != thought.id }

        // Use semantic search to find similar thoughts
        let results = await semanticSearch.search(
            query: thought.content,
            in: otherThoughts
        )

        // Filter to only "related" threshold and limit results
        return results
            .filter { $0.score >= relatedThreshold }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Duplicate Detection

    /// Find possible duplicates of the given thought
    ///
    /// Helps identify when you're writing the same note repeatedly.
    ///
    /// - Parameters:
    ///   - thought: The thought to check for duplicates
    ///   - allThoughts: Complete list of thoughts to search
    /// - Returns: Possible duplicates sorted by similarity
     func findPossibleDuplicates(
        for thought: Thought,
        in allThoughts: [Thought]
    ) async -> [SearchResult] {
        let otherThoughts = allThoughts.filter { $0.id != thought.id }

        let results = await semanticSearch.search(
            query: thought.content,
            in: otherThoughts
        )

        // Only return high-confidence matches as possible duplicates
        return results.filter { $0.score >= duplicateThreshold }
    }

    // MARK: - Pattern Detection

    /// Detect recurring patterns in thoughts
    ///
    /// Identifies themes/topics that appear multiple times,
    /// helping surface ideas you keep thinking about but never act on.
    ///
    /// - Parameter thoughts: All thoughts to analyze
    /// - Returns: Detected patterns sorted by frequency
     func detectPatterns(in thoughts: [Thought]) async -> [ThoughtPattern] {
        var patterns: [String: [Thought]] = [:]

        // Group thoughts by common themes using tags and classifications
        for thought in thoughts {
            // Use tags as themes
            for tag in thought.tags {
                patterns[tag.lowercased(), default: []].append(thought)
            }

            // Use classification type as a theme
            if let classification = thought.classification {
                let typeKey = "type:\(classification.type.rawValue)"
                patterns[typeKey, default: []].append(thought)
            }
        }

        // Convert to ThoughtPattern objects, filtering by minimum count
        let detectedPatterns = patterns.compactMap { (theme, thoughts) -> ThoughtPattern? in
            guard thoughts.count >= patternMinimumCount else { return nil }

            let sortedThoughts = thoughts.sorted { $0.createdAt < $1.createdAt }
            guard let firstSeen = sortedThoughts.first?.createdAt,
                  let lastSeen = sortedThoughts.last?.createdAt else {
                return nil
            }

            return ThoughtPattern(
                theme: theme,
                thoughts: sortedThoughts,
                frequency: thoughts.count,
                firstSeen: firstSeen,
                lastSeen: lastSeen
            )
        }

        // Sort by frequency (most common patterns first)
        return detectedPatterns.sorted { $0.frequency > $1.frequency }
    }

    // MARK: - Comprehensive Insights

    /// Get comprehensive insights for a thought
    ///
    /// Combines related thoughts, duplicate detection, and pattern analysis.
    ///
    /// - Parameters:
    ///   - thought: The thought to analyze
    ///   - allThoughts: Complete list of thoughts
    /// - Returns: Complete insight package
     func getInsights(
        for thought: Thought,
        in allThoughts: [Thought]
    ) async -> ThoughtInsight {
        async let related = findRelatedThoughts(for: thought, in: allThoughts)
        async let duplicates = findPossibleDuplicates(for: thought, in: allThoughts)
        async let allPatterns = detectPatterns(in: allThoughts)

        let (relatedThoughts, possibleDuplicates, detectedPatterns) = await (related, duplicates, allPatterns)

        // Filter patterns to only those containing this thought
        let relevantPatterns = detectedPatterns.filter { pattern in
            pattern.thoughts.contains { $0.id == thought.id }
        }

        return ThoughtInsight(
            thought: thought,
            relatedThoughts: relatedThoughts,
            possibleDuplicates: possibleDuplicates,
            patterns: relevantPatterns
        )
    }

    // MARK: - Unresolved Ideas

    /// Find thoughts that might be unresolved or need action
    ///
    /// Identifies:
    /// - Questions that were never answered
    /// - Ideas that were never developed
    /// - Tasks that were never created
    ///
    /// - Parameter thoughts: All thoughts to analyze
    /// - Returns: Thoughts that may need attention
     func findUnresolvedThoughts(in thoughts: [Thought]) -> [Thought] {
        thoughts.filter { thought in
            // Questions without answers (look for question marks, no related follow-ups)
            if thought.content.contains("?") {
                return true
            }

            // Ideas classified as "idea" but no related task created
            if let classification = thought.classification,
               classification.type == .idea,
               !thought.hasRelatedTask {
                return true
            }

            // Notes tagged with action words but no task
            let actionTags = ["todo", "action", "plan", "need", "should", "must"]
            if thought.tags.contains(where: { tag in
                actionTags.contains(tag.lowercased())
            }) && !thought.hasRelatedTask {
                return true
            }

            return false
        }
    }

    // MARK: - Summary Insights

    /// Generate a summary of patterns and insights across all thoughts
    ///
    /// - Parameter thoughts: All thoughts to analyze
    /// - Returns: Human-readable summary
     func generateSummary(for thoughts: [Thought]) async -> String {
        let patterns = await detectPatterns(in: thoughts)
        let unresolved = findUnresolvedThoughts(in: thoughts)

        var summary: [String] = []

        // Top patterns
        if !patterns.isEmpty {
            summary.append("📊 Recurring Themes:")
            for pattern in patterns.prefix(3) {
                let isRecent = pattern.isRecent ? "🔥 " : ""
                summary.append("  \(isRecent)\(pattern.theme): \(pattern.frequency) times over \(pattern.daySpan) days")
            }
        }

        // Unresolved items
        if !unresolved.isEmpty {
            summary.append("\n💡 Unresolved Ideas: \(unresolved.count)")
            let recentUnresolved = unresolved.filter {
                $0.createdAt.timeIntervalSinceNow > -30 * 24 * 60 * 60 // Last 30 days
            }
            if !recentUnresolved.isEmpty {
                summary.append("  (\(recentUnresolved.count) from the last month)")
            }
        }

        return summary.joined(separator: "\n")
    }
}

// MARK: - Thought Extension

private extension Thought {
    /// Whether this thought has a related task created
    var hasRelatedTask: Bool {
        // TODO: Check if thought has spawned a task
        // For now, return false - will implement when task linking is available
        false
    }
}
