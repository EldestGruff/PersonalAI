//
//  BadgeService.swift
//  STASH
//
//  Gamification issue #41: Discovery Badges
//
//  Checks badge criteria after each capture and persists earned state
//  in SyncedDefaults (iCloud KV Store) for cross-device sync.
//  Criteria are evaluated against the just-saved thought plus stats from
//  the other gamification services.
//
//  All checks are lightweight — no heavy computation, no ML inference.
//

import Foundation
import Observation

// MARK: - Badge Service

@Observable
@MainActor
final class BadgeService {
    static let shared = BadgeService()

    // MARK: - Observed State

    private(set) var earnedBadgeIds: Set<String> = []
    private(set) var earnedDates: [String: Date] = [:]
    /// Badges earned in the current session — used to trigger reveal animations.
    /// Not persisted; cleared when the Achievements screen is dismissed.
    private(set) var recentlyEarnedIds: Set<String> = []

    // MARK: - Keys

    private enum Keys {
        static let earnedIds   = "badge.earnedIds"
        static let earnedDates = "badge.earnedDates"
    }

    private let defaults = SyncedDefaults.shared

    // MARK: - Init

    private init() {
        let ids = defaults.stringArray(forKey: Keys.earnedIds) ?? []
        earnedBadgeIds = Set(ids)

        if let data = defaults.data(forKey: Keys.earnedDates),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            earnedDates = decoded
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange(_:)),
            name: .syncedDefaultsDidChangeExternally,
            object: nil
        )
    }

    // MARK: - Public API

    /// Returns true if the given badge has been earned.
    func isEarned(_ badgeId: String) -> Bool {
        earnedBadgeIds.contains(badgeId)
    }

    /// Runs all badge checks after a thought is captured.
    ///
    /// - Parameters:
    ///   - thought: The newly saved thought
    ///   - thoughtService: Used to fetch counts for volume/quality checks
    /// - Returns: Any badges newly earned during this call
    func checkAll(
        newThought thought: Thought,
        thoughtService: any ThoughtServiceProtocol
    ) async -> [BadgeDefinition] {
        var newlyEarned: [BadgeDefinition] = []

        // Fetch full thought list once for checks that need it
        let allThoughts = (try? await thoughtService.list(filter: nil)) ?? []

        for badge in BadgeDefinition.catalog {
            guard !isEarned(badge.id) else { continue }

            if qualifies(badge: badge, thought: thought, allThoughts: allThoughts) {
                await award(badge)
                newlyEarned.append(badge)
            }
        }

        return newlyEarned
    }

    // MARK: - Criteria Checks

    private func qualifies(
        badge: BadgeDefinition,
        thought: Thought,
        allThoughts: [Thought]
    ) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: thought.createdAt)
        let weekday = calendar.component(.weekday, from: thought.createdAt) // 1=Sun, 2=Mon

        switch badge.id {

        // ── Time-based ────────────────────────────────────────────────
        case "night_owl":
            return hour == 0 || hour == 1 || hour == 2 || hour == 3

        case "early_bird":
            return hour < 6

        case "monday":
            return weekday == 2 && hour < 9

        // ── Volume-based ──────────────────────────────────────────────
        case "deep_roots":
            return allThoughts.count >= 100

        case "hoarder":
            return allThoughts.count >= 500

        // ── Writing quality ───────────────────────────────────────────
        case "novelist":
            let longThoughts = allThoughts.filter { wordCount($0.content) > 200 }
            return longThoughts.count >= 3

        case "overthinker":
            return thought.content.count > 500

        // ── Speed / habit ─────────────────────────────────────────────
        case "fast_thinker":
            let tenMinutesAgo = thought.createdAt.addingTimeInterval(-600)
            let recentCount = allThoughts.filter { $0.createdAt >= tenMinutesAgo }.count
            return recentCount >= 5

        case "long_game":
            return StreakTracker.shared.currentStreak >= 30

        // ── Connection / emotion ──────────────────────────────────────
        case "connected":
            return thought.relatedThoughtIds.count >= 5

        case "feelings":
            let emotional = allThoughts.filter { t in
                guard let sentiment = t.classification?.sentiment else { return false }
                switch sentiment {
                case .positive, .negative, .very_positive, .very_negative: return true
                case .neutral: return false
                }
            }
            return emotional.count >= 10

        // ── Gamification milestones ───────────────────────────────────
        case "first_shiny":
            return allThoughts.contains { $0.isShiny }

        case "acorn_millionaire":
            return AcornLedger.shared.lifetimeEarned >= 1000

        // ── Secret ────────────────────────────────────────────────────
        case "secret_squirrel":
            return thought.content.lowercased().contains("secret squirrel")

        default:
            return false
        }
    }

    // MARK: - Awarding

    private func award(_ badge: BadgeDefinition) async {
        earnedBadgeIds.insert(badge.id)
        recentlyEarnedIds.insert(badge.id)
        AnalyticsService.shared.track(.badgeUnlocked(badgeId: badge.id))
        earnedDates[badge.id] = Date()

        defaults.set(Array(earnedBadgeIds), forKey: Keys.earnedIds)
        if let data = try? JSONEncoder().encode(earnedDates) {
            defaults.set(data, forKey: Keys.earnedDates)
        }

        // Fire acorn bonus
        _ = await AcornService.shared.processVariableReward(acorns: badge.acornBonus)
    }

    /// Call when the Achievements screen is dismissed to clear pending animations.
    func clearRecentlyEarned() {
        recentlyEarnedIds.removeAll()
    }

    // MARK: - Helpers

    private func wordCount(_ text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    // MARK: - External Change Handler

    @objc private func handleExternalChange(_ notification: Notification) {
        guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }

        if changedKeys.contains(Keys.earnedIds) {
            let remote = Set(defaults.stringArray(forKey: Keys.earnedIds) ?? [])
            let merged = earnedBadgeIds.union(remote)
            if merged != earnedBadgeIds {
                earnedBadgeIds = merged
                defaults.set(Array(merged), forKey: Keys.earnedIds)
            }
        }
        if changedKeys.contains(Keys.earnedDates) {
            if let data = defaults.data(forKey: Keys.earnedDates),
               let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
                // Merge: keep earliest date per badge (first time earned wins)
                for (badgeId, remoteDate) in decoded {
                    if let localDate = earnedDates[badgeId] {
                        earnedDates[badgeId] = min(localDate, remoteDate)
                    } else {
                        earnedDates[badgeId] = remoteDate
                    }
                }
                // Persist merged dates
                if let data = try? JSONEncoder().encode(earnedDates) {
                    defaults.set(data, forKey: Keys.earnedDates)
                }
            }
        }
    }
}
