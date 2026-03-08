# Phase 3B Execution Guide: iCloud KV Sync for Gamification & Preferences

You are implementing the iCloud sync spec for STASH's gamification state and user preferences.

**Before writing any code**, read these files in full:
1. `/Users/andy/Dev/personal-ai-ios/PhaseDocs/Phase3B_Spec_iCloudKVSync.md` — the complete spec
2. `/Users/andy/Dev/personal-ai-ios/CLAUDE.md` — project conventions and gotchas
3. `/Users/andy/Dev/personal-ai-ios/Sources/Services/Gamification/AcornService.swift`
4. `/Users/andy/Dev/personal-ai-ios/Sources/Services/Gamification/StreakTracker.swift`
5. `/Users/andy/Dev/personal-ai-ios/Sources/Services/Gamification/BadgeService.swift`
6. `/Users/andy/Dev/personal-ai-ios/Sources/Services/Gamification/ShinyService.swift`
7. `/Users/andy/Dev/personal-ai-ios/Sources/Services/Gamification/SquirrelCompanionService.swift`
8. `/Users/andy/Dev/personal-ai-ios/Sources/Models/SquirrelPersona.swift`
9. `/Users/andy/Dev/personal-ai-ios/Sources/UI/Theme/ThemeEngine.swift`
10. `/Users/andy/Dev/personal-ai-ios/Sources/STASHApp.swift`
11. `/Users/andy/Dev/personal-ai-ios/Sources/Persistence/CoreDataStack/PersistenceController.swift`

---

## Step 1 — Create SyncedDefaults wrapper

Create `/Users/andy/Dev/personal-ai-ios/Sources/Services/Sync/SyncedDefaults.swift`

Implement exactly as specified in the spec. This is the drop-in replacement for `UserDefaults.standard` in all migrated services.

---

## Step 2 — Add AcornSpendRecord to Core Data model

**This step must be done in Xcode, not by editing XML directly.**

Instructions for the developer (you cannot do this step — flag it clearly):

> **MANUAL XCODE STEP REQUIRED before building:**
> 1. Open `PersonalAI.xcodeproj` in Xcode
> 2. Navigate to `Sources/Persistence/CoreDataStack/STASH.xcdatamodeld`
> 3. Select the current model version → Editor → Add Model Version → name it `PersonalAI 2`
> 4. Set `PersonalAI 2` as the current version (select it, then Editor → Set Current Version)
> 5. In `PersonalAI 2`, add entity `AcornSpendRecord` with attributes:
>    - `id`: UUID, not optional
>    - `amount`: Integer 32, not optional
>    - `reason`: String, not optional
>    - `createdAt`: Date, not optional
> 6. Set the entity's syncable = YES (in the entity inspector, ensure CloudKit sync is on)
> 7. Save

After the developer completes this step, generate the NSManagedObject subclass for `AcornSpendRecord`:
- Xcode → Editor → Create NSManagedObject Subclass → select `AcornSpendRecord`
- Place generated files in `Sources/Persistence/CoreDataStack/`

---

## Step 3 — Update AcornService.swift

Implement the split architecture as specified:
- Remove `currentBalance` storage
- `lifetimeEarned` moves to `SyncedDefaults`
- `spend()` becomes async, writes an `AcornSpendRecord` to CoreData
- `currentBalance` is derived as `lifetimeEarned - fetchTotalSpent()`
- Add external change handler for KV notifications

**Important:** `SquirrelCompanionService.purchase()` calls `AcornLedger.shared.spend()` — update that call site to `await` since `spend()` is now async.

---

## Step 4 — Update StreakTracker.swift

- Replace `private let defaults = UserDefaults.standard` with `private let defaults = SyncedDefaults.shared`
- Add observer for `.syncedDefaultsDidChangeExternally` in `init()`
- Implement `handleExternalChange` with merge strategy per spec:
  - `streak.current`, `streak.longest`, `streak.totalDays` → take max
  - `streak.lastCaptureDate` → take later date
  - `streak.milestonesAwarded` → union of both arrays

---

## Step 5 — Update BadgeService.swift

- Replace `private let defaults = UserDefaults.standard` with `private let defaults = SyncedDefaults.shared`
- Add observer for `.syncedDefaultsDidChangeExternally` in `init()`
- Implement `handleExternalChange` with merge strategy:
  - `badge.earnedIds` → union of both sets
  - `badge.earnedDates` → keep earliest date per badge

---

## Step 6 — Update ShinyService.swift

- Replace the single `UserDefaults.standard` usage (`shiny.lastPromotionDate`) with `SyncedDefaults.shared`
- No merge handler needed — last-write-wins for throttle date is correct

---

## Step 7 — Update SquirrelCompanionService.swift

- Replace `UserDefaults.standard` with `SyncedDefaults.shared` for all keys **except** `companion.adventureReturnShown` — that key stays in `UserDefaults.standard` (device-local UI state)
- Add observer for `.syncedDefaultsDidChangeExternally` in `init()`
- Implement `handleExternalChange`:
  - `companion.lifetimeCaptures` → take max
  - `companion.ownedAccessories` → union
  - `companion.equippedAccessory` → last-write-wins
  - `companion.shinyCount` → take max

---

## Step 8 — Update PersonaService in SquirrelPersona.swift

- Replace `UserDefaults.standard` with `SyncedDefaults.shared` for `squirrel_personas` and `default_persona_id`
- Add observer for `.syncedDefaultsDidChangeExternally`
- Implement `handleExternalChange`:
  - Custom personas: merge by UUID (add remote personas not in local set, never delete)
  - Default persona ID: last-write-wins

---

## Step 9 — Update ThemeEngine.swift

- Replace `UserDefaults.standard` with `SyncedDefaults.shared` for `selected_theme`
- Add observer for `.syncedDefaultsDidChangeExternally`
- On external change: re-read `selected_theme` and update `currentTheme`

---

## Step 10 — Create SyncedDefaultsMigration

Create `/Users/andy/Dev/personal-ai-ios/Sources/Services/Sync/SyncedDefaultsMigration.swift`

Implement exactly as specified. Key points:
- Guarded by `syncedDefaults.v1.migrated` flag — runs exactly once per device
- `migrateAcornBalance(context:)` creates synthetic `AcornSpendRecord` so derived balance equals actual current balance
- All other migrations are "only write if local has value and synced is empty"

---

## Step 11 — Update STASHApp.swift

Add migration call before the view hierarchy:
```swift
SyncedDefaultsMigration.migrateIfNeeded(context: PersistenceController.shared.container.viewContext)
```

---

## Step 12 — Deploy CloudKit schema

After building and running on a real device for the first time with `AcornSpendRecord`:
1. Go to icloud.developer.apple.com/dashboard
2. Find container `iCloud.com.withershins.stash`
3. Schema → Deploy Schema Changes to Production

Flag this as a required manual step in your output.

---

## What NOT to change

Do not modify any of these files:
- `SettingsViewModel.swift`
- `HealthKitService.swift`
- `AnalyticsService.swift`
- `ClassificationBiasStore.swift`
- `SquirrelReminderService.swift`
- `VariableRewardService.swift`
- Any ViewModel UI state files

---

## Completion criteria

- [ ] `SyncedDefaults.swift` created
- [ ] `SyncedDefaultsMigration.swift` created
- [ ] All 7 services updated (AcornService, StreakTracker, BadgeService, ShinyService, SquirrelCompanionService, PersonaService, ThemeEngine)
- [ ] `STASHApp.swift` updated with migration call
- [ ] `SquirrelCompanionService.purchase()` updated for async `spend()`
- [ ] All Swift 6 concurrency requirements satisfied (no new warnings)
- [ ] Project builds cleanly

Flag the two manual Xcode/CloudKit steps clearly in your output so the developer knows what to do after you finish.
