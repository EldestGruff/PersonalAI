# Phase 3B Spec: iCloud Key-Value Sync for Gamification & Preferences

**Branch:** `feature/icloud-kv-sync`  
**Execution model:** Sonnet implements → Opus reviews  
**Scope:** Migrate gamification state and user preferences from `UserDefaults` to `NSUbiquitousKeyValueStore`

---

## Background

Thoughts sync via CloudKit / NSPersistentCloudKitContainer (implemented in Phase 3A).  
Gamification state and preferences are currently `UserDefaults`-backed and device-local.  
This spec migrates them to `NSUbiquitousKeyValueStore` (iCloud KV Store) for cross-device sync.

**Why iCloud KV Store (not CloudKit)?**  
- All values are small primitives (ints, strings, dates, small arrays/JSON)
- Total data volume is well under the 1MB iCloud KV limit
- API is near-identical to `UserDefaults` — minimal code change per service
- Automatic sync, no schema, no async fetch required

**Exception: Acorn spend events use CloudKit (not KV Store)**  
The acorn balance cannot be stored directly in KV Store because of a spend race condition: if the user spends acorns on two devices before sync, the "take max" merge strategy would silently drop one purchase. Since acorns represent real earned effort, this is unacceptable.

The correct model:
- `acorn.lifetimeEarned` → KV Store (monotonically increasing, take max, safe)
- Spend events → CloudKit append-only `AcornSpendRecord` (each spend is its own record; concurrent writes both survive)
- `currentBalance` → derived at runtime as `lifetimeEarned - sum(allSpendRecords)`, **never stored directly**

This is the only value in the entire spec that requires CloudKit records. Everything else is safe with KV Store.

---

## What Syncs vs. What Stays Local

### ✅ Migrate to NSUbiquitousKeyValueStore

| Service | Keys |
|---|---|
| `AcornLedger` | `acorn.lifetimeEarned`, `acorn.lastCaptureDate` (KV Store) + spend events via CloudKit `AcornSpendRecord` — see below |
| `StreakTracker` | `streak.current`, `streak.longest`, `streak.totalDays`, `streak.lastCaptureDate`, `streak.graceDayWeek`, `streak.milestonesAwarded` |
| `BadgeService` | `badge.earnedIds`, `badge.earnedDates` |
| `SquirrelCompanionService` | `companion.lifetimeCaptures`, `companion.ownedAccessories`, `companion.equippedAccessory`, `companion.shinyCount` |
| `ShinyService` | `shiny.lastPromotionDate` |
| `PersonaService` | `squirrel_personas`, `default_persona_id` |
| `ThemeEngine` | `selected_theme` |

### ❌ Keep in UserDefaults (device-local by design)

| Service | Reason |
|---|---|
| `SettingsViewModel` — `selectedCalendarId`, `selectedReminderListId`, `autoCreateReminders` | Calendar/reminder identifiers are device-specific |
| `HealthKitService` | Authorization state is per-device |
| `AnalyticsService` | Consent/opt-in is per-device |
| `ClassificationBiasStore` | ML training data — per-device, potentially large |
| `SquirrelReminderService` | Notification scheduling state is per-device |
| `VariableRewardService` | Reward timing state — device-local intentional |
| `companion.adventureReturnShown` | UI "already shown" flag — device-local |
| All ViewModel UI state | Transient UI, not preferences |

---

## Architecture: SyncedDefaults Wrapper

Create `Sources/Services/Sync/SyncedDefaults.swift`.

This wrapper provides a `UserDefaults`-compatible API over `NSUbiquitousKeyValueStore`. All migrated services swap `UserDefaults.standard` for `SyncedDefaults.shared` — no other API changes needed.

```swift
// Sources/Services/Sync/SyncedDefaults.swift

import Foundation

/// A UserDefaults-compatible wrapper over NSUbiquitousKeyValueStore.
/// Provides automatic iCloud sync for gamification state and preferences.
/// 
/// Usage: Drop-in replacement for UserDefaults.standard in services
/// that should sync across devices.
///
/// Merge strategy on external change:
/// - Numeric values (acorns, streaks, counts): take max
/// - Sets/arrays (badges, accessories): union
/// - Scalar preferences (theme, persona ID, dates): last-write-wins
final class SyncedDefaults {
    static let shared = SyncedDefaults()

    private let store = NSUbiquitousKeyValueStore.default
    private let localFallback = UserDefaults.standard

    private init() {
        // Flush to iCloud on init
        store.synchronize()

        // Observe external changes (other devices writing)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChangeExternally(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    // MARK: - Get/Set API (mirrors UserDefaults)

    func integer(forKey key: String) -> Int {
        Int(store.longLong(forKey: key))
    }

    func set(_ value: Int, forKey key: String) {
        store.set(Int64(value), forKey: key)
        store.synchronize()
    }

    func string(forKey key: String) -> String? {
        store.string(forKey: key)
    }

    func set(_ value: String?, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func bool(forKey key: String) -> Bool {
        store.bool(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func object(forKey key: String) -> Any? {
        store.object(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func data(forKey key: String) -> Data? {
        store.data(forKey: key)
    }

    func set(_ value: Data?, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func stringArray(forKey key: String) -> [String]? {
        store.array(forKey: key) as? [String]
    }

    // MARK: - External Change Handler

    @objc private func storeDidChangeExternally(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }

        let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int

        // Handle quota exceeded — log and continue (data is read-only in this case)
        if reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
            print("⚠️ SyncedDefaults: iCloud KV quota exceeded")
            return
        }

        // Notify services to re-read their values
        NotificationCenter.default.post(
            name: .syncedDefaultsDidChangeExternally,
            object: nil,
            userInfo: ["changedKeys": changedKeys]
        )
    }
}

extension Notification.Name {
    static let syncedDefaultsDidChangeExternally = Notification.Name("SyncedDefaultsDidChangeExternally")
}
```

---

## Migration Plan — Per Service

### 1. AcornLedger (`AcornService.swift`)

The acorn ledger requires a split architecture to prevent spend race conditions.

#### 1a. AcornSpendRecord — new CloudKit entity

Add `AcornSpendRecord` to the Core Data model (syncable=YES so NSPersistentCloudKitContainer syncs it):

```
Entity: AcornSpendRecord
  id:        UUID     (required)
  amount:    Int32    (required, positive integer)
  reason:    String   (e.g. "accessory.flower_crown")
  createdAt: Date     (required)
```

This is an **append-only** entity. Records are never updated or deleted. Each purchase creates exactly one record.

#### 1b. AcornLedger changes

**Remove** `currentBalance` storage entirely — it is now derived.

**Keep in KV Store (via SyncedDefaults):**
- `acorn.lifetimeEarned` — take max on external change
- `acorn.lastCaptureDate` — take later date on external change

**Add** `fetchTotalSpent() async -> Int` which queries CoreData:
```swift
private func fetchTotalSpent() async -> Int {
    let request = AcornSpendRecord.fetchRequest()
    let records = (try? await context.perform { try context.fetch(request) }) ?? []
    return records.reduce(0) { $0 + Int($1.amount) }
}
```

**Derive balance** on every read:
```swift
var currentBalance: Int {
    get async {
        let spent = await fetchTotalSpent()
        return max(0, lifetimeEarned - spent)
    }
}
```

**Modify `spend(_ amount: Int)`** to write a CloudKit record instead of decrementing a stored value:
```swift
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
```

**External change handling** for KV keys (lifetimeEarned only, balance is auto-derived from CloudKit):
```swift
@objc private func handleExternalChange(_ notification: Notification) {
    guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }
    if changedKeys.contains(Keys.lifetimeEarned) {
        let remote = defaults.integer(forKey: Keys.lifetimeEarned)
        if remote > lifetimeEarned {
            lifetimeEarned = remote
        }
    }
}
```

**Note on `SquirrelCompanionService.purchase()`:** The purchase method calls `AcornLedger.shared.spend()` which is now `async`. Update the call site accordingly.

**Note:** `lastCaptureDate` is used for "first capture of day" bonus. On external change, take the *later* date (more recent capture wins — avoids double-awarding the bonus).

---

### 2. StreakTracker (`StreakTracker.swift`)

**Change:** Replace `private let defaults = UserDefaults.standard` with `private let defaults = SyncedDefaults.shared`

**Add external change handling** with max-merge strategy:
- `streak.current` → take max
- `streak.longest` → take max  
- `streak.totalDays` → take max
- `streak.lastCaptureDate` → take later date
- `streak.graceDayWeek` → last-write-wins (week string)
- `streak.milestonesAwarded` → union of both arrays (never remove a milestone)

```swift
@objc private func handleExternalChange(_ notification: Notification) {
    guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }

    if changedKeys.contains(Keys.currentStreak) {
        let remote = defaults.integer(forKey: Keys.currentStreak)
        if remote > currentStreak {
            currentStreak = remote
        }
    }
    if changedKeys.contains(Keys.longestStreak) {
        let remote = defaults.integer(forKey: Keys.longestStreak)
        if remote > longestStreak {
            longestStreak = remote
        }
    }
    if changedKeys.contains(Keys.totalCaptureDays) {
        let remote = defaults.integer(forKey: Keys.totalCaptureDays)
        if remote > totalCaptureDays {
            totalCaptureDays = remote
        }
    }
    if changedKeys.contains(Keys.milestonesAwarded) {
        // Union — never lose a milestone
        let local = Set((defaults.stringArray(forKey: Keys.milestonesAwarded) ?? [])
            .compactMap { Int($0) })
        // Already handled via the shared store — re-read and merge
        let remote = (defaults.object(forKey: Keys.milestonesAwarded) as? [Int]) ?? []
        let union = Array(Set(remote).union(local))
        defaults.set(union, forKey: Keys.milestonesAwarded)
    }
}
```

---

### 3. BadgeService (`BadgeService.swift`)

**Change:** Replace `private let defaults = UserDefaults.standard` with `private let defaults = SyncedDefaults.shared`

**Add external change handling** — badges are a set, so union merge:
```swift
@objc private func handleExternalChange(_ notification: Notification) {
    guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }
    
    if changedKeys.contains(Keys.earnedIds) {
        let remote = Set(defaults.stringArray(forKey: Keys.earnedIds) ?? [])
        let merged = earnedBadgeIds.union(remote)
        if merged != earnedBadgeIds {
            earnedBadgeIds = merged
            // Persist the merged union
            defaults.set(Array(merged), forKey: Keys.earnedIds)
        }
    }
    if changedKeys.contains(Keys.earnedDates) {
        // Re-read dates from store
        if let data = defaults.data(forKey: Keys.earnedDates),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            // Merge: keep earliest date per badge (first time earned)
            for (badgeId, remoteDate) in decoded {
                if let localDate = earnedDates[badgeId] {
                    earnedDates[badgeId] = min(localDate, remoteDate)
                } else {
                    earnedDates[badgeId] = remoteDate
                }
            }
        }
    }
}
```

---

### 4. SquirrelCompanionService (`SquirrelCompanionService.swift`)

**Change:** Replace `UserDefaults.standard` references with `SyncedDefaults.shared`

**Exception:** Keep `Keys.adventureShown` in `UserDefaults.standard` — this is device-local UI state (whether the "welcome back" message has been shown on *this* device).

**External change handling:**
- `companion.lifetimeCaptures` → take max
- `companion.ownedAccessories` → union (never lose an accessory)
- `companion.equippedAccessory` → last-write-wins
- `companion.shinyCount` → take max

---

### 5. ShinyService (`ShinyService.swift`)

**Change:** The one `UserDefaults.standard` usage (`shiny.lastPromotionDate`) → `SyncedDefaults.shared`

No merge handler needed — last-write-wins for a throttle date is fine.

---

### 6. PersonaService (`SquirrelPersona.swift`)

**Change:** Replace `UserDefaults.standard` with `SyncedDefaults.shared` for:
- `squirrel_personas` (custom personas JSON)
- `default_persona_id`

**External change handling:**
- Custom personas: merge by UUID — remote personas with IDs not in local set are added; never delete
- Default persona ID: last-write-wins

---

### 7. ThemeEngine (`ThemeEngine.swift`)

**Change:** Replace `UserDefaults.standard` with `SyncedDefaults.shared` for `selected_theme`

**External change handling:** Re-read theme from store and update `currentTheme`. Last-write-wins is correct here.

---

## One-Time Migration: Existing Local Data

On first launch after this update, a device may have existing `UserDefaults` data that should be promoted to iCloud KV Store. Without migration, the iCloud store starts empty and overwrites the user's existing local state.

Add a `SyncedDefaultsMigration` utility called once at app startup:

```swift
// Sources/Services/Sync/SyncedDefaultsMigration.swift

struct SyncedDefaultsMigration {
    static let migrationKey = "syncedDefaults.v1.migrated"

    /// Call once at app startup, before services initialize.
    static func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let local = UserDefaults.standard
        let synced = SyncedDefaults.shared

        // Migrate each key — only if local value is higher/non-nil and synced is empty
        // Acorn balance migration: create a synthetic opening-balance spend record
        // so that derived balance (lifetimeEarned - spendRecords) equals the user's
        // actual current balance at migration time. This preserves earned acorns.
        //
        // e.g. lifetimeEarned=341, currentBalance=241 → synthetic spend record of 100
        //
        // After migration, all future spends append real AcornSpendRecords.
        // The synthetic record is a one-time bridge — never created again.
        migrateAcornBalance(context: context)
        migrateInt(Keys.acornLifetime, from: local, to: synced)
        migrateInt(Keys.streakCurrent, from: local, to: synced)
        migrateInt(Keys.streakLongest, from: local, to: synced)
        migrateInt(Keys.streakTotalDays, from: local, to: synced)
        migrateObject(Keys.acornLastCapture, from: local, to: synced)
        migrateObject(Keys.streakLastCapture, from: local, to: synced)
        migrateStringArray(Keys.badgeEarnedIds, from: local, to: synced)
        migrateData(Keys.badgeEarnedDates, from: local, to: synced)
        migrateInt(Keys.companionLifetimeCaptures, from: local, to: synced)
        migrateStringArray(Keys.companionOwnedAccessories, from: local, to: synced)
        migrateString(Keys.companionEquipped, from: local, to: synced)
        migrateString(Keys.selectedTheme, from: local, to: synced)
        migrateString(Keys.defaultPersonaId, from: local, to: synced)
        migrateData(Keys.customPersonas, from: local, to: synced)

        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    // Migration helpers: only write to synced if local has a value
    // and synced is currently empty (first device to migrate wins)
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

    private static func migrateData(_ key: String, from local: UserDefaults, to synced: SyncedDefaults) {
        guard let val = local.data(forKey: key), synced.data(forKey: key) == nil else { return }
        synced.set(val, forKey: key)
    }

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

        // Create a single synthetic record representing all historical spend
        context.perform {
            let record = AcornSpendRecord(context: context)
            record.id = UUID()
            record.amount = Int32(totalSpent)
            record.reason = "migration.opening_balance"
            record.createdAt = Date()
            try? context.save()
        }
    }

    // All keys to migrate — must match actual UserDefaults keys in each service
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
```

Call in `STASHApp.swift` before the view hierarchy initializes, passing the CoreData context:
```swift
SyncedDefaultsMigration.migrateIfNeeded(context: PersistenceController.shared.container.viewContext)
```

---

## Testing Checklist

- [ ] Earn acorns on iPhone → appear on iPad within 5 minutes
- [ ] Earn a badge on iPhone → appears in Achievements on iPad
- [ ] Change theme on iPhone → iPad updates theme
- [ ] Change default persona on iPhone → iPad reflects it
- [ ] Existing acorn balance preserved after update (migration test: lifetimeEarned=341, currentBalance=241 → synthetic spend record of 100 created, derived balance = 241 ✓)
- [ ] User who has never spent acorns: no synthetic record created, balance = lifetimeEarned
- [ ] No double-award of first-capture-of-day bonus when devices sync
- [ ] App functions normally when iCloud is unavailable (graceful degradation — reads from local KV cache)

---

## Files to Create
- `Sources/Services/Sync/SyncedDefaults.swift`
- `Sources/Services/Sync/SyncedDefaultsMigration.swift`
- Core Data model: add `AcornSpendRecord` entity (syncable=YES) as a new model version — must be done in Xcode, not by hand

## Files to Modify
- `Sources/Services/Gamification/AcornService.swift`
- `Sources/Services/Gamification/StreakTracker.swift`
- `Sources/Services/Gamification/BadgeService.swift`
- `Sources/Services/Gamification/ShinyService.swift`
- `Sources/Services/Gamification/SquirrelCompanionService.swift`
- `Sources/Models/SquirrelPersona.swift` (PersonaService)
- `Sources/UI/Theme/ThemeEngine.swift`
- `Sources/STASHApp.swift` (add migration call)

## Files to Leave Unchanged
All of `SettingsViewModel.swift`, `HealthKitService.swift`, `AnalyticsService.swift`, `ClassificationBiasStore.swift`, `SquirrelReminderService.swift`, `VariableRewardService.swift`
