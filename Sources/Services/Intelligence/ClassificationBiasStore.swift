//
//  ClassificationBiasStore.swift
//  STASH
//
//  Local bias layer on top of CoreData fine-tuning data (Issue #48 Option A).
//  Records negative feedback signals per content pattern and applies them
//  during heuristic classification to avoid repeated misclassifications.
//
//  Compatible with future Option B (model fine-tuning): this store is
//  independent of FineTuningData CoreData records and can be retired when
//  a trained model replaces the heuristic path.
//

import Foundation

// MARK: - Classification Correction

struct ClassificationCorrection: Codable {
    /// First 5 words of thought content, lowercased — used as the pattern key.
    let pattern: String

    /// The `ClassificationType.rawValue` that was wrong for this pattern.
    let penalizedType: String

    /// The `ClassificationType.rawValue` the user explicitly corrected to, if known.
    var preferredType: String?

    /// Increases with repeated negative feedback; decreases with positive feedback.
    var weight: Double

    let createdAt: Date
}

// MARK: - Classification Bias Store

/// Lightweight `UserDefaults`-backed store that records classification correction signals.
///
/// ## How it works
/// - 👎 feedback increments the penalty weight for a (pattern, type) pair.
/// - Explicit type edits additionally record the `preferredType`.
/// - 👍 feedback decrements weight; entry is removed when weight reaches zero.
/// - `ClassificationService.classifyType` checks this store before returning
///   a type and skips penalized types (weight ≥ 2.0).
///
/// ## Maintenance
/// - Capped at 200 entries; oldest are evicted when over limit.
/// - Entries older than 90 days are pruned on every write.
// @unchecked Sendable: all state stored in UserDefaults (thread-safe).
// Mutation is infrequent (user correction events) and serialized through
// UserDefaults' internal locking. No in-memory mutable state.
final class ClassificationBiasStore: @unchecked Sendable {
    static let shared = ClassificationBiasStore()

    private let userDefaultsKey = "classificationBiasCorrections"
    private let maxEntries = 200
    private let decayDays: Double = 90

    /// Minimum weight before a penalty is applied during classification.
    let applyThreshold: Double = 2.0

    private init() {}

    // MARK: - Pattern Extraction

    /// Extracts a stable pattern key from thought content (first 5 words, lowercased).
    static func extractPattern(from content: String) -> String {
        content.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(5)
            .joined(separator: " ")
    }

    // MARK: - Queries

    /// Returns the accumulated penalty weight for a given pattern + type pair.
    func penaltyWeight(for pattern: String, type: String) -> Double {
        load().first { $0.pattern == pattern && $0.penalizedType == type }?.weight ?? 0.0
    }

    /// Returns the user-confirmed preferred type for a pattern, if one has been recorded.
    func preferredType(for pattern: String, penalizedType: String) -> String? {
        load().first { $0.pattern == pattern && $0.penalizedType == penalizedType }?.preferredType
    }

    /// Returns the correction entry for a given pattern + type pair in a single UserDefaults read.
    /// Prefer this over calling penaltyWeight and preferredType separately.
    func correction(for pattern: String, type penalizedType: String) -> ClassificationCorrection? {
        load().first { $0.pattern == pattern && $0.penalizedType == penalizedType }
    }

    // MARK: - Recording Signals

    /// Records a negative feedback signal for the given pattern + type.
    ///
    /// Call when the user gives 👎 feedback, or when a type edit is saved.
    /// Pass `preferredType` when the user has explicitly selected the correct type.
    func record(pattern: String, penalizedType: String, preferredType: String? = nil) {
        var corrections = load()

        if let index = corrections.firstIndex(where: {
            $0.pattern == pattern && $0.penalizedType == penalizedType
        }) {
            corrections[index].weight += 1.0
            if let preferred = preferredType {
                corrections[index].preferredType = preferred
            }
        } else {
            corrections.append(ClassificationCorrection(
                pattern: pattern,
                penalizedType: penalizedType,
                preferredType: preferredType,
                weight: 1.0,
                createdAt: Date()
            ))
        }

        save(corrections)
        trim()
    }

    /// Reduces the penalty weight for a pattern + type pair (positive feedback signal).
    ///
    /// Call when the user gives 👍 feedback on a thought. Removes the entry when
    /// weight reaches zero.
    func reinforce(pattern: String, penalizedType: String) {
        var corrections = load()

        guard let index = corrections.firstIndex(where: {
            $0.pattern == pattern && $0.penalizedType == penalizedType
        }) else { return }

        corrections[index].weight = max(0, corrections[index].weight - 0.5)
        if corrections[index].weight <= 0 {
            corrections.remove(at: index)
        }

        save(corrections)
    }

    // MARK: - Maintenance

    private func trim() {
        var corrections = load()
        let cutoff = Date().addingTimeInterval(-decayDays * 86400)

        corrections.removeAll { $0.createdAt < cutoff }

        if corrections.count > maxEntries {
            corrections = Array(
                corrections.sorted { $0.createdAt > $1.createdAt }.prefix(maxEntries)
            )
        }

        save(corrections)
    }

    // MARK: - Persistence

    private func load() -> [ClassificationCorrection] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let corrections = try? JSONDecoder().decode([ClassificationCorrection].self, from: data)
        else { return [] }
        return corrections
    }

    private func save(_ corrections: [ClassificationCorrection]) {
        guard let data = try? JSONEncoder().encode(corrections) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
