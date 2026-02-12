# Enhanced Siri Integration: "Stash a Thought" & Back Tap

**Issue:** #27 - Enhanced Siri Integration with App Intents
**Status:** Planning
**Target:** iOS 26.0 / Swift 6.0
**Priority:** High

---

## Goal

Two user-facing capabilities:

1. **"Siri, stash a thought"** -- Siri immediately asks "What's on your mind?", user speaks, thought is saved. No app launch required.
2. **Back Tap** -- Double/triple tap the back of the phone triggers a Shortcut that opens the app to a voice capture screen and starts listening.

---

## Current State

### What already exists

| File | What it does |
|------|-------------|
| `Sources/AppIntents/CaptureThoughtIntent.swift` | `AppIntent` that saves a thought. Has `content: String` parameter (no `requestValueDialog`). Runs in background (`openAppWhenRun = false`). Contains `ThoughtAppShortcuts` provider with phrases "Capture a thought in \(.applicationName)", etc. |
| `Sources/AppIntents/ThoughtAppEntity.swift` | `AppEntity` with `ThoughtQuery` and `EntityStringQuery` for Spotlight/Shortcuts integration. |
| `Sources/AppIntents/SearchThoughtsIntent.swift` | Search intent. iOS 26+. |
| `Sources/AppIntents/ReviewIntent.swift` | Review-by-date intent. iOS 26+. |
| `Sources/AppIntents/ThoughtTypeEnum.swift` | `AppEnum` for classification types. iOS 26+. |
| `Sources/STASHApp.swift` | App entry point. Calls `ThoughtAppShortcuts.updateAppShortcutParameters()` in `init()`. |
| `Sources/Services/Domain/ThoughtService.swift` | Actor-based service for thought CRUD with classification, sync, fine-tuning side effects. |
| `Sources/Persistence/Repositories/ThoughtRepository.swift` | Actor-based Core Data repository. `ThoughtRepository.shared` singleton. |
| `Sources/UI/Screens/CaptureScreen.swift` | Text-based capture screen (no voice input). |
| `Sources/UI/ViewModels/CaptureViewModel.swift` | ViewModel for text capture with context gathering and classification. |
| `Sources/Models/Thought.swift` | Domain model. Struct with `id`, `userId`, `content`, `tags`, `status`, `context`, `classification`, etc. |
| `Sources/Models/Context.swift` | Contextual metadata. Has `Context.empty()` factory method. |
| `PersonalAI.entitlements` | Has `com.apple.developer.siri = true` and `com.apple.security.application-groups = ["group.com.withershins.stash"]`. |
| Xcode build settings | Already has `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`. |

### What does NOT exist

- No `SpeechRecognitionService` (zero usage of `Speech.framework`, `SFSpeechRecognizer`, or `AVAudioSession` anywhere in Sources)
- No voice capture UI screen
- No `requestValueDialog` on any `@Parameter`
- No "stash" phrasing in `ThoughtAppShortcuts`
- No deep-link mechanism to open a specific screen from an intent
- No `.speech` case in `FrameworkType`

---

## Architecture

### Two complementary paths

**Path A -- Siri-native voice (Phase 1a):** Enhance `CaptureThoughtIntent` with `requestValueDialog` on the `content` parameter. Siri handles all dictation. The app never opens. Works from lock screen.

**Path B -- In-app voice capture (Phase 1b):** New `SpeechRecognitionService` + `VoiceCaptureScreen` with real-time `SFSpeechRecognizer` transcription. A separate `OpenVoiceCaptureIntent` (with `openAppWhenRun = true`) launches the app to this screen. This is what Back Tap triggers.

Both paths save a `Thought` via `ThoughtRepository.shared` using the same persistence code.

---

## Phase 1a: "Siri, Stash a Thought" (No App Launch)

This phase delivers the primary user story with minimal changes to the existing codebase.

### 1.1 Modify `CaptureThoughtIntent` content parameter

**File:** `Sources/AppIntents/CaptureThoughtIntent.swift`

**Change:** Add `requestValueDialog` to the existing `content` `@Parameter`:

```swift
@Parameter(
    title: "Content",
    description: "What you want to capture",
    requestValueDialog: "What's on your mind?",
    inputOptions: .init(
        multiline: true,
        autocorrect: true,
        smartQuotes: true,
        smartDashes: true
    )
)
var content: String
```

When the user says "Capture a thought in STASH" without providing content inline, Siri will speak "What's on your mind?" and immediately begin listening. The transcribed text becomes the `content` value. No app launch occurs.

If the user says "Capture a thought about my meeting in STASH", Siri extracts "my meeting" as `content` directly and skips the dialog.

### 1.2 Add "Stash" phrases to `ThoughtAppShortcuts`

**File:** `Sources/AppIntents/CaptureThoughtIntent.swift` (in `ThoughtAppShortcuts`)

**Change:** Add new phrases to the existing `AppShortcut` for `CaptureThoughtIntent`:

```swift
AppShortcut(
    intent: CaptureThoughtIntent(),
    phrases: [
        "Capture a thought in \(.applicationName)",
        "Save a note in \(.applicationName)",
        "Remember something in \(.applicationName)",
        "Stash a thought in \(.applicationName)",
        "Stash this in \(.applicationName)",
        "Quick thought in \(.applicationName)"
    ],
    shortTitle: "Stash Thought",
    systemImageName: "brain.head.profile"
)
```

**Constraint:** All App Shortcut phrases must contain `\(.applicationName)`. Apple requires this so the system can route the phrase to the correct app.

### 1.3 Add `parameterSummary`

**File:** `Sources/AppIntents/CaptureThoughtIntent.swift`

```swift
static var parameterSummary: some ParameterSummary {
    Summary("Capture \(\.$content)") {
        \.$type
        \.$autoClassify
    }
}
```

### 1.4 Testing Phase 1a

- Build and run on physical device
- Wait 60 seconds for iOS to index intents
- Say: "Siri, stash a thought in STASH"
- Siri should respond: "What's on your mind?"
- Speak a thought
- Siri should confirm: "Captured as thought: [content]"
- Verify thought appears in Browse screen
- Also test: "Siri, capture a thought about groceries in STASH" (inline content)

---

## Phase 1b: In-App Voice Capture with SFSpeechRecognizer

This phase builds the infrastructure for real-time speech-to-text within the app, which Phase 2 (Back Tap) depends on.

### 1.5 Add `.speech` to `FrameworkType`

**File:** `Sources/Services/Core/ServiceError.swift`

Add a new case to the `FrameworkType` enum:

```swift
case speech = "Speech Recognition"
```

Update the `settingsPath` computed property:

```swift
case .speech: return "Privacy/SpeechRecognition"
```

### 1.6 Create `SpeechRecognitionService`

**New file:** `Sources/Services/Framework/SpeechRecognitionService.swift`

Actor conforming to `FrameworkServiceProtocol`. Wraps `SFSpeechRecognizer` + `AVAudioEngine` for streaming speech-to-text.

**Public API:**
- `startListening() async throws -> AsyncStream<TranscriptionUpdate>` -- begins real-time transcription
- `stopListening() async -> String` -- stops and returns final transcript
- `cancelListening() async` -- stops without returning result

**Types:**
```swift
struct TranscriptionUpdate: Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Float
}
```

**Key details:**
- Configures `AVAudioSession` with category `.playAndRecord`, mode `.measurement`, options `.duckOthers`
- Creates `SFSpeechAudioBufferRecognitionRequest` with `shouldReportPartialResults = true`
- Installs a tap on `AVAudioEngine.inputNode` to feed audio buffers
- Prefers on-device recognition when available

### 1.7 Create `VoiceCaptureViewModel`

**New file:** `Sources/UI/ViewModels/VoiceCaptureViewModel.swift`

`@Observable @MainActor final class` following the pattern of `CaptureViewModel`.

**State:** `transcribedText`, `captureState` (`.idle`/`.listening`/`.processing`/`.saved`/`.error`), `captureSucceeded`

**Behavior:**
- `startListening()` -- requests permissions, starts `SpeechRecognitionService`, subscribes to `AsyncStream<TranscriptionUpdate>`
- `stopAndSave()` -- stops listening, creates `Thought` from `transcribedText`, saves via `ThoughtService`
- 3-second silence auto-save: after each transcription update, reset a timer. If timer fires with non-empty text, auto-call `stopAndSave()`
- Saves with `Context.empty()` first, enriches context asynchronously afterward

### 1.8 Create `VoiceCaptureScreen`

**New file:** `Sources/UI/Screens/VoiceCaptureScreen.swift`

Minimal SwiftUI view with:
- Pulsing microphone icon when listening (`mic.fill` with scale animation)
- Real-time transcription text in a scrollable view
- "Cancel" and "Done" buttons
- Brief checkmark confirmation before auto-dismiss
- Permission error state with Settings button
- `onAppear`: calls `viewModel.startListening()` immediately
- Uses `@Environment(\.themeEngine)` for theming

---

## Phase 2: Back Tap Integration

### How Back Tap works

Back Tap is an Accessibility feature (Settings > Accessibility > Touch > Back Tap). Users assign an action to double/triple-tap the phone's back. One action category is **Shortcuts** -- any shortcut from the Shortcuts app.

There is no API to configure Back Tap programmatically. Our job is to create a Shortcut that opens voice capture.

### 2.1 Create `OpenVoiceCaptureIntent`

**New file:** `Sources/AppIntents/OpenVoiceCaptureIntent.swift`

```swift
struct OpenVoiceCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Voice Capture"
    static let description = IntentDescription(
        "Open STASH and start voice capture",
        categoryName: "Capture",
        searchKeywords: ["voice", "microphone", "speak", "talk", "dictate"]
    )
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.withershins.stash")
        defaults?.set(true, forKey: "pendingVoiceCapture")
        defaults?.synchronize()
        return .result()
    }
}
```

### 2.2 Register in `ThoughtAppShortcuts`

**File:** `Sources/AppIntents/CaptureThoughtIntent.swift`

Add a second `AppShortcut`:

```swift
AppShortcut(
    intent: OpenVoiceCaptureIntent(),
    phrases: [
        "Voice capture in \(.applicationName)",
        "Talk to \(.applicationName)",
        "Speak to \(.applicationName)"
    ],
    shortTitle: "Voice Capture",
    systemImageName: "mic.fill"
)
```

### 2.3 Add deep navigation in `STASHApp.swift`

**File:** `Sources/STASHApp.swift`

Changes:
1. Add `@State private var showVoiceCapture = false`
2. Add `@Environment(\.scenePhase) private var scenePhase`
3. Add `.fullScreenCover(isPresented: $showVoiceCapture)` with `VoiceCaptureScreen`
4. Add `.onChange(of: scenePhase)` to check for pending voice capture flag
5. Add `checkForPendingVoiceCapture()` helper that reads/clears the UserDefaults flag

### 2.4 Back Tap setup instructions for users

1. Open **Settings** > **Accessibility** > **Touch** > **Back Tap**
2. Choose **Double Tap** or **Triple Tap**
3. Scroll to **Shortcuts** section
4. Select **Voice Capture** (under STASH)
5. Double/triple tap the back of your phone to start voice capture

---

## File Change Summary

### New files (5)

| File | Purpose |
|------|---------|
| `Sources/AppIntents/OpenVoiceCaptureIntent.swift` | Intent that opens app to voice capture (for Back Tap) |
| `Sources/Services/Framework/SpeechRecognitionService.swift` | `SFSpeechRecognizer` + `AVAudioEngine` wrapper |
| `Sources/UI/Screens/VoiceCaptureScreen.swift` | Voice capture UI with real-time transcription |
| `Sources/UI/ViewModels/VoiceCaptureViewModel.swift` | State management for voice capture flow |
| `docs/BACK_TAP_SETUP.md` | User-facing Back Tap configuration guide |

### Modified files (3)

| File | Changes |
|------|---------|
| `Sources/AppIntents/CaptureThoughtIntent.swift` | Add `requestValueDialog` to content param, add "Stash a thought" phrases, add `OpenVoiceCaptureIntent` shortcut, add `parameterSummary` |
| `Sources/Services/Core/ServiceError.swift` | Add `case speech` to `FrameworkType` enum |
| `Sources/STASHApp.swift` | Add scenePhase observer, fullScreenCover for VoiceCaptureScreen, UserDefaults flag check |

---

## Implementation Order

| Batch | Steps | Deliverable | Files | Risk |
|-------|-------|-------------|-------|------|
| 1 | 1.1-1.4 | "Siri, stash a thought" works via Siri | `CaptureThoughtIntent.swift` only | Low |
| 2 | 1.5-1.6 | Working `SpeechRecognitionService` | `ServiceError.swift`, new `SpeechRecognitionService.swift` | Medium |
| 3 | 1.7-1.8 | Voice capture UI with real-time transcription | New `VoiceCaptureViewModel.swift`, `VoiceCaptureScreen.swift` | Low-Medium |
| 4 | 2.1-2.4 | Back Tap opens voice capture | New `OpenVoiceCaptureIntent.swift`, modify `CaptureThoughtIntent.swift`, `STASHApp.swift` | Medium |

---

## Design Decisions

### Why enhance existing `CaptureThoughtIntent` instead of creating a new intent
The existing intent already has the correct `perform()` logic. Adding `requestValueDialog` is a one-line change. Creating a separate intent would duplicate persistence logic.

### Why a separate `OpenVoiceCaptureIntent` for Back Tap
Back Tap needs `openAppWhenRun = true` to launch the app. The primary `CaptureThoughtIntent` has `openAppWhenRun = false`. These are mutually exclusive.

### Why UserDefaults via App Group for deep navigation
The app group `group.com.withershins.stash` already exists in entitlements. The intent writes a boolean flag, the app checks it when `scenePhase` becomes `.active`. Simpler and more reliable than URL schemes or NSUserActivity.

### Why 3-second silence timeout
ADHD users benefit from automatic task completion. A 3-second pause is a natural "I'm done" signal. User can also tap "Done" manually.

### Why save with `Context.empty()` for voice capture
Context gathering takes up to 300ms and requires permissions. Voice capture priority is speed. Context can be enriched asynchronously after the save.

---

## Potential Challenges

| Challenge | Mitigation |
|-----------|-----------|
| `SFSpeechRecognizer` requires network for some locales | Check `supportsOnDeviceRecognition`. Show clear error if unavailable offline. |
| `AVAudioSession` conflicts with other audio | Use `.duckOthers`. Handle interruption notifications. |
| App cold launch from Back Tap is slow | Pre-request permissions during onboarding. Use `task(priority: .userInitiated)`. Save with `Context.empty()`. |
| UserDefaults flag persists if app crashes | Clear flag immediately before presenting, not after. |
| Swift 6 strict concurrency | `SpeechRecognitionService` is an actor. `VoiceCaptureViewModel` is `@MainActor`. `TranscriptionUpdate` is `Sendable`. |

---

## Future Enhancements (Not in Scope)

- Control Center widget (`ControlWidget`)
- Action Button support (uses same Shortcut mechanism)
- Live Activity during voice capture
- `GetStreakIntent` and `GetInsightsIntent`
- Spotlight indexing service (`CSSearchableIndex`)
- Focus Filter integration
