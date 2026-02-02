//
//  SemanticSearchService.swift
//  PersonalAI
//
//  Semantic search using iOS 26 NLEmbedding for meaning-based search.
//  Searches by concept similarity rather than keyword matching.
//

import Foundation
import NaturalLanguage

/// Result from semantic search with relevance scoring
struct SearchResult: Identifiable {
    let id = UUID()
    let thought: Thought
    let score: Double

    /// Relevance as percentage (0-100)
    var relevancePercentage: Int {
        Int(score * 100)
    }

    /// Whether this is a high-confidence match
    var isHighConfidence: Bool {
        score > 0.6
    }
}

/// Semantic search service using NLEmbedding for contextual search
///
/// Enables "search by meaning" rather than keyword matching:
/// - Query "productivity" finds thoughts about "focus", "efficiency", "work"
/// - Query "feeling anxious" finds thoughts about "worried", "stressed", "nervous"
/// - Understands context and relationships between concepts
@MainActor
final class SemanticSearchService {
    static let shared = SemanticSearchService()

    /// NLEmbedding for generating contextual embeddings
    private let embedding: NLEmbedding?

    /// Minimum similarity threshold for results (0.0-1.0)
    private let relevanceThreshold: Double = 0.3

    /// Maximum number of results to return
    private let maxResults: Int = 20

    init() {
        // Initialize sentence embedding for English
        // NLEmbedding.sentenceEmbedding is the correct iOS 26 API
        embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }

    /// Perform semantic search on thoughts
    ///
    /// - Parameters:
    ///   - query: The search query
    ///   - thoughts: Array of thoughts to search
    /// - Returns: Array of search results sorted by relevance
    func search(query: String, in thoughts: [Thought]) async -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        // Check if embedding is available
        guard let embedding = embedding else {
            // Fallback to keyword search if embedding unavailable
            return keywordSearch(query: query, in: thoughts)
        }

        // Generate query vector
        guard let queryVector = try? embedding.vector(for: query) else {
            return keywordSearch(query: query, in: thoughts)
        }

        // Calculate similarity for each thought
        var results: [(thought: Thought, similarity: Double)] = []

        for thought in thoughts {
            let content = thought.content
            guard !content.isEmpty else { continue }

            // Generate thought vector
            if let thoughtVector = try? embedding.vector(for: content) {
                let similarity = cosineSimilarity(queryVector, thoughtVector)

                // Include if above threshold
                if similarity > relevanceThreshold {
                    results.append((thought, similarity))
                }
            }
        }

        // Sort by similarity (highest first) and limit results
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(maxResults)
            .map { SearchResult(thought: $0.thought, score: $0.similarity) }
    }

    /// Calculate cosine similarity between two vectors
    ///
    /// Cosine similarity measures the angle between vectors:
    /// - 1.0 = identical direction (very similar)
    /// - 0.0 = perpendicular (unrelated)
    /// - -1.0 = opposite direction (contradictory)
    ///
    /// - Parameters:
    ///   - a: First vector
    ///   - b: Second vector
    /// - Returns: Similarity score between -1.0 and 1.0
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }

        // Calculate dot product: sum of element-wise products
        let dotProduct = zip(a, b).map(*).reduce(0, +)

        // Calculate magnitudes (L2 norm)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        // Avoid division by zero
        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }

        // Cosine similarity = dot product / (magnitude A * magnitude B)
        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Fallback keyword search when semantic search unavailable
    ///
    /// Simple case-insensitive substring matching.
    /// Returns all matching thoughts with score of 1.0.
    ///
    /// - Parameters:
    ///   - query: The search query
    ///   - thoughts: Array of thoughts to search
    /// - Returns: Array of matching search results
    private func keywordSearch(query: String, in thoughts: [Thought]) -> [SearchResult] {
        thoughts
            .filter { thought in
                thought.content.localizedCaseInsensitiveContains(query)
            }
            .map { SearchResult(thought: $0, score: 1.0) }
    }

    /// Check if semantic search is available
    var isAvailable: Bool {
        embedding != nil
    }

    /// Get description of search mode for UI display
    var searchMode: String {
        isAvailable ? "Semantic Search" : "Keyword Search"
    }
}
