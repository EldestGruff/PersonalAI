//
//  AcornService.swift
//  STASH
//
//  Acorn Economy — the currency layer of STASH's gamification system.
//
//  Acorns are earned passively through capturing thoughts. They are never
//  purchasable with real money and are spent exclusively on cosmetics
//  (squirrelsona accessories, themes).
//
//  Phase 3B: Migrated to NSUbiquitousKeyValueStore for cross-device sync.
//  - lifetimeEarned syncs via SyncedDefaults (KV Store)
//  - spend events persist as AcornSpendRecord in CloudKit (CoreData)
//  - currentBalance is derived: lifetimeEarned - sum(AcornSpendRecords)
//  - No stored currentBalance — prevents spend-race conflicts across devices
//

import Foundation
import CoreData
import Observation

// MARK: - Earning Events

/// A reason acorns were awarded. Each case carries its acorn value.
enum AcornEarningEvent {
    /// Standard thought capture (+1)
    case capture
    /// First capture of the calendar day (+2, stacks with capture)
    case firstCaptureOfDay
    /// Capture included auto-populated context (+1 bonus)
    case contextualCapture
    /// Streak milestone reached (+5 to +25 depending on milestone)
    case streakMilestone(days: Int)
    /// Variable reward surprise — wired by VariableRewardService later
    case variableReward(acorns: Int)

    var acorns: Int {
        switch self {
        case .capture:             return 1
        case .firstCaptureOfDay:   return 2
        case .contextualCapture:   return 1
        case .streakMilestone(let days):
            switch days {
            case 3:    return 5
            case 7:    return 10
            case 14:   return 15
            case 30:   return 20
            default:   return 25
            }
        case .variableReward(let acorns): return acorns
        }
    }
}

// MARK: - Acorn Ledger

/// Persistent, observable ledger for the user's acorn balance.
///
/// `lifetimeEarned` is the all-time acorn total — it never decreases
/// and syncs via iCloud KV Store. `currentBalance` is derived at runtime:
/// lifetimeEarned minus the sum of all AcornSpendRecords in CloudKit.
/// This prevents spend-race conflicts across devices.
@Observable
@MainActor
final class AcornLedger {
    static let shared = AcornLedger()

    // MARK: Observed Properties

    private(set) var lifetimeEarned: Int

    // MARK: Keys

    private enum Keys {
        static let lifetimeEarned  = "acorn.lifetimeEarned"
        static let lastCaptureDate = "acorn.lastCaptureDate"
    }

    private let defaults = SyncedDefaults.shared
    private let context: NSManagedObjectContext

    private init() {
        lifetimeEarned = SyncedDefaults.shared.integer(forKey: Keys.lifetimeEarned)
        context = PersistenceController.shared.container.viewContext

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange(_:)),
            name: .syncedDefaultsDidChangeExternally,
            object: nil
        )
    }

    // MARK: - Derived Balance

    /// Current spendable balance, derived by subtracting all spend records from lifetime earned.
    var currentBalance: Int {
        get async {
            let spent = fetchTotalSpent()
            return max(0, lifetimeEarned - spent)
        }
    }

    /// Sums all AcornSpendRecord amounts. Safe on main thread using the viewContext.
    private func fetchTotalSpent() -> Int {
        let request = AcornSpendRecord.fetchRequest()
        let records = (try? context.fetch(request)) ?? []
        return records.reduce(0) { $0 + Int($1.amount) }
    }

    // MARK: Internal Mutations

    fileprivate func award(_ amount: Int) {
        lifetimeEarned += amount
        defaults.set(lifetimeEarned, forKey: Keys.lifetimeEarned)
        AnalyticsService.shared.track(.acornEarned(amount: amount))
    }

    /// Deducts acorns by writing an append-only AcornSpendRecord to CoreData.
    /// Returns false if the balance is insufficient.
    @discardableResult
    func spend(_ amount: Int) async -> Bool {
        let balance = await currentBalance
        guard balance >= amount else { return false }

        let record = AcornSpendRecord(context: context)
        record.id = UUID()
        record.amount = Int32(amount)
        record.reason = "manual"
        record.createdAt = Date()
        try? context.save()

        AnalyticsService.shared.track(.acornSpent(amount: amount))
        return true
    }

    // MARK: Last Capture Date (used by AcornService for first-of-day bonus)

    var lastCaptureDate: Date? {
        get { defaults.object(forKey: Keys.lastCaptureDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastCaptureDate) }
    }

    // MARK: - External Change Handler

    @objc private func handleExternalChange(_ notification: Notification) {
        guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }
        if changedKeys.contains(Keys.lifetimeEarned) {
            let remote = defaults.integer(forKey: Keys.lifetimeEarned)
            if remote > lifetimeEarned {
                lifetimeEarned = remote
            }
        }
        // lastCaptureDate: take later date to avoid double-awarding the first-capture-of-day bonus
        if changedKeys.contains(Keys.lastCaptureDate) {
            if let remote = defaults.object(forKey: Keys.lastCaptureDate) as? Date,
               let local = lastCaptureDate,
               remote > local {
                defaults.set(remote, forKey: Keys.lastCaptureDate)
            }
        }
    }
}

// MARK: - Acorn Service

/// Processes acorn earning events and updates the ledger.
///
/// Call `processCapture(hadContext:)` immediately after a successful
/// thought save. The service determines which events apply and awards
/// the combined total in a single ledger update.
///
/// The returned `AcornReward` tells the UI exactly what happened so
/// it can show the right celebration moment.
@MainActor
final class AcornService {
    static let shared = AcornService()

    private let ledger: AcornLedger

    init(ledger: AcornLedger = .shared) {
        self.ledger = ledger
    }

    // MARK: - Public API

    /// Call this after a successful thought capture.
    ///
    /// - Parameter hadContext: True if context was auto-populated (earns bonus acorn)
    /// - Returns: The reward details for UI feedback
    @discardableResult
    func processCapture(hadContext: Bool) async -> AcornReward {
        var events: [AcornEarningEvent] = [.capture]

        if hadContext {
            events.append(.contextualCapture)
        }

        if isFirstCaptureOfDay() {
            events.append(.firstCaptureOfDay)
            ledger.lastCaptureDate = Date()
        }

        return await award(events: events)
    }

    /// Call this when the user hits a streak milestone.
    ///
    /// - Parameter days: The streak length reached (3, 7, 14, 30, etc.)
    @discardableResult
    func processStreakMilestone(days: Int) async -> AcornReward {
        await award(events: [.streakMilestone(days: days)])
    }

    /// Called by VariableRewardService (issue #42) when a surprise fires.
    @discardableResult
    func processVariableReward(acorns: Int) async -> AcornReward {
        await award(events: [.variableReward(acorns: acorns)])
    }

    // MARK: - Read-Only Access

    var currentBalance: Int { get async { await ledger.currentBalance } }
    var lifetimeEarned: Int  { ledger.lifetimeEarned }

    // MARK: - Private

    private func isFirstCaptureOfDay() -> Bool {
        guard let last = ledger.lastCaptureDate else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    private func award(events: [AcornEarningEvent]) async -> AcornReward {
        let total = events.reduce(0) { $0 + $1.acorns }
        ledger.award(total)
        let newBalance = await ledger.currentBalance
        return AcornReward(events: events, total: total, newBalance: newBalance)
    }
}

// MARK: - Reward Result

/// The result of an acorn earning moment.
///
/// The capture screen uses this to decide how prominent the celebration
/// should be (a single "+1" nudge vs. a "first capture of the day!" moment).
struct AcornReward {
    let events: [AcornEarningEvent]
    let total: Int
    let newBalance: Int

    /// True when something worth calling out happened (bonus events earned)
    var isNoteworthy: Bool {
        events.contains { event in
            switch event {
            case .capture:             return false
            case .contextualCapture:   return false
            case .firstCaptureOfDay:   return true
            case .streakMilestone:     return true
            case .variableReward:      return true
            }
        }
    }
}
