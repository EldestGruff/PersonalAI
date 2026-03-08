//
//  SyncedDefaultsMigration.swift
//  STASH
//
//  One-time migration of existing UserDefaults data to NSUbiquitousKeyValueStore.
//
//  Run once at app startup (before services initialize) via:
//    SyncedDefaultsMigration.migrateIfNeeded(context: PersistenceController.shared.container.viewContext)
//
//  Guarded by `syncedDefaults.v1.migrated` flag — runs exactly once per device.
//  The first device to migrate writes its data to the KV Store; subsequent devices
//  skip the migration because the flag is already set.
//

import Foundation
import CoreData

struct SyncedDefaultsMigration {
    static let migrationKey = "syncedDefaults.v1.migrated"

    /// Call once at app startup, before services initialize.
    /// - Parameter context: The app's main NSManagedObjectContext (for creating AcornSpendRecord)
    static func migrateIfNeeded(context: NSManagedObjectContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let local = UserDefaults.standard
        let synced = SyncedDefaults.shared

        // Migrate acorn balance first — creates a synthetic spend record so the
        // derived balance (lifetimeEarned - spendRecords) equals the user's actual
        // pre-migration balance. This runs before migrateInt for lifetimeEarned.
        migrateAcornBalance(context: context)

        migrateInt(Keys.acornLifetime, from: local, to: synced)
        migrateObject(Keys.acornLastCapture, from: local, to: synced)
        migrateInt(Keys.streakCurrent, from: local, to: synced)
        migrateInt(Keys.streakLongest, from: local, to: synced)
        migrateInt(Keys.streakTotalDays, from: local, to: synced)
        migrateObject(Keys.streakLastCapture, from: local, to: synced)
        migrateString(Keys.streakGraceDay, from: local, to: synced)
        migrateIntArray(Keys.streakMilestones, from: local, to: synced)
        migrateStringArray(Keys.badgeEarnedIds, from: local, to: synced)
        migrateData(Keys.badgeEarnedDates, from: local, to: synced)
        migrateInt(Keys.companionLifetimeCaptures, from: local, to: synced)
        migrateStringArray(Keys.companionOwnedAccessories, from: local, to: synced)
        migrateString(Keys.companionEquipped, from: local, to: synced)
        migrateInt(Keys.companionShinyCount, from: local, to: synced)
        migrateObject(Keys.shinyLastPromotion, from: local, to: synced)
        migrateString(Keys.selectedTheme, from: local, to: synced)
        migrateString(Keys.defaultPersonaId, from: local, to: synced)
        migrateData(Keys.customPersonas, from: local, to: synced)

        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    // MARK: - Acorn Balance Migration

    /// Creates a synthetic opening-balance AcornSpendRecord so the derived balance
    /// (lifetimeEarned - sum(spendRecords)) equals the user's actual balance at migration.
    ///
    /// Only runs once — guarded by the migration key. If currentBalance == lifetimeEarned
    /// (user has never spent anything), no record is created.
    ///
    /// - Parameter context: The app's main NSManagedObjectContext
    private static func migrateAcornBalance(context: NSManagedObjectContext) {
        let local = UserDefaults.standard
        let lifetimeEarned = local.integer(forKey: Keys.acornLifetime)
        let currentBalance = local.integer(forKey: "acorn.currentBalance")
        let totalSpent = lifetimeEarned - currentBalance

        // Nothing to migrate if user has never spent, or data is missing
        guard lifetimeEarned > 0, totalSpent > 0 else { return }

        // Idempotency guard: if a migration record already exists (e.g. from a previous
        // run that crashed after Core Data saved but before the migration flag was written),
        // skip creation entirely. This prevents double-counting historical spend.
        // performAndWait ensures the save completes before migrateIfNeeded sets its guard flag,
        // eliminating the async window where a crash could leave data in an inconsistent state.
        context.performAndWait {
            let request = AcornSpendRecord.fetchRequest()
            let existing = (try? context.fetch(request)) ?? []
            guard !existing.contains(where: { $0.reason == "migration.opening_balance" }) else { return }

            let record = AcornSpendRecord(context: context)
            record.id = UUID()
            record.amount = Int32(totalSpent)
            record.reason = "migration.opening_balance"
            record.createdAt = Date()
            try? context.save()
        }
    }

    // MARK: - Migration Helpers
    // Only write to synced if local has a value AND synced is currently empty.
    // This ensures the first device to migrate wins.

    private static func migrateInt(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        let localVal = local.integer(forKey: key)
        guard localVal > 0, synced.integer(forKey: key) == 0 else { return }
        synced.set(localVal, forKey: key)
    }

    private static func migrateObject(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        guard let val = local.object(forKey: key), synced.object(forKey: key) == nil else { return }
        synced.set(val, forKey: key)
    }

    private static func migrateString(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        guard let val = local.string(forKey: key), synced.string(forKey: key) == nil else { return }
        synced.set(val, forKey: key)
    }

    private static func migrateStringArray(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        guard let val = local.stringArray(forKey: key), synced.stringArray(forKey: key) == nil else { return }
        synced.set(val, forKey: key)
    }

    private static func migrateIntArray(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        guard let val = local.array(forKey: key) as? [Int],
              !val.isEmpty,
              synced.object(forKey: key) == nil else { return }
        synced.set(val, forKey: key)
    }

    private static func migrateData(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        guard let val = local.data(forKey: key), synced.data(forKey: key) == nil else { return }
        synced.set(val, forKey: key)
    }

    // MARK: - Key Manifest
    // Must match the actual UserDefaults keys used in each service.

    private enum Keys {
        static let acornLifetime             = "acorn.lifetimeEarned"
        static let acornLastCapture          = "acorn.lastCaptureDate"
        static let streakCurrent             = "streak.current"
        static let streakLongest             = "streak.longest"
        static let streakTotalDays           = "streak.totalDays"
        static let streakLastCapture         = "streak.lastCaptureDate"
        static let streakGraceDay            = "streak.graceDayWeek"
        static let streakMilestones          = "streak.milestonesAwarded"
        static let badgeEarnedIds            = "badge.earnedIds"
        static let badgeEarnedDates          = "badge.earnedDates"
        static let companionLifetimeCaptures = "companion.lifetimeCaptures"
        static let companionOwnedAccessories = "companion.ownedAccessories"
        static let companionEquipped         = "companion.equippedAccessory"
        static let companionShinyCount       = "companion.shinyCount"
        static let shinyLastPromotion        = "shiny.lastPromotionDate"
        static let selectedTheme             = "selected_theme"
        static let defaultPersonaId          = "default_persona_id"
        static let customPersonas            = "squirrel_personas"
    }
}
