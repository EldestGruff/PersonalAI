//
//  SemanticSearchService.swift
//  STASH
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

/// Semantic search service using NLEmbedding for contextual search.
///
/// Enables "search by meaning" rather than keyword matching:
/// - Query "productivity" finds thoughts about "focus", "efficiency", "work"
/// - Query "feeling anxious" finds thoughts about "worried", "stressed", "nervous"
///
/// ## Performance
///
/// NLEmbedding vector generation is CPU-intensive. Running as an `actor` (rather
/// than `@MainActor`) ensures embedding work executes off the main thread.
/// A `vectorCache` keyed by thought ID avoids re-computing embeddings for the
/// same thought content across consecutive searches.
actor SemanticSearchService {
    static let shared = SemanticSearchService()

    /// NLEmbedding for generating contextual embeddings
    private let embedding: NLEmbedding?

    /// Whether semantic embedding is available on this device.
    ///
    /// Stored as `nonisolated let` so callers can read it synchronously
    /// without hopping onto the actor (e.g. from a `@MainActor` ViewModel).
    nonisolated let isAvailable: Bool

    /// Minimum similarity threshold for results (0.0–1.0)
    private let relevanceThreshold: Double = 0.2

    /// Maximum number of results to return
    private let maxResults: Int = 20

    /// Cached embedding vectors keyed by thought ID.
    ///
    /// Invalidated selectively when a thought is updated or deleted
    /// (see `invalidateCache(for:)`). Cleared entirely on memory pressure.
    private var vectorCache: [UUID: [Double]] = [:]

    init() {
        let emb = NLEmbedding.sentenceEmbedding(for: .english)
        embedding = emb
        isAvailable = emb != nil
    }

    /// Perform semantic search on a collection of thoughts.
    ///
    /// - Parameters:
    ///   - query: The search query
    ///   - thoughts: Array of thoughts to search
    /// - Returns: Array of search results sorted by relevance, descending
    func search(query: String, in thoughts: [Thought]) -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        guard let embedding else {
            return keywordSearch(query: query, in: thoughts)
        }

        guard let queryVector = embedding.vector(for: query) else {
            return keywordSearch(query: query, in: thoughts)
        }

        var results: [(thought: Thought, similarity: Double)] = []

        for thought in thoughts {
            guard !thought.content.isEmpty else { continue }

            let thoughtVector = cachedVector(for: thought, embedding: embedding)

            guard let thoughtVector else { continue }

            let similarity = cosineSimilarity(queryVector, thoughtVector)
            if similarity > relevanceThreshold {
                results.append((thought, similarity))
            }
        }

        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(maxResults)
            .map { SearchResult(thought: $0.thought, score: $0.similarity) }
    }

    /// Removes the cached vector for a specific thought.
    ///
    /// Call this after a thought's content or tags are updated so the stale
    /// vector is recomputed on the next search.
    func invalidateCache(for thoughtId: UUID) {
        vectorCache.removeValue(forKey: thoughtId)
    }

    /// Clears the entire vector cache (e.g. on memory pressure).
    func clearCache() {
        vectorCache.removeAll()
    }

    /// Get description of search mode for UI display.
    func searchModeName() -> String {
        embedding != nil ? "Semantic Search" : "Keyword Search"
    }

    // MARK: - Private Helpers

    /// Returns a cached embedding vector for the thought, computing and caching it if needed.
    private func cachedVector(for thought: Thought, embedding: NLEmbedding) -> [Double]? {
        if let cached = vectorCache[thought.id] {
            return cached
        }

        let tagText = thought.tags.isEmpty ? "" : " \(thought.tags.joined(separator: " "))"
        let searchableText = thought.content + tagText

        guard let vector = embedding.vector(for: searchableText) else { return nil }

        vectorCache[thought.id] = vector
        return vector
    }

    /// Calculates cosine similarity between two equal-length vectors.
    ///
    /// - Returns: Value in [-1, 1]. 1 = identical direction, 0 = orthogonal.
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Fallback keyword search when semantic search is unavailable.
    ///
    /// Scores thoughts by fraction of query tokens that appear in content or tags.
    private func keywordSearch(query: String, in thoughts: [Thought]) -> [SearchResult] {
        let stopWords: Set<String> = [
            "a", "an", "the", "is", "in", "on", "at", "to", "for", "of", "and", "or", "my", "i"
        ]
        let tokens = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 1 && !stopWords.contains($0) }

        guard !tokens.isEmpty else { return [] }

        return thoughts.compactMap { thought in
            let searchableText = (thought.content + " " + thought.tags.joined(separator: " ")).lowercased()
            let matchCount = tokens.filter { searchableText.contains($0) }.count
            guard matchCount > 0 else { return nil }
            let score = Double(matchCount) / Double(tokens.count)
            return SearchResult(thought: thought, score: score)
        }
        .sorted { $0.score > $1.score }
    }
}
