# STASH — Project Handoff Document
**For:** New Claude conversation
**Repo:** `/Users/andy/Dev/personal-ai-ios`
**Current version:** 0.5 build 1 (just pushed to main, 2026-02-23)
**Platform:** iOS 18+, Swift, SwiftUI, CoreData, StoreKit 2, Foundation Models (iOS 26+)
**Bundle ID:** `com.withershins.stash`

---

## What This App Is

STASH is an ADHD-first personal thought-capture iOS app. Users speak or type fleeting thoughts; the app classifies them (reminder/event/note/idea/question), gathers ambient context (location, health, calendar, energy level), and surfaces them back intelligently. A "squirrelsona" gamification layer (streaks, acorns, badges, companion pet) drives engagement without shame or punishment. There is a subscription paywall (free: 30 thoughts/month, pro: unlimited).

**Design philosophy:** Never punish, never shame. Grace days, not lost streaks. Fail-soft on permissions. The squirrel went foraging, not died.

---

## Development Conventions (FOLLOW THESE)

- **Always use feature branches.** Never commit directly to `main`. Branch naming: `feature/`, `fix/`, `refactor/`, `experiment/`
- **Exceptions (main only):** CLAUDE.md, README.md, CHANGELOG.md updates
- **Theme-aware UI:** All views use `ThemeEngine.shared.getCurrentTheme()` — `theme.textColor`, `theme.backgroundColor`, `theme.primaryColor`, etc.
- **Shared singletons:** Most services are `.shared` — `ThoughtService.shared`, `StreakTracker.shared`, etc.
- **Read files before editing.** Always.
- **No over-engineering.** No helpers for one-time use, no future-proofing, minimum complexity for the task.

---

## What Just Shipped (v0.5 build 1)

All of this is committed and pushed to `main`. Do NOT redo any of it.

### 1. CoreData Threading Crash Fix
**Root cause:** Repositories are `actor` types (background threads) but read methods were calling `container.viewContext` (main thread only) → `EXC_BAD_ACCESS`. Fixed all five read methods in `ThoughtRepository`, `TaskRepository`, `FineTuningRepository`, `SyncRepository` to use `container.newBackgroundContext()` + `context.perform {}`.

**Files:** `Sources/Persistence/Repositories/ThoughtRepository.swift`, `TaskRepository.swift`, `FineTuningRepository.swift`, `SyncRepository.swift`

**Analytics:** Added `AnalyticsEvent.coreDataError(operation: String)` for future monitoring.

### 2. Voice Capture Transcript Wipe Fix
**Root cause:** `requiresOnDeviceRecognition = true` forces aggressive ~1-2 second silence detection. Fix: removed it, server recognition has much longer silence tolerance. Also removed complex cycling/restart machinery from the service. Each OS recognition session is now one `AsyncStream`; `VoiceCaptureViewModel` auto-restarts seamlessly when the stream ends.

**Key pattern in `VoiceCaptureViewModel`:**
- `beginCapture()` → starts stream, wires `handleSessionEnded()` on exhaustion
- `handleSessionEnded()`: if still `.listening`, saves `savedTranscript` and calls `beginCapture()` again
- `pauseListening()`: sets `.paused` BEFORE `stopListening()` so `handleSessionEnded` guard fails
- `cancelListening()`: sets `.idle` BEFORE cancel so same guard fails
- Transcription is cumulative: `savedTranscript + " " + update.text`

**Files:** `Sources/Services/Framework/SpeechRecognitionService.swift`, `Sources/UI/ViewModels/VoiceCaptureViewModel.swift`

### 3. Voice Captures Missing Gamification
**Root cause:** `VoiceCaptureViewModel.stopAndSave()` saved to CoreData but never called any gamification hooks. `StreakTracker`, acorns, badges, companion — all silent for voice captures.

**Fix:** Added to `stopAndSave()` after successful save:
```swift
let streakUpdate = StreakTracker.shared.recordCapture()
if let milestone = streakUpdate.milestone {
    _ = AcornService.shared.processStreakMilestone(days: milestone.rawValue)
}
_ = AcornService.shared.processCapture(hadContext: false)
_ = await BadgeService.shared.checkAll(newThought: saved, thoughtService: thoughtService)
_ = VariableRewardService.shared.roll()
SquirrelReminderService.shared.onCaptureCompleted()
SquirrelCompanionService.shared.recordCapture()
AnalyticsService.shared.track(.thoughtCaptured(method: .voice))
```

### 4. Streak System Overhaul
**Problems fixed:**
- Streak showed stale value after lapsing (init loaded UserDefaults without checking)
- Three screens showed three different numbers (inconsistent sources)
- Longest streak lower than current streak (no grace day logic in ChartDataService)
- Total capture days undercounted (voice captures never incremented it)

**Key changes:**

`StreakTracker` now has:
- `validateStreak()` — called at `init()` and `onAppForeground()`, resets currentStreak to 0 if lapsed
- `reconcile(from captureDates: [Date])` — single method that computes currentStreak (with grace day logic), longestStreak, and totalCaptureDays from the actual thought database and raises any stale stored values. Enforces `longestStreak ≥ currentStreak` invariant.
- `onAppForeground()` — call from `scenePhase → .active` (already wired in `STASHApp.swift`)

`AchievementsViewModel.load()` calls:
```swift
StreakTracker.shared.reconcile(from: allThoughts.map { $0.createdAt })
currentStreak    = StreakTracker.shared.currentStreak
longestStreak    = StreakTracker.shared.longestStreak
totalCaptureDays = StreakTracker.shared.totalCaptureDays
```

`StreakVisualization` now uses `StreakTracker.shared.currentStreak` (via local computed property `currentStreak`) instead of `streakData.currentStreak` from ChartDataService. longestStreak and totalDays still come from `streakData` — only the current streak changed.

**Grace day logic (existing, unchanged):** One missed day per ISO week doesn't break the streak. `StreakTracker.reconcile(from:)` uses the same ISO-week grace day logic when computing from history.

**Files:** `Sources/Services/Gamification/StreakTracker.swift`, `Sources/UI/ViewModels/AchievementsViewModel.swift`, `Sources/UI/Charts/StreakVisualization.swift`, `Sources/STASHApp.swift`

### 5. Siri Shortcut Rename
`CaptureThoughtIntent.title` changed from "Capture Thought" → "Stash a Thought". Phrase: "Stash a thought in \(.applicationName)".

**File:** `Sources/AppIntents/CaptureThoughtIntent.swift`

### 6. Free Tier Limit Change
Changed from 50 → 30 thoughts/month. Stored as top-level constant `freeMonthlyThoughtLimit = 30` in `Sources/Models/Subscription.swift`. All UI strings pull from this constant.

---

## Architecture Overview

### Layer Stack (top to bottom)
```
SwiftUI Views
    ↓
@Observable @MainActor ViewModels
    ↓
Domain Services (actor) — ThoughtService, TaskService
    ↓
Orchestration Services (actor) — ContextService, FineTuningService, SyncService
    ↓
Framework Services — LocationService, HealthKitService, EventKitService, SpeechRecognitionService
    ↓
Intelligence Services — ClassificationService, SemanticSearchService, InsightsAnalyzer
    ↓
Repositories (actor) — ThoughtRepository, TaskRepository, etc.
    ↓
CoreData (NSPersistentCloudKitContainer)
```

### Gamification is flat (not layered)
All gamification services are `@MainActor` singletons accessed directly. They don't go through `ThoughtService`. Call sites (e.g. `CaptureViewModel`, `VoiceCaptureViewModel`) call them directly after a successful save.

---

## Screens & ViewModels

| Screen | ViewModel | Key Dependencies |
|--------|-----------|-----------------|
| `BrowseScreen` | `BrowseViewModel` | ThoughtService, FineTuningService |
| `CaptureScreen` | `CaptureViewModel` | ThoughtService, ContextService, ClassificationService, FineTuningService, TaskService + all gamification |
| `VoiceCaptureScreen` | `VoiceCaptureViewModel` | SpeechRecognitionService, ThoughtService + all gamification |
| `DetailScreen` | `DetailViewModel` | ThoughtService |
| `SearchScreen` | `SearchViewModel` | ThoughtService |
| `InsightsScreen` | `InsightsViewModel` | ThoughtService, ChartDataService |
| `AchievementsScreen` | `AchievementsViewModel` | ThoughtService, StreakTracker.shared, AcornLedger.shared, BadgeService.shared |
| `SettingsScreen` | `SettingsViewModel` | HealthKitService, LocationService, EventKitService, ContactsService, ThoughtService, PermissionCoordinator |
| `ConversationScreen` | `ConversationViewModel` | ConversationService (iOS 26+ only) |
| `ThoughtConversationScreen` | `ThoughtConversationViewModel` | CompanionConversationService |
| `OnboardingScreen` | `OnboardingViewModel` | CaptureViewModel |
| `PaywallScreen` | — | SubscriptionManager.shared |

---

## Key Services

### Singletons (shared instances)
```
ThoughtService.shared          — actor, main thought CRUD
StreakTracker.shared            — @MainActor, UserDefaults-backed streak
AcornService.shared (or AcornLedger.shared — check usage)
BadgeService.shared             — @MainActor, post-capture badge checks
VariableRewardService.shared    — @MainActor, random reward rolls
SquirrelReminderService.shared  — push notification scheduling
SquirrelCompanionService.shared — companion life stages/accessories
AnalyticsService.shared         — TelemetryDeck, respects opt-out
SubscriptionManager.shared      — StoreKit 2
SpeechRecognitionService.shared — actor, Speech framework wrapper
```

### Context gathering
`ContextService` (actor) gathers location, health, calendar, motion in parallel (`TaskGroup`) with 300ms target. All sources fail-soft — missing permissions just mean missing context, not a broken capture.

`ContextEnrichmentService.shared.enrichContext(for: thought.id)` is called detached (background) after every save in both `CaptureViewModel` and `VoiceCaptureViewModel`.

---

## Data Models

**`Thought`** — core entity. Key fields: `id UUID`, `content String`, `tags [String]`, `status ThoughtStatus`, `context Context`, `createdAt Date`, `classification Classification?`, `isShiny Bool`, `relatedThoughtIds [UUID]`, `taskId UUID?`

**`Context`** — ambient snapshot. Fields: `location Location?`, `timeOfDay TimeOfDay`, `energy EnergyLevel`, `focusState UserFocusState`, `calendar CalendarContext?`, `activity ActivityContext?`, `stateOfMind StateOfMindSnapshot?`, `energyBreakdown EnergyBreakdown?`

**`Classification`** — AI output. Fields: `type ClassificationType`, `confidence Float`, `sentiment Sentiment`, `entities [String]`, `suggestedTags [String]`, `parsedDateTime ParsedDateTime?`

**`EnergyBreakdown`** — scored 0–1 per component. Weights: sleep 40%, activity 25%, HRV 20%, time-of-day 15%.

---

## Persistence

**Stack:** `NSPersistentCloudKitContainer` in `PersistenceController.shared`
- CloudKit-synced entities: `ThoughtEntity`, `ClassificationEntity`, `TaskEntity`, `FineTuningDataEntity`
- Local-only: `SyncQueueEntity`
- Preview: in-memory store via `PersistenceController.preview`

**Repositories** are all `actor` types. All operations (read AND write) use `container.newBackgroundContext()` + `context.perform {}`. Never use `container.viewContext` from an actor — that's what caused the crashes fixed in v0.5.

**Repository → Domain model mapping:** Each entity has `Thought.from(entity)` and `thought.toEntity(in: context)` conversion methods.

---

## Gamification System

| Component | State | Key Behavior |
|-----------|-------|-------------|
| `StreakTracker` | UserDefaults | Grace day (1/ISO week). `recordCapture()` → `StreakUpdate`. `reconcile(from:[Date])` corrects from DB. |
| `AcornLedger` / `AcornService` | UserDefaults | currentBalance, lifetimeEarned. `processCapture(hadContext:)`, `processStreakMilestone(days:)` |
| `BadgeService` | UserDefaults | `checkAll(newThought:thoughtService:)` async. `earnedBadgeIds: Set<String>` |
| `VariableRewardService` | UserDefaults | `roll()` → `VariableReward?`. Tiers: common (3🌰), uncommon (10), rare (25), legendary (50). One roll/session. |
| `SquirrelCompanionService` | UserDefaults | Life stages: sprout→curious→seasoned→elder→legendary. `recordCapture()`. Never dies. |
| `SquirrelReminderService` | UNUserNotificationCenter | `onCaptureCompleted()`. Max 1 notification/day. Fully opt-in. |
| `ShinyService` | CoreData | Runs daily. Scores thoughts, promotes top ~7% as `isShiny = true`. Max pool = max(3, floor(total × 0.07)). |

**Squirrel Personas (5):** Supportive Listener, Socratic Questioner, Brainstorm Partner, Journal Guide, Devil's Advocate. User selects one as default.

---

## Analytics (TelemetryDeck)

**App ID:** `9893DF09-028C-4E41-84A6-2191465CC1EC`
**Opt-out:** `UserDefaults.standard.bool(forKey: "analytics.optOut")`

Key tracked events (from `AnalyticsEvent` enum): `thoughtCaptured(method: .text/.voice)`, `screenViewed`, `searchPerformed`, `acornEarned`, `badgeUnlocked`, `themeChanged`, `personaSelected`, `onboardingCompleted`, `siriShortcutUsed`, `classificationFailed`, `aiUnavailable`, `coreDataError(operation:)`.

---

## Subscription System

**Constant:** `freeMonthlyThoughtLimit = 30` (top of `Sources/Models/Subscription.swift`)

**Tiers:** `.free` (30 thoughts/month, basic AI, state of mind), `.pro` (unlimited, advanced analytics, export)

**Products:** `com.personalai.pro.monthly` ($4.99), `com.personalai.pro.annual`

**Enforcement:** `CaptureViewModel` checks `SubscriptionUsage.calculate(from: allThoughts)` before saving. `SubscriptionUsage` counts thoughts where `createdAt` is in the current calendar month.

**Manager:** `SubscriptionManager.shared` — StoreKit 2, `Transaction.currentEntitlements`, `Transaction.updates` listener.

---

## App Intents / Siri

`Sources/AppIntents/`:
- `CaptureThoughtIntent` — "Stash a Thought". Params: content (optional), type, autoClassify. If no content → sets `UserDefaults(suiteName: "group.com.withershins.stash")["pendingVoiceCapture"] = true` → app opens voice capture.
- `OpenVoiceCaptureIntent` — sets same flag
- `SearchThoughtsIntent`
- `ThoughtAppShortcuts: AppShortcutsProvider`

`MainTabView` polls for `pendingVoiceCapture` flag every 0.5s when active and on `scenePhase → .active`.

---

## Known Issues / Open Work

### Bugs (from testing)
- **HealthKit step count** — returns 0 or missing. Affects energy calculation (25% weight). Root cause unknown. `Sources/Services/Framework/HealthKitService.swift` (TD-001)
- **Location name occasionally blank** — reverse geocoding intermittent. Cosmetic. `Sources/Services/Framework/LocationService.swift` (TD-002)

### TODOs in code
- `userId: UUID()` hardcoded throughout — needs real user session (both `CaptureViewModel` and `VoiceCaptureViewModel`)
- `MedicationService` — stub waiting for `HKUserAnnotatedMedication` API
- `ConversationScreen` — navigate-to-detail and show-all-citations not implemented
- `WatershipDownTheme` — parchment texture, gem sparkle, watercolor wash assets not yet created

### Technical Debt
- CoreData concurrency (TD-005) — **RESOLVED in v0.5**
- Classification service coupling to local impl — needs provider pattern for backend (TD-003)
- No unit tests for ViewModels (TD-006)
- Error handling inconsistency across services — some throw, some return optionals (TD-004)

---

## Roadmap

**Now:** TestFlight beta, watching analytics on free tier limit (30/month, may adjust)

**Phase 4 (next):**
1. Smart date/time parsing — "call mom tomorrow at 2pm" → pre-populated date
2. Calendar selection (work vs personal calendar for events)
3. Pattern learning from classification feedback

**Phase 5 (critical):** Backend infrastructure
- Recommended: Hybrid (Supabase for auth/sync/storage + custom service for AI/ML)
- Currently: CloudKit for multi-device sync, local-only classification

**Phase 6:** Social, Watch app, third-party integrations (Notion, Todoist)

---

## File Structure Quick Reference

```
Sources/
  AppIntents/         — Siri/Shortcuts intents
  Models/             — Domain structs (Thought, Context, Classification, Subscription, etc.)
  Persistence/
    CoreDataStack/    — PersistenceController
    Entities/         — NSManagedObject subclasses
    Repositories/     — ThoughtRepository, TaskRepository, etc. (all actors)
    Filters/          — ThoughtFilter, TaskFilter
  Services/
    Analytics/        — AnalyticsService, AnalyticsEvent, ChartDataService
    Domain/           — ThoughtService, TaskService
    Framework/        — SpeechRecognitionService, LocationService, HealthKitService, etc.
    Gamification/     — StreakTracker, AcornLedger, BadgeService, VariableRewardService,
                        SquirrelCompanionService, SquirrelReminderService, ShinyService
    Intelligence/     — ClassificationService, SemanticSearchService, InsightsAnalyzer
    Monetization/     — SubscriptionManager
    Orchestration/    — ContextService, FineTuningService, SyncService
    AI/               — ConversationService, CompanionConversationService (iOS 26+)
  UI/
    Charts/           — StreakVisualization, ChartViews, Chart3D (hidden)
    Components/       — Reusable views, theme components
    Screens/          — One file per screen
    ViewModels/       — One file per ViewModel
  Resources/          — Assets, Info.plist, entitlements
  STASHApp.swift      — App entry, MainTabView, NotificationDelegate
docs/
  planning/           — ROADMAP.md, TECHNICAL_DEBT.md, CUSTOMER_REQUESTS.md
  PROJECT_HANDOFF.md  — This file
CHANGELOG.md
CLAUDE.md             — Dev conventions (READ THIS FIRST)
```

---

## Branch Status

`main` is clean and up to date. All v0.5 work is merged. Start new work on a feature branch.

```bash
git checkout -b feature/your-feature-name
```
