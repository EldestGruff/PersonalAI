//
//  ShinyService.swift
//  STASH
//
//  Shinies Mechanic — issue #40
//
//  Surfaces the user's best thoughts as "shinies." Scoring uses on-device
//  signals only (no server, no ML inference beyond what's already stored).
//  A thought can become a shiny exactly once (shinies are permanent).
//  Promotion runs at most once per day.
//
//  Pool cap scales with library size: max(3, floor(totalThoughts × 7%))
//  — starts at 3, grows naturally as the user captures more thoughts.
//  Threshold: 2.0 primary; falls back to 1.5 if nothing clears 2.0,
//  ensuring great-but-not-quite thoughts aren't permanently overlooked.
//
//  Tagline: "STASH found a new shiny! ✨"
//

import Foundation

// MARK: - Shiny Score

private struct ShinyScore {
    let thought: Thought
    let score: Double
}

// MARK: - Shiny Service

/// Evaluates thoughts for "shiny" status and manages the active shiny pool.
///
/// Call `promoteShiniesIfNeeded(from:thoughtService:)` on app foreground or
/// after a batch of captures. It's safe to call repeatedly — it throttles
/// itself to once per calendar day.
actor ShinyService {
    static let shared = ShinyService()

    private enum Keys {
        static let lastPromotionDate = "shiny.lastPromotionDate"
    }

    private init() {}

    // MARK: - Public API

    /// Returns the current shiny pool from a thought list.
    /// Useful for driving "Today's Shiny" UI without a CoreData fetch.
    nonisolated func currentShinies(from thoughts: [Thought]) -> [Thought] {
        thoughts.filter(\.isShiny)
    }

    /// Scores and promotes thoughts to shiny status if it hasn't run today.
    /// Returns the IDs of newly promoted thoughts.
    ///
    /// Pool cap scales with library size: `max(3, floor(totalThoughts × 7%))`.
    /// Shinies are permanent — the cap only gates new promotions.
    ///
    /// Threshold rules (applied in order):
    ///   1. Primary: score ≥ 2.0
    ///   2. Fallback: score ≥ 1.5 (used only when nothing clears 2.0)
    ///
    /// - Parameters:
    ///   - thoughts: Full active thought list
    ///   - thoughtService: Used to persist the `isShiny = true` update
    /// - Returns: IDs of newly promoted shinies (empty if throttled or no candidates)
    func promoteShiniesIfNeeded(
        from thoughts: [Thought],
        thoughtService: ThoughtService
    ) async -> [UUID] {
        guard shouldRunToday() else { return [] }

        let existing = thoughts.filter(\.isShiny)

        // Dynamic pool cap: ~7% of total thoughts, minimum 3
        let poolCap = max(3, Int(Double(thoughts.count) * 0.07))
        let available = max(0, poolCap - existing.count)
        guard available > 0 else { return [] }

        let candidates = thoughts.filter { !$0.isShiny && $0.status == .active }
        let allScored = candidates
            .map { ShinyScore(thought: $0, score: score($0)) }
            .sorted { $0.score > $1.score }

        // Try primary threshold (2.0), fall back to 1.5 if nothing qualifies
        var toPromote = allScored.filter { $0.score >= 2.0 }.prefix(available)
        if toPromote.isEmpty {
            toPromote = allScored.filter { $0.score >= 1.5 }.prefix(available)
        }

        guard !toPromote.isEmpty else { return [] }

        // Persist
        var promoted: [UUID] = []
        for entry in toPromote {
            var updated = entry.thought
            updated.isShiny = true
            if (try? await thoughtService.update(updated)) != nil {
                promoted.append(updated.id)
            }
        }

        if !promoted.isEmpty {
            UserDefaults.standard.set(Date(), forKey: Keys.lastPromotionDate)
        }

        return promoted
    }

    // MARK: - Scoring

    /// Scores a thought on a 0–10 scale using available on-device signals.
    nonisolated func score(_ thought: Thought) -> Double {
        var score: Double = 0

        // Sentiment intensity (very positive OR very negative = high signal)
        if let sentiment = thought.classification?.sentiment {
            switch sentiment {
            case .very_positive, .very_negative: score += 3.0
            case .positive, .negative:           score += 1.5
            case .neutral:                       break
            }
        }

        // Spawned a task — thought was actionable enough to act on
        if thought.taskId != nil { score += 2.5 }

        // Connectivity — many related thoughts means it resonates
        switch thought.relatedThoughtIds.count {
        case 5...: score += 2.0
        case 3...4: score += 1.0
        case 1...2: score += 0.5
        default: break
        }

        // High-energy capture context
        if thought.context.energy == .high {
            score += 1.0
        }

        // Nostalgia signal — thought is older than 7 days (a gem from the past)
        let age = Date().timeIntervalSince(thought.createdAt)
        if age > 7 * 86400 { score += 1.0 }

        // Length signal — longer thoughts represent more investment
        if thought.content.count > 200 { score += 0.5 }

        return score
    }

    // MARK: - Throttle

    private func shouldRunToday() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: Keys.lastPromotionDate) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(last)
    }
}
