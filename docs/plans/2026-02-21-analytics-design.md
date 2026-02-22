# Analytics Integration Design
**Date:** 2026-02-21
**Provider:** TelemetryDeck
**App ID:** 9893DF09-028C-4E41-84A6-2191465CC1EC
**Namespace:** us.withershins
**Status:** Approved — ready for implementation

---

## Goals

- Understand which features are used and how often
- Track error rates to surface reliability problems
- Maintain user trust: zero personal data leaves the device
- Keep future flexibility: event level adjustable with minimal code changes

---

## Architecture

Two new files. All other files only add `track()` call sites.

### `AnalyticsEvent.swift`
A typed enum listing every trackable event. Each case computes:
- `signalName: String` — the TelemetryDeck signal name sent over the wire
- `metadata: [String: String]` — non-personal parameters (e.g. `["method": "voice"]`)

Adding, removing, or adjusting granularity is a single-file change here.

### `AnalyticsService.swift`
Lightweight singleton. Responsibilities:
- Initialize TelemetryDeck SDK in `STASHApp.init()`
- Expose `isOptedOut: Bool` (backed by `UserDefaults` key `"analytics.optOut"`)
- Single `track(_ event: AnalyticsEvent)` method — opt-out check lives here only

Call sites throughout the app:
```swift
AnalyticsService.shared.track(.thoughtCaptured(method: .voice))
```

---

## Event Taxonomy

### Screen Events
Fired on `.onAppear` of each major screen's root view.

| Signal Name | Metadata |
|---|---|
| `screenViewed` | `screen`: browse, search, insights, settings, achievements, detail, capture |

### Feature Events
Fired at moment of completion (not intent).

| Signal Name | Metadata |
|---|---|
| `thoughtCaptured` | `method`: text or voice |
| `thoughtDeleted` | — |
| `thoughtArchived` | — |
| `classificationOverridden` | `from`: original type, `to`: new type |
| `searchPerformed` | `resultCount`: number of results |
| `aiInsightsGenerated` | — |
| `shinyPromoted` | `count`: how many promoted |
| `shinySurfaced` | — |
| `acornEarned` | `amount`: acorn count |
| `acornSpent` | `amount`: acorn count |
| `badgeUnlocked` | `badgeId`: badge identifier |
| `achievementEarned` | `achievementId`: achievement identifier |
| `themeChanged` | `theme`: theme name |
| `personaSelected` | `persona`: persona type |
| `onboardingCompleted` | `stepsCompleted`: count |
| `onboardingAbandoned` | `atStep`: step number |
| `siriShortcutUsed` | `intent`: capture or search |

### Error Events
Fired on existing failure paths.

| Signal Name | Metadata |
|---|---|
| `classificationFailed` | — |
| `aiUnavailable` | — |
| `searchZeroResults` | — |
| `contextEnrichmentFailed` | `component`: location, healthkit, or calendar |

---

## Privacy & Settings Integration

### Privacy Statement (replaces existing single-line text in Settings → Privacy section)
> STASH collects anonymous metadata about how app features are used — for example, which screens you visit and whether you use voice or text capture. No thought content, tags, health data, or personal information ever leaves your device. This telemetry is used solely to understand which features are working well and where the app can improve.

### Opt-out Toggle
- Label: "Share anonymous usage data"
- Default: **on** (opted in)
- `UserDefaults` key: `"analytics.optOut"` (false = opted in, true = opted out)
- Takes effect immediately — no restart required
- When toggled off, shows note: "Usage data will no longer be collected."

---

## Instrumentation Points

### Screen Views
`.onAppear` on root view of: `BrowseScreen`, `SearchScreen`, `InsightsScreen`, `SettingsScreen`, `AchievementsScreen`, `DetailScreen`, `CaptureScreen`

### Feature Events

| Event | File | Location |
|---|---|---|
| `thoughtCaptured` | `CaptureViewModel.swift` | After successful save in `captureThought()` |
| `thoughtDeleted` | `BrowseViewModel.swift`, `DetailViewModel.swift` | Delete action completion |
| `thoughtArchived` | `BrowseViewModel.swift` | `archiveThought()` + bulk archive completion |
| `classificationOverridden` | `DetailViewModel.swift` | Classification override action |
| `searchPerformed` / `searchZeroResults` | `SearchViewModel.swift` | After results load |
| `aiInsightsGenerated` | `InsightsViewModel.swift` | `loadAIInsights()` on success |
| `shinyPromoted` | `ShinyService.swift` | After `promoted` array populated |
| `shinySurfaced` | `BrowseViewModel.swift` | When `todaysShiny` is set |
| `acornEarned` / `acornSpent` | `AcornLedger.swift` | Credit/debit methods |
| `badgeUnlocked` | `BadgeService.swift` | When badge newly earned |
| `themeChanged` | `ThemeEngine.swift` | On theme update |
| `personaSelected` | `OnboardingViewModel.swift`, `PersonalizationScreen.swift` | Selection confirmed |
| `onboardingCompleted` | `OnboardingViewModel.swift` | `onComplete` closure |
| `siriShortcutUsed` | `CaptureThoughtIntent.swift`, `SearchThoughtsIntent.swift` | `perform()` entry |

### Error Events

| Event | File | Location |
|---|---|---|
| `classificationFailed` | `ClassificationService.swift` | Catch block |
| `aiUnavailable` | `FoundationModelsClassifier.swift` | Availability check failure |
| `searchZeroResults` | `SearchViewModel.swift` | When result count is zero |
| `contextEnrichmentFailed` | `ContextEnrichmentService.swift` | Per-component catch blocks |

---

## Privacy Constraints

- **Never** include thought content, tags, or excerpts in any event metadata
- **Never** include HealthKit values (Apple policy prohibits third-party sharing)
- **Never** include location coordinates or names
- **Never** include user identifiers or device fingerprints
- TelemetryDeck handles anonymization server-side; no raw IPs or device IDs stored

---

## Future Flexibility

- To reduce granularity: delete cases from `AnalyticsEvent` and remove call sites
- To increase granularity: add cases to `AnalyticsEvent` and add call sites
- To swap providers: update `AnalyticsService.track()` only — all call sites unchanged
