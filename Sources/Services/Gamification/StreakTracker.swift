//
//  StreakTracker.swift
//  STASH
//
//  ADHD-first streak tracking for the gamification layer.
//
//  Design principles (from issue #38):
//  - One grace day per week — a single missed day doesn't break the streak
//  - Streak NEVER shows punishing/shaming imagery
//  - Lifetime stats (totalCaptureDays) never reset
//  - Milestone events fire acorn rewards + are available for squirrelsona reactions
//
//  This service maintains its own UserDefaults-backed state so streak info
//  is instantly available without querying CoreData. The ChartDataService
//  continues to compute streak history for the Insights visualization.
//

import Foundation
import Observation

// MARK: - Streak Milestone

/// A streak length that deserves a celebration moment.
enum StreakMilestone: Int, CaseIterable {
    case three   = 3
    case seven   = 7
    case fourteen = 14
    case thirty  = 30
    case sixty   = 60
    case hundred = 100

    static func from(_ days: Int) -> StreakMilestone? {
        StreakMilestone(rawValue: days)
    }
}

// MARK: - Streak Update

/// The result of recording a capture — consumed by the UI and AcornService.
struct StreakUpdate {
    /// The new streak length after this capture
    let newStreak: Int
    /// Whether the streak advanced (false = already captured today)
    let didAdvance: Bool
    /// A milestone just reached, if any
    let milestone: StreakMilestone?
    /// Grace day was consumed to preserve the streak
    let graceDayConsumed: Bool
}

// MARK: - Streak Tracker

/// Live, game-layer streak tracker with ADHD-first grace day logic.
///
/// The streak counter lives here, in UserDefaults, so it's available
/// instantly at app launch without hitting CoreData.
///
/// Grace day logic:
/// - Each week (Mon–Sun) the user gets one free missed day.
/// - If they miss a single day and haven't used their grace day this week,
///   the streak is preserved and the grace day is consumed.
/// - If they miss two consecutive days, the streak resets (gently).
@Observable
@MainActor
final class StreakTracker {
    static let shared = StreakTracker()

    // MARK: - Observable State

    private(set) var currentStreak: Int
    private(set) var longestStreak: Int
    private(set) var totalCaptureDays: Int

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let currentStreak      = "streak.current"
        static let longestStreak      = "streak.longest"
        static let totalCaptureDays   = "streak.totalDays"
        static let lastCaptureDate    = "streak.lastCaptureDate"
        static let graceDayWeek       = "streak.graceDayWeek"   // ISO week string when grace was used
        static let milestonesAwarded  = "streak.milestonesAwarded" // [Int] of milestone rawValues already fired
    }

    private let defaults = UserDefaults.standard

    // MARK: - Initialization

    private init() {
        currentStreak    = defaults.integer(forKey: Keys.currentStreak)
        longestStreak    = defaults.integer(forKey: Keys.longestStreak)
        totalCaptureDays = defaults.integer(forKey: Keys.totalCaptureDays)
    }

    // MARK: - Public API

    /// Call this immediately after a successful thought capture.
    ///
    /// Handles:
    /// - Advancing the streak if this is the first capture of the day
    /// - Grace day consumption if the user missed yesterday
    /// - Streak reset (gentle) if they missed 2+ days
    /// - Milestone detection
    ///
    /// - Returns: `StreakUpdate` with the new state for UI feedback
    @discardableResult
    func recordCapture() -> StreakUpdate {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        // Load last capture date
        let lastCapture = defaults.object(forKey: Keys.lastCaptureDate) as? Date
        let lastCaptureDay = lastCapture.map { calendar.startOfDay(for: $0) }

        // Already captured today — no streak change
        if let last = lastCaptureDay, last == today {
            return StreakUpdate(
                newStreak: currentStreak,
                didAdvance: false,
                milestone: nil,
                graceDayConsumed: false
            )
        }

        let daysSinceLast: Int
        if let last = lastCaptureDay {
            daysSinceLast = calendar.dateComponents([.day], from: last, to: today).day ?? 999
        } else {
            daysSinceLast = 999 // first ever capture
        }

        var graceDayConsumed = false
        var newStreak: Int

        switch daysSinceLast {
        case 1:
            // Consecutive day — advance normally
            newStreak = currentStreak + 1
        case 2:
            // Missed exactly one day — check grace day
            if canUseGraceDay(for: now) {
                consumeGraceDay(for: now)
                newStreak = currentStreak + 1
                graceDayConsumed = true
            } else {
                // Grace day used up this week — reset streak
                newStreak = 1
            }
        default:
            // Missed 2+ days — reset (gently; squirrel went foraging)
            newStreak = 1
        }

        // Update total capture days
        totalCaptureDays += 1
        defaults.set(totalCaptureDays, forKey: Keys.totalCaptureDays)

        // Update streak
        currentStreak = newStreak
        defaults.set(currentStreak, forKey: Keys.currentStreak)

        // Update longest
        if newStreak > longestStreak {
            longestStreak = newStreak
            defaults.set(longestStreak, forKey: Keys.longestStreak)
        }

        // Update last capture date
        defaults.set(now, forKey: Keys.lastCaptureDate)

        // Check for milestone
        let milestone = checkMilestone(newStreak: newStreak)

        return StreakUpdate(
            newStreak: newStreak,
            didAdvance: true,
            milestone: milestone,
            graceDayConsumed: graceDayConsumed
        )
    }

    // MARK: - Computed Properties

    /// How many days since the user last captured (nil if never)
    var daysSinceLastCapture: Int? {
        guard let last = defaults.object(forKey: Keys.lastCaptureDate) as? Date else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: last)
        return calendar.dateComponents([.day], from: lastDay, to: today).day
    }

    /// True if the user captured at least once today
    var capturedToday: Bool {
        guard let last = defaults.object(forKey: Keys.lastCaptureDate) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Grace Day

    private func canUseGraceDay(for date: Date) -> Bool {
        let weekString = isoWeekString(for: date)
        let usedWeek = defaults.string(forKey: Keys.graceDayWeek)
        return usedWeek != weekString
    }

    private func consumeGraceDay(for date: Date) {
        defaults.set(isoWeekString(for: date), forKey: Keys.graceDayWeek)
    }

    private func isoWeekString(for date: Date) -> String {
        let cal = Calendar(identifier: .iso8601)
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(components.yearForWeekOfYear ?? 0)-W\(components.weekOfYear ?? 0)"
    }

    // MARK: - Milestone Detection

    private func checkMilestone(newStreak: Int) -> StreakMilestone? {
        guard let milestone = StreakMilestone.from(newStreak) else { return nil }

        var awarded = (defaults.array(forKey: Keys.milestonesAwarded) as? [Int]) ?? []
        guard !awarded.contains(milestone.rawValue) else { return nil }

        awarded.append(milestone.rawValue)
        defaults.set(awarded, forKey: Keys.milestonesAwarded)
        return milestone
    }
}
