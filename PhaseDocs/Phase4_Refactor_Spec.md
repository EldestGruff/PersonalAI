# Phase 4 — Codebase Refactor & Quality Hardening

## Goal
Systematic cleanup of the STASH codebase: eliminate duplication, decompose monolith functions, standardize naming conventions, and extract shared infrastructure. No new features. No behavior changes. Every task is purely structural.

## Guiding Principles
- **No behavior changes.** If it changes what the app does, it's out of scope.
- **One concern per function.** Functions answer one question or perform one action.
- **Extract before you abstract.** Move code first, then introduce a type if warranted.
- **Naming reflects intent.** Function names are verbs, type names are nouns, booleans are predicates.
- **Risk-ordered execution.** Lowest-risk tasks first. Each task independently committable.

---

## Work Breakdown

### Wave 1 — Extract Shared Infrastructure (Zero Risk)
New utility files. No existing file changed except to import and call the new code.

---

#### Task 1.1 — Create `AppConstants.swift`
**New file:** `Sources/Configuration/AppConstants.swift`

Extract all hardcoded identifiers and limits into a single source of truth.

```swift
enum AppConstants {
    enum AppGroup {
        static let identifier = "group.com.withershins.stash"
        static var defaults: UserDefaults? {
            UserDefaults(suiteName: identifier)
        }
    }
    enum CloudKit {
        static let containerIdentifier = "iCloud.com.withershins.stash"
    }
    enum Classification {
        static let maxCacheSize = 100
        static let recentThoughtsLimit = 50
        static let maxSuggestionCount = 3
    }
}
```

**Find and replace these literals after creating the file:**
- `"group.com.withershins.stash"` → `AppConstants.AppGroup.identifier` (2 locations: `STASHApp.swift:208`, `CaptureThoughtIntent.swift:90`)
- `"iCloud.com.withershins.stash"` → `AppConstants.CloudKit.containerIdentifier` (`PersistenceController.swift:104`)
- `100` (maxCacheSize) → `AppConstants.Classification.maxCacheSize` (`ClassificationService.swift:65`)
- `.prefix(50)` → `.prefix(AppConstants.Classification.recentThoughtsLimit)` (`ConversationService.swift:162`)
- `.prefix(3)` → `.prefix(AppConstants.Classification.maxSuggestionCount)` (`ConversationService.swift:265`)

---

#### Task 1.2 — Create `ConcurrencyUtilities.swift`
**New file:** `Sources/Utilities/ConcurrencyUtilities.swift`

Three files each define their own `withTimeout` function. Extract to one canonical implementation.

```swift
enum ConcurrencyUtilities {
    /// Returns nil if the operation does not complete within the timeout.
    static func withTimeout<T: Sendable>(
        _ timeout: TimeInterval,
        operation: @Sendable @escaping () async -> T
    ) async -> T?

    /// Returns `defaultValue` if the operation does not complete within the timeout.
    static func withTimeout<T: Sendable>(
        _ timeout: TimeInterval,
        default defaultValue: T,
        operation: @Sendable @escaping () async -> T
    ) async -> T
}
```

**Remove private implementations from:**
- `ClassificationService.swift` — `withTimeoutOrThrow` (Lines 552–572) → replace calls with `ConcurrencyUtilities.withTimeout`
- `ContextService.swift` — both `withTimeout` overloads (Lines 286–329) → replace calls with `ConcurrencyUtilities.withTimeout`

Verify call sites still compile. Behaviour is identical.

---

#### Task 1.3 — Create `DateFormatters.swift`
**New file:** `Sources/Utilities/DateFormatters.swift`

`DateFormatter` is expensive to instantiate. It's currently being created fresh on each call in at least `ConversationService.swift` and `CompanionConversationService.swift`.

```swift
enum DateFormatters {
    /// "Jan 5, 2026 at 3:00 PM" — used in thought context summaries
    static let mediumDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    /// "Jan 5, 2026" — used in date-only contexts
    static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
```

**Replace inline `DateFormatter()` constructions in:**
- `ConversationService.swift` (Lines 273–276, 292–296)
- `CompanionConversationService.swift` (Lines 256–261)
- Any other service where `DateFormatter()` appears

---

#### Task 1.4 — Create `ClassificationPatterns.swift`
**New file:** `Sources/Services/Intelligence/ClassificationPatterns.swift`

Consolidates 6 scattered keyword arrays in `ClassificationService.swift`. Eliminates overlaps between `reminderPatterns` and `highSignalReminders` etc.

```swift
/// All keyword patterns used for NLP-based thought classification.
/// Single source of truth — edit here, not in ClassificationService.
enum ClassificationPatterns {

    enum Reminder {
        static let highSignal: [String] = ["remind me", "don't forget", "remember to"]
        static let general: [String] = [
            "need to", "have to", "should", "must", "got to", "gotta",
            "pick up", "buy", "call", "email", "schedule", "book", ...
        ]
        static var all: [String] { highSignal + general }
    }

    enum Event {
        static let highSignal: [String] = ["meeting at", "appointment", "call at", "dinner at"]
        static let general: [String] = [
            "tomorrow", "next week", "on monday", "at noon", ...
        ]
        static var all: [String] { highSignal + general }
    }

    enum Idea {
        static let highSignal: [String] = ["what if", "idea:", "concept:"]
        static let general: [String] = [
            "maybe we could", "what about", "imagine if", ...
        ]
        static var all: [String] { highSignal + general }
    }

    enum Emotion {
        /// Markers indicating genuine emotional distress (used for urgency detection)
        static let negativeMarkers: [String] = [
            "stressed", "anxious", "worried", "scared",
            "hate", "dread", "dreading", "overwhelmed",
            "terrible", "awful"
        ]
    }
}
```

**After creating:** Replace all inline arrays in `ClassificationService.swift` with references to `ClassificationPatterns.*`. Remove the inline declarations.

---

#### Task 1.5 — Create `AppLogger.swift`
**New file:** `Sources/Utilities/AppLogger.swift`

Replace scattered `NSLog` and `print` calls with a single structured logging utility backed by `os_log`.

```swift
import os.log

/// Structured application logger. Use instead of print() or NSLog().
enum AppLogger {

    enum Category: String {
        case classification = "Classification"
        case conversation   = "Conversation"
        case context        = "Context"
        case location       = "Location"
        case sync           = "Sync"
        case persistence    = "Persistence"
        case analytics      = "Analytics"
        case gamification   = "Gamification"
        case general        = "General"
    }

    static func debug(_ message: String, category: Category = .general) { ... }
    static func info(_ message: String, category: Category = .general) { ... }
    static func warning(_ message: String, category: Category = .general) { ... }
    static func error(_ message: String, category: Category = .general) { ... }
}
```

Implementation uses `OSLog` with subsystem `com.withershins.stash`. In `#DEBUG` builds include file/line context. In release builds omit verbose detail.

**Migration order (lowest disruption first):**
1. `LocationService.swift` — 16 NSLog calls, all use `"📍 LocationService"` prefix → `AppLogger.debug(..., category: .location)`
2. `ClassificationService.swift` — 3 NSLog calls → `AppLogger.info/warning(..., category: .classification)`
3. All remaining `print(...)` calls throughout `Sources/` — replace with appropriate `AppLogger` level

**Rule after migration:** `print()` and `NSLog()` are banned in source (add Swiftlint rule if Swiftlint is in use).

---

### Wave 2 — Decompose Monolith Functions (Medium Risk)
Existing files modified. Each function split is a separate commit.

---

#### Task 2.1 — Decompose `ContextService.gatherContextWithDiagnostics()` (151 lines → ~6 focused functions)

**File:** `Sources/Services/Orchestration/ContextService.swift`

This is the highest-priority decomposition in the codebase. The function manages 5 parallel gathering operations, timeout wrapping, metric assembly, and diagnostic packaging all in one body.

**Split into:**

```swift
// Private helpers within ContextService actor

private func gatherLocation(timeout: TimeInterval) async -> LocationContext?
// Wraps locationService call + timeout. Returns nil on failure or timeout.

private func gatherHealthMetrics(timeout: TimeInterval) async -> HealthContext?
// Wraps healthKitService call + timeout.

private func gatherActivity(timeout: TimeInterval) async -> ActivityContext?
// Wraps activityService call + timeout.

private func gatherCalendarEvents(timeout: TimeInterval) async -> CalendarContext?
// Wraps eventKitService call + timeout.

private func assembleContextComponents(
    location: LocationContext?,
    health: HealthContext?,
    activity: ActivityContext?,
    calendar: CalendarContext?,
    diagnostics: ContextDiagnostics
) -> Context
// Pure assembly function — takes gathered results, returns Context struct.

private func recordDiagnostics(
    componentName: String,
    duration: TimeInterval,
    timedOut: Bool,
    into diagnostics: inout ContextDiagnostics
)
// Encapsulates the repeated timing + append pattern.
```

`gatherContextWithDiagnostics()` becomes:

```swift
func gatherContextWithDiagnostics() async -> (Context, ContextDiagnostics) {
    var diagnostics = ContextDiagnostics()
    async let location = gatherLocation(timeout: ...)
    async let health = gatherHealthMetrics(timeout: ...)
    async let activity = gatherActivity(timeout: ...)
    async let calendar = gatherCalendarEvents(timeout: ...)
    let (loc, hlt, act, cal) = await (location, health, activity, calendar)
    return assembleContextComponents(location: loc, health: hlt, activity: act, calendar: cal, diagnostics: diagnostics)
}
```

---

#### Task 2.2 — Decompose `ClassificationService.performClassification(_:)` (93 lines → ~4 focused functions)

**File:** `Sources/Services/Intelligence/ClassificationService.swift`

**Split into:**

```swift
private func classifyViaFoundationModels(_ content: String) async -> Classification?
// Isolates the FM path. Returns nil if FM unavailable or fails.

private func classifyViaNLPHeuristics(_ content: String, entities: [Entity]) async -> Classification
// The fallback NLP path. Never returns nil — always produces a classification.

private func applySentimentPostProcessing(_ classification: inout Classification, content: String) async
// Mutates classification to incorporate sentiment scoring.

private func applyBiasCorrection(_ classification: inout Classification) async
// Reads ClassificationBiasStore, applies any learned corrections.
```

`performClassification` becomes a coordinator:

```swift
func performClassification(_ content: String) async throws -> Classification {
    if let fmResult = await classifyViaFoundationModels(content) {
        var result = fmResult
        await applySentimentPostProcessing(&result, content: content)
        await applyBiasCorrection(&result)
        return result
    }
    let entities = await nlpService.extractEntities(content)
    var result = await classifyViaNLPHeuristics(content, entities: entities)
    await applySentimentPostProcessing(&result, content: content)
    await applyBiasCorrection(&result)
    return result
}
```

---

#### Task 2.3 — Decompose `ConversationService.buildThoughtContext()` (42 lines → 3 focused functions)

**File:** `Sources/Services/AI/ConversationService.swift`

**Split into:**

```swift
private func fetchRecentThoughts(limit: Int) async -> [Thought]
// Fetches and returns the most recent N thoughts.

private func computeThoughtStatistics(_ thoughts: [Thought]) -> ThoughtStatistics
// Pure function: calculates date range, top tags, entry count.

private func formatThoughtContextSummary(_ thoughts: [Thought], statistics: ThoughtStatistics) -> String
// Pure function: builds the prompt-ready text block.
```

`buildThoughtContext()` delegates to all three.

---

#### Task 2.4 — Decompose `CompanionConversationService.sendMessage(_:)` (62 lines → 3 focused functions)

**File:** `Sources/Services/AI/CompanionConversationService.swift`

**Split into:**

```swift
private func sendPrivateMessage(_ message: String) async throws -> ConversationResponse
// Offline/private path only.

private func sendConnectedMessage(_ message: String) async throws -> ConversationResponse
// Connected/backend path only.

private func generateCitations(from thoughts: [Thought]) -> [Citation]
// Pure function: maps Thought array to Citation array.
```

`sendMessage` becomes a dispatcher:

```swift
func sendMessage(_ message: String) async throws -> ConversationResponse {
    switch conversationMode {
    case .private: return try await sendPrivateMessage(message)
    case .connected: return try await sendConnectedMessage(message)
    }
}
```

---

#### Task 2.5 — Decompose `STASHApp.MainTabView.body` (87 lines → 4 tab views + 1 coordinator)

**Files affected:** `Sources/STASHApp.swift` (or wherever `MainTabView` lives)

**Extract tab definitions:**

```swift
// New private view types within the same file (no new file needed)
private struct BrowseTab: View { ... }
private struct SearchTab: View { ... }
private struct InsightsTab: View { ... }
private struct SettingsTab: View { ... }
```

**Move voice capture overlay** into its own `VoiceCaptureOverlay` view. It's currently inline in the body.

`MainTabView.body` becomes:

```swift
var body: some View {
    TabView(selection: $selectedTab) {
        BrowseTab()
            .tabItem { ... }
            .tag(Tab.browse)
        SearchTab()
            .tabItem { ... }
            .tag(Tab.search)
        InsightsTab()
            .tabItem { ... }
            .tag(Tab.insights)
        SettingsTab()
            .tabItem { ... }
            .tag(Tab.settings)
    }
    .overlay(VoiceCaptureOverlay(...))
}
```

---

### Wave 3 — Naming Standardization (Low Risk, High Value)
Pure renames. Swift compiler catches all missed call sites.

---

#### Task 3.1 — Standardize Parameter Labels

**`SyncService.enqueue(...)` — add parameter labels:**

Current:
```swift
func enqueue(_ entity: SyncEntity, _ entityId: UUID, _ action: SyncAction, _ payload: Data?)
```

Corrected:
```swift
func enqueue(entity: SyncEntity, entityId: UUID, action: SyncAction, payload: Data?)
```

Update all call sites (compiler will flag every one).

---

#### Task 3.2 — Fix Typo in `ContextService`

`timeedOut` → `timedOut` (appears at Lines 160, 182). Two-character fix but worth catching before it spreads.

---

#### Task 3.3 — Consistent Callback Naming

In `SyncedDefaults.swift`:
- `didChangeExternally` (property) vs `DidChangeExternally` (Notification.Name)

Swift convention:
- Properties: `camelCase` — `didChangeExternally` is correct
- Notification names: use static extension on `Notification.Name` — `static let didChangeExternally = Notification.Name("SyncedDefaultsDidChangeExternally")`

Rename the `Notification.Name` entry to lowercase `didChangeExternally` to match the property.

---

#### Task 3.4 — Boolean Predicate Naming Audit

Find all `var is*`, `var has*`, `var can*` booleans and verify they read naturally in an `if` statement. Rename any that don't.

Examples to check:
- `_isSyncing` backing field (SyncService.swift:87) — internal backing fields should use the same name as the published property, marked `private(set)`: `private(set) var isSyncing: Bool`

---

### Wave 4 — Concurrency Model Audit (Higher Risk, Targeted)
Do not blanket-convert everything. Address only the confirmed-unsafe cases.

---

#### Task 4.1 — Audit and Document `@unchecked Sendable` Declarations

For each of the 7 `@unchecked Sendable` types, add a documentation comment above the declaration explaining exactly why it is safe:

```swift
// Thread safety: all mutation occurs via UserDefaults.standard which is thread-safe.
// NSUbiquitousKeyValueStore is thread-safe by Apple documentation.
// No additional locking required.
final class SyncedDefaults: @unchecked Sendable { ... }
```

If you cannot write a truthful explanation, the `@unchecked` must be removed and replaced with a proper `actor` or `@MainActor`.

**Specific cases requiring actor conversion (not just a comment):**
- `AnalyticsService` — mutable state accessed from multiple contexts; convert to `actor`
- `NotificationDelegate` in `STASHApp.swift` — `@Published openCapture` on a class marked `@unchecked Sendable`; convert to `@MainActor` class

---

#### Task 4.2 — Replace `DispatchQueue.main.async` with `MainActor`

**`STASHApp.swift:259`:**

```swift
// Before:
DispatchQueue.main.async { self.openCapture = true }

// After:
await MainActor.run { self.openCapture = true }
```

Or annotate the calling function `@MainActor` so the assignment is always on the main actor.

---

### Wave 5 — Error Handling Standardization (Architecture Change, Do Last)

This wave requires the most judgment. Document the decision in `DECISIONS.md` before implementing.

---

#### Task 5.1 — Define Error Handling Policy

Write the policy to `DECISIONS.md` first. Proposed policy:

| Layer | Pattern | Rationale |
|---|---|---|
| Service public APIs | `throws` with typed `ServiceError` | Callers must handle or propagate |
| Internal helpers | `throws` or return `nil` if nil = "not found" | Don't throw for absence |
| View Models | Catch + publish `errorState: Error?` | UI layer handles display |
| Background work | `try?` only when failure is intentionally silent | Must comment explaining why |

#### Task 5.2 — Apply Policy to Top Violators

After policy is decided, audit these files for misuse:
1. `ClassificationService.swift` — several `try?` where failure should be logged
2. `ConversationService.swift` — validate error propagation from Foundation Models
3. `SyncService.swift` — confirm retry logic sees errors that are currently swallowed

---

## Execution Sequence

```
Wave 1 (infrastructure extraction) — 5 tasks, all independently committable
  1.1 AppConstants.swift
  1.2 ConcurrencyUtilities.swift
  1.3 DateFormatters.swift
  1.4 ClassificationPatterns.swift
  1.5 AppLogger.swift

Wave 2 (function decomposition) — 5 tasks, each on its own commit
  2.1 ContextService.gatherContextWithDiagnostics
  2.2 ClassificationService.performClassification
  2.3 ConversationService.buildThoughtContext
  2.4 CompanionConversationService.sendMessage
  2.5 STASHApp.MainTabView.body

Wave 3 (naming) — 4 tasks, quick wins
  3.1 SyncService parameter labels
  3.2 timedOut typo
  3.3 Notification.Name casing
  3.4 Boolean predicate naming audit

Wave 4 (concurrency) — targeted, surgical
  4.1 @unchecked Sendable documentation + actor conversions
  4.2 DispatchQueue.main.async → MainActor

Wave 5 (error handling) — requires policy decision first
  5.1 Write policy to DECISIONS.md
  5.2 Apply to top violators
```

---

## Definition of Done

- [ ] Each Wave 1 task: new file exists, old code updated to use it, no duplicate logic remains
- [ ] Each Wave 2 task: original function is a short coordinator (<15 lines), helpers are <40 lines each
- [ ] Wave 3: Xcode builds with zero warnings; no renamed symbol has unresolved call sites
- [ ] Wave 4: every `@unchecked Sendable` has a truthful comment or has been converted
- [ ] Wave 5: policy documented in DECISIONS.md, top-3 violators corrected
- [ ] All tasks: app builds without warnings, no behavior change

---

## Files Not to Touch

These are well-designed and should not be refactored:
- `ServiceContainer.swift` — clean DI implementation
- `AcornService.swift` — well-scoped, readable
- `SyncService.swift` — clean, correct, mock belongs in test target
- `PersistenceController.swift` — fatalErrors are appropriate (config/preview errors)
