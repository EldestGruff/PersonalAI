# Analytics Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate TelemetryDeck anonymous usage analytics with a typed event enum, opt-out toggle, and instrumentation across all key user actions.

**Architecture:** A single `AnalyticsEvent` enum defines every trackable event (signal name + metadata). `AnalyticsService.shared.track()` checks opt-out and forwards to TelemetryDeck. All other files only add `track()` call sites.

**Tech Stack:** TelemetryDeck Swift SDK (SPM), UserDefaults for opt-out flag, existing SwiftUI/service architecture.

**Design doc:** `docs/plans/2026-02-21-analytics-design.md`

---

## Setup

```bash
git checkout -b feature/analytics
```

---

### Task 1: Add TelemetryDeck Swift Package

**Files:**
- Modify: `PersonalAI.xcodeproj` (via Xcode UI)

**Step 1: Add the package in Xcode**

In Xcode: File → Add Package Dependencies...

Enter URL: `https://github.com/TelemetryDeck/SwiftSDK`

Select version: Up to Next Major from `2.0.0`

Click Add Package, then add `TelemetryDeck` library to the `PersonalAI` target.

**Step 2: Verify it builds**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
git add PersonalAI.xcodeproj
git commit -m "Add TelemetryDeck Swift SDK via SPM"
```

---

### Task 2: Create AnalyticsEvent enum with tests

**Files:**
- Create: `Sources/Analytics/AnalyticsEvent.swift`
- Create: `Tests/Unit/AnalyticsEventTests.swift`

**Step 1: Write the failing tests**

Create `Tests/Unit/AnalyticsEventTests.swift`:

```swift
//
//  AnalyticsEventTests.swift
//  STASH
//

import XCTest
@testable import PersonalAI

final class AnalyticsEventTests: XCTestCase {

    // MARK: - Signal Names

    func test_screenViewed_signalName() {
        XCTAssertEqual(AnalyticsEvent.screenViewed(.browse).signalName, "screenViewed")
    }

    func test_thoughtCaptured_signalName() {
        XCTAssertEqual(AnalyticsEvent.thoughtCaptured(method: .text).signalName, "thoughtCaptured")
    }

    func test_shinyPromoted_signalName() {
        XCTAssertEqual(AnalyticsEvent.shinyPromoted(count: 1).signalName, "shinyPromoted")
    }

    func test_contextEnrichmentFailed_signalName() {
        XCTAssertEqual(
            AnalyticsEvent.contextEnrichmentFailed(component: .healthKit).signalName,
            "contextEnrichmentFailed"
        )
    }

    // MARK: - Metadata

    func test_screenViewed_metadata_containsScreen() {
        let event = AnalyticsEvent.screenViewed(.insights)
        XCTAssertEqual(event.metadata["screen"], "insights")
    }

    func test_thoughtCaptured_voice_metadata() {
        let event = AnalyticsEvent.thoughtCaptured(method: .voice)
        XCTAssertEqual(event.metadata["method"], "voice")
    }

    func test_thoughtCaptured_text_metadata() {
        let event = AnalyticsEvent.thoughtCaptured(method: .text)
        XCTAssertEqual(event.metadata["method"], "text")
    }

    func test_classificationOverridden_metadata() {
        let event = AnalyticsEvent.classificationOverridden(from: "note", to: "reminder")
        XCTAssertEqual(event.metadata["from"], "note")
        XCTAssertEqual(event.metadata["to"], "reminder")
    }

    func test_searchPerformed_metadata() {
        let event = AnalyticsEvent.searchPerformed(resultCount: 7)
        XCTAssertEqual(event.metadata["resultCount"], "7")
    }

    func test_shinyPromoted_metadata() {
        let event = AnalyticsEvent.shinyPromoted(count: 3)
        XCTAssertEqual(event.metadata["count"], "3")
    }

    func test_acornEarned_metadata() {
        let event = AnalyticsEvent.acornEarned(amount: 10)
        XCTAssertEqual(event.metadata["amount"], "10")
    }

    func test_contextEnrichmentFailed_healthKit_metadata() {
        let event = AnalyticsEvent.contextEnrichmentFailed(component: .healthKit)
        XCTAssertEqual(event.metadata["component"], "healthkit")
    }

    func test_contextEnrichmentFailed_location_metadata() {
        let event = AnalyticsEvent.contextEnrichmentFailed(component: .location)
        XCTAssertEqual(event.metadata["component"], "location")
    }

    func test_onboardingCompleted_metadata() {
        let event = AnalyticsEvent.onboardingCompleted(stepsCompleted: 6)
        XCTAssertEqual(event.metadata["stepsCompleted"], "6")
    }

    // MARK: - Privacy: no personal data in metadata

    func test_noPersonalDataLeaks() {
        let events: [AnalyticsEvent] = [
            .thoughtCaptured(method: .text),
            .thoughtDeleted,
            .thoughtArchived,
            .searchZeroResults,
            .aiInsightsGenerated,
            .shinySurfaced,
            .classificationFailed,
            .aiUnavailable,
        ]
        let forbidden = ["content", "tags", "query", "text", "location", "health"]
        for event in events {
            for key in forbidden {
                XCTAssertNil(event.metadata[key], "\(event.signalName) leaks '\(key)'")
            }
        }
    }

    // MARK: - Zero-metadata events

    func test_thoughtDeleted_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.thoughtDeleted.metadata.isEmpty)
    }

    func test_classificationFailed_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.classificationFailed.metadata.isEmpty)
    }
}
```

**Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:PersonalAITests/AnalyticsEventTests 2>&1 | tail -10
```

Expected: compile error — `AnalyticsEvent` not found.

**Step 3: Create `Sources/Analytics/AnalyticsEvent.swift`**

```swift
//
//  AnalyticsEvent.swift
//  STASH
//
//  All trackable analytics events in one place.
//  To adjust granularity: add, remove, or rename cases here.
//  Call sites use: AnalyticsService.shared.track(.caseName)
//

import Foundation

enum AnalyticsEvent {

    // MARK: - Screen Events

    case screenViewed(Screen)

    // MARK: - Capture Events

    case thoughtCaptured(method: CaptureMethod)
    case thoughtDeleted
    case thoughtArchived
    case classificationOverridden(from: String, to: String)

    // MARK: - Search Events

    case searchPerformed(resultCount: Int)
    case searchZeroResults

    // MARK: - Insights Events

    case aiInsightsGenerated

    // MARK: - Gamification Events

    case shinyPromoted(count: Int)
    case shinySurfaced
    case acornEarned(amount: Int)
    case acornSpent(amount: Int)
    case badgeUnlocked(badgeId: String)
    case achievementEarned(achievementId: String)

    // MARK: - Personalization Events

    case themeChanged(theme: String)
    case personaSelected(persona: String)

    // MARK: - Lifecycle Events

    case onboardingCompleted(stepsCompleted: Int)
    case onboardingAbandoned(atStep: Int)
    case siriShortcutUsed(intent: String)

    // MARK: - Error Events

    case classificationFailed
    case aiUnavailable
    case contextEnrichmentFailed(component: ContextComponent)

    // MARK: - Supporting Types

    enum Screen: String {
        case browse, search, insights, settings, achievements, detail, capture
    }

    enum CaptureMethod: String {
        case text, voice
    }

    enum ContextComponent: String {
        case location
        case healthKit = "healthkit"
        case calendar
    }

    // MARK: - Signal Name

    var signalName: String {
        switch self {
        case .screenViewed:              return "screenViewed"
        case .thoughtCaptured:           return "thoughtCaptured"
        case .thoughtDeleted:            return "thoughtDeleted"
        case .thoughtArchived:           return "thoughtArchived"
        case .classificationOverridden:  return "classificationOverridden"
        case .searchPerformed:           return "searchPerformed"
        case .searchZeroResults:         return "searchZeroResults"
        case .aiInsightsGenerated:       return "aiInsightsGenerated"
        case .shinyPromoted:             return "shinyPromoted"
        case .shinySurfaced:             return "shinySurfaced"
        case .acornEarned:               return "acornEarned"
        case .acornSpent:                return "acornSpent"
        case .badgeUnlocked:             return "badgeUnlocked"
        case .achievementEarned:         return "achievementEarned"
        case .themeChanged:              return "themeChanged"
        case .personaSelected:           return "personaSelected"
        case .onboardingCompleted:       return "onboardingCompleted"
        case .onboardingAbandoned:       return "onboardingAbandoned"
        case .siriShortcutUsed:          return "siriShortcutUsed"
        case .classificationFailed:      return "classificationFailed"
        case .aiUnavailable:             return "aiUnavailable"
        case .contextEnrichmentFailed:   return "contextEnrichmentFailed"
        }
    }

    // MARK: - Metadata (non-personal only)

    var metadata: [String: String] {
        switch self {
        case .screenViewed(let screen):
            return ["screen": screen.rawValue]
        case .thoughtCaptured(let method):
            return ["method": method.rawValue]
        case .classificationOverridden(let from, let to):
            return ["from": from, "to": to]
        case .searchPerformed(let resultCount):
            return ["resultCount": String(resultCount)]
        case .shinyPromoted(let count):
            return ["count": String(count)]
        case .acornEarned(let amount):
            return ["amount": String(amount)]
        case .acornSpent(let amount):
            return ["amount": String(amount)]
        case .badgeUnlocked(let badgeId):
            return ["badgeId": badgeId]
        case .achievementEarned(let achievementId):
            return ["achievementId": achievementId]
        case .themeChanged(let theme):
            return ["theme": theme]
        case .personaSelected(let persona):
            return ["persona": persona]
        case .onboardingCompleted(let stepsCompleted):
            return ["stepsCompleted": String(stepsCompleted)]
        case .onboardingAbandoned(let atStep):
            return ["atStep": String(atStep)]
        case .siriShortcutUsed(let intent):
            return ["intent": intent]
        case .contextEnrichmentFailed(let component):
            return ["component": component.rawValue]
        case .thoughtDeleted, .thoughtArchived, .searchZeroResults,
             .aiInsightsGenerated, .shinySurfaced, .classificationFailed,
             .aiUnavailable:
            return [:]
        }
    }
}
```

**Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:PersonalAITests/AnalyticsEventTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

**Step 5: Commit**

```bash
git add Sources/Analytics/AnalyticsEvent.swift Tests/Unit/AnalyticsEventTests.swift
git commit -m "Add AnalyticsEvent enum with privacy-safe metadata"
```

---

### Task 3: Create AnalyticsService with tests

**Files:**
- Create: `Sources/Analytics/AnalyticsService.swift`
- Create: `Tests/Unit/AnalyticsServiceTests.swift`

**Step 1: Write failing tests**

Create `Tests/Unit/AnalyticsServiceTests.swift`:

```swift
//
//  AnalyticsServiceTests.swift
//  STASH
//

import XCTest
@testable import PersonalAI

final class AnalyticsServiceTests: XCTestCase {

    private let optOutKey = "analytics.optOut"
    private var service: AnalyticsService { .shared }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: optOutKey)
    }

    func test_isOptedOut_defaultsFalse() {
        UserDefaults.standard.removeObject(forKey: optOutKey)
        XCTAssertFalse(service.isOptedOut)
    }

    func test_setOptedOut_true_persists() {
        service.isOptedOut = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func test_setOptedOut_false_persists() {
        service.isOptedOut = true
        service.isOptedOut = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func test_isOptedOut_reflectsUserDefaults() {
        UserDefaults.standard.set(true, forKey: optOutKey)
        XCTAssertTrue(service.isOptedOut)

        UserDefaults.standard.set(false, forKey: optOutKey)
        XCTAssertFalse(service.isOptedOut)
    }
}
```

**Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:PersonalAITests/AnalyticsServiceTests 2>&1 | tail -10
```

Expected: compile error — `AnalyticsService` not found.

**Step 3: Create `Sources/Analytics/AnalyticsService.swift`**

```swift
//
//  AnalyticsService.swift
//  STASH
//
//  Wraps TelemetryDeck. All opt-out logic lives here.
//  To swap analytics providers: update track() only.
//

import Foundation
import TelemetryDeck

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    private let optOutKey = "analytics.optOut"

    var isOptedOut: Bool {
        get { UserDefaults.standard.bool(forKey: optOutKey) }
        set { UserDefaults.standard.set(newValue, forKey: optOutKey) }
    }

    func initialize() {
        let config = TelemetryDeckConfiguration(appID: "9893DF09-028C-4E41-84A6-2191465CC1EC")
        TelemetryDeck.initialize(config: config)
    }

    func track(_ event: AnalyticsEvent) {
        guard !isOptedOut else { return }
        TelemetryDeck.signal(event.signalName, parameters: event.metadata)
    }
}
```

**Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:PersonalAITests/AnalyticsServiceTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

**Step 5: Commit**

```bash
git add Sources/Analytics/AnalyticsService.swift Tests/Unit/AnalyticsServiceTests.swift
git commit -m "Add AnalyticsService with opt-out support"
```

---

### Task 4: Initialize analytics in STASHApp

**Files:**
- Modify: `Sources/STASHApp.swift` (around line 37–48, the `init()` block)

**Step 1: Add initialization call**

In `STASHApp.init()`, after the existing App Shortcuts registration lines, add:

```swift
// Initialize analytics (respects user opt-out from UserDefaults)
AnalyticsService.shared.initialize()
```

The full `init()` block should look like:

```swift
init() {
    // Register App Shortcuts for Siri integration
    print("🎯 Registering \(ThoughtAppShortcuts.appShortcuts.count) App Shortcuts...")
    ThoughtAppShortcuts.updateAppShortcutParameters()
    print("✅ App Shortcuts registration complete")

    // Register notification delegate for deep link handling
    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

    // Initialize analytics (respects user opt-out from UserDefaults)
    AnalyticsService.shared.initialize()

    // Check if onboarding should be shown
    let hasCompleted = OnboardingViewModel.hasCompletedOnboarding()
    self._showOnboarding = State(initialValue: !hasCompleted)
}
```

**Step 2: Build to verify**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
git add Sources/STASHApp.swift
git commit -m "Initialize TelemetryDeck analytics on app launch"
```

---

### Task 5: Add opt-out toggle and privacy statement to Settings

**Files:**
- Modify: `Sources/UI/Screens/SettingsScreen.swift` (around line 752, `PrivacyInfoView`)

**Step 1: Update `PrivacyInfoView`**

Add a `@State` property for the toggle and insert a new "Usage Analytics" section. Replace the body of `PrivacyInfoView.body` with:

```swift
var body: some View {
    let theme = themeEngine.getCurrentTheme()
    ZStack {
        theme.backgroundColor
            .ignoresSafeArea()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Information")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.textColor)

                Text("Personal AI is designed with privacy first.")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                // MARK: - Usage Analytics (new section)
                Group {
                    Text("Usage Analytics")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)

                    Text("STASH collects anonymous metadata about how app features are used — for example, which screens you visit and whether you use voice or text capture. No thought content, tags, health data, or personal information ever leaves your device. This telemetry is used solely to understand which features are working well and where the app can improve.")
                        .foregroundStyle(theme.secondaryTextColor)

                    Toggle(isOn: Binding(
                        get: { !AnalyticsService.shared.isOptedOut },
                        set: { AnalyticsService.shared.isOptedOut = !$0 }
                    )) {
                        Text("Share anonymous usage data")
                            .foregroundStyle(theme.textColor)
                    }
                    .themedToggle(theme)

                    if AnalyticsService.shared.isOptedOut {
                        Text("Usage data will no longer be collected.")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }

                // MARK: - Existing sections (unchanged)
                Group {
                    Text("Data Storage")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                    Text("All your thoughts are stored locally on your device using Core Data. No data is sent to external servers in Phase 3A.")
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Group {
                    Text("Permissions")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                    Text("Permissions are used solely to enrich context. Location data, health data, and other information is never shared and only used to provide context for your thoughts.")
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Group {
                    Text("Classification")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                    Text("All classification is done on-device using Apple's Natural Language framework. No thought content is sent to external AI services.")
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Group {
                    Text("Future Updates")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                    Text("Cloud sync (Phase 4+) will use end-to-end encryption. You will always have full control over what data is synced.")
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            .padding()
        }
    }
    .navigationTitle("Privacy")
    .toolbarBackground(theme.surfaceColor, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
}
```

Note: The toggle reads live from `AnalyticsService.shared.isOptedOut` — no local `@State` needed. The `if AnalyticsService.shared.isOptedOut` condition for the confirmation note requires the view to re-render when the toggle changes. Add `.id(AnalyticsService.shared.isOptedOut)` to the outer `VStack` if the note doesn't appear/disappear reactively during testing.

**Step 2: Build to verify**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
git add Sources/UI/Screens/SettingsScreen.swift
git commit -m "Add analytics opt-out toggle and privacy statement to Settings"
```

---

### Task 6: Instrument screen views

**Files:**
- Modify: `Sources/UI/Screens/BrowseScreen.swift`
- Modify: `Sources/UI/Screens/SearchScreen.swift`
- Modify: `Sources/UI/Screens/InsightsScreen.swift`
- Modify: `Sources/UI/Screens/SettingsScreen.swift`
- Modify: `Sources/UI/Screens/AchievementsScreen.swift`
- Modify: `Sources/UI/Screens/DetailScreen.swift`
- Modify: `Sources/UI/Screens/CaptureScreen.swift`

**Step 1: Add `.onAppear` tracking to each screen**

In each screen's root view `body`, add `.onAppear` with the appropriate screen case. Pattern to apply:

```swift
// BrowseScreen — add to the NavigationStack or outermost ZStack:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.browse))
}

// SearchScreen:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.search))
}

// InsightsScreen:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.insights))
}

// SettingsScreen:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.settings))
}

// AchievementsScreen:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.achievements))
}

// DetailScreen:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.detail))
}

// CaptureScreen:
.onAppear {
    AnalyticsService.shared.track(.screenViewed(.capture))
}
```

Add the modifier to the outermost view in each `body` (before or after existing modifiers — order doesn't matter).

**Step 2: Build to verify**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
git add Sources/UI/Screens/
git commit -m "Instrument screen view analytics for all major screens"
```

---

### Task 7: Instrument capture, search, and insights events

**Files:**
- Modify: `Sources/UI/ViewModels/CaptureViewModel.swift` (method `captureThought()`)
- Modify: `Sources/UI/ViewModels/SearchViewModel.swift` (after results load)
- Modify: `Sources/UI/ViewModels/InsightsViewModel.swift` (method `loadAIInsights()`)
- Modify: `Sources/UI/ViewModels/DetailViewModel.swift` (classification override + delete + archive)
- Modify: `Sources/UI/ViewModels/BrowseViewModel.swift` (delete, archive)

**Step 1: CaptureViewModel — `captureThought()`**

Find the successful-save path in `captureThought()`. After the thought is saved successfully, add:

```swift
let captureMethod: AnalyticsEvent.CaptureMethod = isVoiceCapture ? .voice : .text
AnalyticsService.shared.track(.thoughtCaptured(method: captureMethod))
```

`isVoiceCapture` should be an existing property or derivable from how the capture was initiated. If the ViewModel doesn't track capture method, use `.text` as default and add a `isVoiceCapture: Bool` parameter to `captureThought()` or set it from the voice capture entry point.

**Step 2: SearchViewModel — after results load**

Find where `results` is assigned after a search. After setting results:

```swift
if results.isEmpty {
    AnalyticsService.shared.track(.searchZeroResults)
} else {
    AnalyticsService.shared.track(.searchPerformed(resultCount: results.count))
}
```

**Step 3: InsightsViewModel — `loadAIInsights()`**

Find the success path where AI insights are assigned. After successful generation:

```swift
AnalyticsService.shared.track(.aiInsightsGenerated)
```

**Step 4: DetailViewModel — classification override**

Find the method that applies a user's classification override. After saving:

```swift
AnalyticsService.shared.track(.classificationOverridden(
    from: originalType.rawValue,
    to: newType.rawValue
))
```

**Step 5: BrowseViewModel + DetailViewModel — delete and archive**

In `BrowseViewModel.deleteThought()` after successful deletion:
```swift
AnalyticsService.shared.track(.thoughtDeleted)
```

In `BrowseViewModel.archiveThought()` after successful archive:
```swift
AnalyticsService.shared.track(.thoughtArchived)
```

Apply the same two lines to any equivalent methods in `DetailViewModel`.

**Step 6: Build and verify**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 7: Commit**

```bash
git add Sources/UI/ViewModels/
git commit -m "Instrument capture, search, insights, and thought action events"
```

---

### Task 8: Instrument gamification events

**Files:**
- Modify: `Sources/Services/Gamification/ShinyService.swift`
- Modify: `Sources/UI/ViewModels/BrowseViewModel.swift`
- Modify: `Sources/Services/Gamification/AcornService.swift`
- Modify: `Sources/Services/Gamification/BadgeService.swift`

**Step 1: ShinyService — `promoteShiniesIfNeeded()`**

After the `promoted` array is populated and non-empty (around line 103):

```swift
if !promoted.isEmpty {
    AnalyticsService.shared.track(.shinyPromoted(count: promoted.count))
    // ... existing UserDefaults.standard.set call
}
```

**Step 2: BrowseViewModel — `shinySurfaced`**

After `self.todaysShiny = shinies.randomElement()` (line 198), add:

```swift
if todaysShiny != nil {
    AnalyticsService.shared.track(.shinySurfaced)
}
```

**Step 3: AcornLedger — `award()` and `spend()`**

In `AcornService.swift`, inside `fileprivate func award(_ amount: Int)`, after crediting the balance:

```swift
AnalyticsService.shared.track(.acornEarned(amount: amount))
```

Inside `func spend(_ amount: Int) -> Bool`, after the balance is decremented (on the success path, before `return true`):

```swift
AnalyticsService.shared.track(.acornSpent(amount: amount))
```

**Step 4: BadgeService — `award(_ badge:)`**

In `BadgeService.swift`, inside `private func award(_ badge: BadgeDefinition)`, after `recentlyEarnedIds.insert(badge.id)`:

```swift
AnalyticsService.shared.track(.badgeUnlocked(badgeId: badge.id))
```

**Step 5: Build and verify**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 6: Commit**

```bash
git add Sources/Services/Gamification/ Sources/UI/ViewModels/BrowseViewModel.swift
git commit -m "Instrument gamification analytics (shinies, acorns, badges)"
```

---

### Task 9: Instrument lifecycle, personalization, and Siri events

**Files:**
- Modify: `Sources/UI/ViewModels/OnboardingViewModel.swift`
- Modify: `Sources/UI/Theme/ThemeEngine.swift`
- Modify: `Sources/AppIntents/CaptureThoughtIntent.swift`
- Modify: `Sources/AppIntents/SearchThoughtsIntent.swift`

**Step 1: OnboardingViewModel — `completeOnboarding()` and `selectPersona()`**

In `completeOnboarding()` (line 192), add before or after existing logic:

```swift
AnalyticsService.shared.track(.onboardingCompleted(stepsCompleted: currentStepIndex))
```

`currentStepIndex` should reflect how many steps were completed. Use whatever property tracks the current step. If unsure, inspect the step enum and find the count.

In `selectPersona(_ persona:)` (line 136), add:

```swift
AnalyticsService.shared.track(.personaSelected(persona: persona.name))
```

**Step 2: ThemeEngine — `setTheme()`**

In `ThemeEngine.setTheme(_ theme: ThemeType)` (line 36), add after the theme is applied:

```swift
AnalyticsService.shared.track(.themeChanged(theme: theme.rawValue))
```

**Step 3: CaptureThoughtIntent — `perform()`**

At the top of the `perform()` function body (before any logic):

```swift
AnalyticsService.shared.track(.siriShortcutUsed(intent: "capture"))
```

**Step 4: SearchThoughtsIntent — `perform()`**

At the top of the `perform()` function body:

```swift
AnalyticsService.shared.track(.siriShortcutUsed(intent: "search"))
```

**Step 5: Build and verify**

```bash
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

**Step 6: Commit**

```bash
git add Sources/UI/ViewModels/OnboardingViewModel.swift Sources/UI/Theme/ThemeEngine.swift Sources/AppIntents/
git commit -m "Instrument onboarding, theme, persona, and Siri shortcut events"
```

---

### Task 10: Instrument error events and merge

**Files:**
- Modify: `Sources/Services/Intelligence/ClassificationService.swift`
- Modify: `Sources/Services/AI/FoundationModelsClassifier.swift`
- Modify: `Sources/UI/ViewModels/SearchViewModel.swift` (already touched in Task 7)
- Modify: `Sources/Services/Domain/ContextEnrichmentService.swift`

**Step 1: ClassificationService — classification failure**

Find the catch block where classification fails (not retried). Add:

```swift
AnalyticsService.shared.track(.classificationFailed)
```

**Step 2: FoundationModelsClassifier — AI unavailable**

In `setupSession()` or wherever `SystemLanguageModel().availability != .available` is handled:

```swift
AnalyticsService.shared.track(.aiUnavailable)
```

Only fire this once per session, not on every call. Add a guard like:

```swift
private var hasTrackedUnavailable = false

// Inside the unavailability guard:
if !hasTrackedUnavailable {
    AnalyticsService.shared.track(.aiUnavailable)
    hasTrackedUnavailable = true
}
```

**Step 3: ContextEnrichmentService — per-component failures**

Find the catch blocks for each context component. Add the appropriate call:

```swift
// Location failure:
AnalyticsService.shared.track(.contextEnrichmentFailed(component: .location))

// HealthKit failure:
AnalyticsService.shared.track(.contextEnrichmentFailed(component: .healthKit))

// Calendar failure:
AnalyticsService.shared.track(.contextEnrichmentFailed(component: .calendar))
```

**Step 4: Run all tests**

```bash
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -15
```

Expected: `** TEST SUCCEEDED **` with no regressions.

**Step 5: Commit and merge**

```bash
git add Sources/
git commit -m "Instrument error events (classification, AI, context enrichment)"

git checkout main
git merge feature/analytics --no-ff -m "Merge feature/analytics: TelemetryDeck integration"
git push origin main
git branch -d feature/analytics
```

---

## Privacy verification checklist

Before merging, confirm:
- [ ] No thought `.content` appears in any `metadata` dict
- [ ] No `.tags` array appears in any `metadata` dict
- [ ] No HealthKit numeric values appear in any `metadata` dict
- [ ] No location strings appear in any `metadata` dict
- [ ] `AnalyticsServiceTests` all pass
- [ ] `AnalyticsEventTests` all pass, including `test_noPersonalDataLeaks`
