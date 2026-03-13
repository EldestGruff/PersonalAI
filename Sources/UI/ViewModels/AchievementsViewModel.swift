//
//  AchievementsViewModel.swift
//  STASH
//
//  Gamification issue #41-adjacent: Achievements & Stats screen.
//  Evaluates all achievement criteria against live service data.
//

import Foundation
import Observation

// MARK: - Achievement Category

enum AchievementCategory: String, CaseIterable {
    case streaks  = "Streaks"
    case acorns   = "Acorns"
    case captures = "Captures"
    case shinies  = "Shinies"

    var icon: String {
        switch self {
        case .streaks:  return "flame.fill"
        case .acorns:   return "🌰"
        case .captures: return "brain.head.profile"
        case .shinies:  return "sparkles"
        }
    }
}

// MARK: - Achievement

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String          // SF Symbol name
    let category: AchievementCategory
    let isEarned: Bool
    /// Human-readable threshold label shown on locked achievements, e.g. "7-day streak"
    let goalLabel: String
}

// MARK: - Achievements ViewModel

@Observable
@MainActor
final class AchievementsViewModel {

    // MARK: - Stats

    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var totalCaptureDays: Int = 0
    private(set) var currentAcorns: Int = 0
    private(set) var lifetimeAcorns: Int = 0
    private(set) var shinyCount: Int = 0
    private(set) var thoughtCount: Int = 0
    var luckyCaptures: Int { VariableRewardService.shared.lifetimeCount }

    // MARK: - Achievements

    private(set) var achievements: [Achievement] = []

    // MARK: - Badges

    private(set) var badges: [BadgeDefinition] = BadgeDefinition.catalog
    var earnedBadgeCount: Int { BadgeService.shared.earnedBadgeIds.count }

    // MARK: - State

    var isLoading: Bool = false
    var error: AppError?

    // MARK: - Services

    let thoughtService: ThoughtService

    // MARK: - Init

    init(thoughtService: ThoughtService) {
        self.thoughtService = thoughtService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        // Pull from lightweight UserDefaults-backed services first (synchronous)
        let streak = StreakTracker.shared
        let ledger = AcornLedger.shared

        currentStreak    = streak.currentStreak
        longestStreak    = streak.longestStreak
        totalCaptureDays = streak.totalCaptureDays
        currentAcorns    = await ledger.currentBalance
        lifetimeAcorns   = ledger.lifetimeEarned

        // Pull thought + shiny counts from CoreData
        do {
            let allThoughts = try await thoughtService.list(filter: nil)
            thoughtCount = allThoughts.count
            shinyCount   = allThoughts.filter { $0.isShiny }.count

            // Reconcile all streak stats against the authoritative thought history.
            StreakTracker.shared.reconcile(from: allThoughts.map { $0.createdAt })

            currentStreak    = StreakTracker.shared.currentStreak
            longestStreak    = StreakTracker.shared.longestStreak
            totalCaptureDays = StreakTracker.shared.totalCaptureDays
        } catch {
            self.error = AppError.from(error)
        }

        achievements = buildAchievements()
        isLoading = false
    }

    // MARK: - Achievement Builder

    private func buildAchievements() -> [Achievement] {
        let awardedMilestones = (UserDefaults.standard.array(
            forKey: AppStorageKeys.Gamification.streakMilestonesAwarded
        ) as? [Int]) ?? []

        var list: [Achievement] = []

        // ── Streak achievements ───────────────────────────────────────
        let streakDefs: [(days: Int, title: String, icon: String)] = [
            (3,   "First Steps",         "flame"),
            (7,   "One Week Wonder",     "flame.fill"),
            (14,  "Two Week Habit",      "star.fill"),
            (30,  "Month Master",        "trophy"),
            (60,  "Two Month Champion",  "trophy.fill"),
            (100, "Century Club",        "crown.fill"),
        ]
        for def in streakDefs {
            list.append(Achievement(
                id: "streak_\(def.days)",
                title: def.title,
                description: "Reach a \(def.days)-day capture streak",
                icon: def.icon,
                category: .streaks,
                isEarned: awardedMilestones.contains(def.days),
                goalLabel: "\(def.days)-day streak"
            ))
        }

        // ── Acorn achievements ────────────────────────────────────────
        let acornDefs: [(threshold: Int, title: String, icon: String)] = [
            (100,   "Small Stash",        "bag"),
            (350,   "Growing Hoard",      "bag.fill"),
            (1000,  "Big Stash",          "archivebox"),
            (3000,  "Overflowing Stash",  "archivebox.fill"),
            (10000, "Legendary Hoard",    "crown.fill"),
        ]
        for def in acornDefs {
            list.append(Achievement(
                id: "acorns_\(def.threshold)",
                title: def.title,
                description: "Earn \(def.threshold) lifetime acorns",
                icon: def.icon,
                category: .acorns,
                isEarned: lifetimeAcorns >= def.threshold,
                goalLabel: "\(def.threshold) acorns lifetime"
            ))
        }

        // ── Capture achievements ──────────────────────────────────────
        let captureDefs: [(threshold: Int, title: String, icon: String)] = [
            (1,   "First Thought",       "brain.head.profile"),
            (10,  "Getting Started",     "text.bubble"),
            (50,  "On a Roll",           "list.bullet"),
            (100, "Century of Thoughts", "books.vertical"),
            (500, "Five Hundred Strong", "books.vertical.fill"),
        ]
        for def in captureDefs {
            list.append(Achievement(
                id: "captures_\(def.threshold)",
                title: def.title,
                description: "Capture \(def.threshold) thought\(def.threshold == 1 ? "" : "s")",
                icon: def.icon,
                category: .captures,
                isEarned: thoughtCount >= def.threshold,
                goalLabel: "\(def.threshold) thought\(def.threshold == 1 ? "" : "s")"
            ))
        }

        // ── Shiny achievements ────────────────────────────────────────
        list.append(Achievement(
            id: "shiny_1",
            title: "First Shiny",
            description: "Have a thought promoted to shiny status",
            icon: "sparkle",
            category: .shinies,
            isEarned: shinyCount >= 1,
            goalLabel: "1 shiny thought"
        ))
        list.append(Achievement(
            id: "shiny_3",
            title: "Shiny Collection",
            description: "Build a pool of 3 shiny thoughts",
            icon: "sparkles",
            category: .shinies,
            isEarned: shinyCount >= 3,
            goalLabel: "3 shiny thoughts"
        ))

        return list
    }

    // MARK: - Private Helpers

    // MARK: - Computed

    var earnedCount: Int  { achievements.filter(\.isEarned).count }
    var totalCount:  Int  { achievements.count }

    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }
}
