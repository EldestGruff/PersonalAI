# Onboarding: Siri Screen, Exit Button, Skip FirstCapture on Replay

**Date:** 2026-02-24
**Status:** Approved

---

## Changes

### 1. Siri Setup Screen (new step)

New `OnboardingStep.siriSetup` inserted between `futureTeaser` and `completion`.
Step enum shifts: siriSetup = 8, completion = 9.

**Content:**
- Persona-voiced intro (added to `OnboardingCopy`)
- Subline: "Works from anywhere — locked screen, AirPods, CarPlay"
- 4 phrase chips in a stacked card list:
  1. "Hey Siri, stash a thought"
  2. "Hey Siri, stash a thought in STASH"
  3. "Hey Siri, save a note in STASH"
  4. "Hey Siri, remember something in STASH"
- Persona copy above list: something like "pick whichever feels natural — all of them work"
- No API call needed; phrases are already registered via `ThoughtAppShortcuts.updateAppShortcutParameters()` at launch

**Files to create:** `Sources/UI/Onboarding/Steps/SiriSetupStepView.swift`
**Files to modify:** `OnboardingCopy.swift` (add `siriSetupIntro(for:)`), `OnboardingScreen.swift` (add case), `OnboardingViewModel.swift` (add step)

---

### 2. Exit Button

- Shown on steps 1–8 (personaPicker through siriSetup); hidden on welcome (0) and completion (9)
- Top-right corner, "×" or `xmark` SF Symbol
- Tertiary text color — visually quiet, not competing with primary CTA
- Action: calls `completeOnboarding()` then `onComplete()`
  - Marks `onboarding.completed = true` in UserDefaults
  - Fires `onboardingCompleted` analytics event
  - Dismisses the screen

**Files to modify:** `OnboardingScreen.swift` (add button to overlay/toolbar)

---

### 3. Skip firstCapture on Replay

`OnboardingViewModel` gains `isReplay: Bool` parameter.

When `isReplay == true`, `advance()` skips over `.firstCapture` automatically (steps from personaPicker directly to acornExplainer).

`MainTabView` gains `@State var isReplayOnboarding = false`.

Replay notification handler:
```swift
.onReceive(NotificationCenter.default.publisher(for: .replayOnboarding)) { _ in
    _Concurrency.Task { @MainActor in
        OnboardingViewModel.resetOnboarding()
        isReplayOnboarding = true
        showOnboarding = true
    }
}
```

`fullScreenCover` passes `isReplay: isReplayOnboarding` when constructing the ViewModel, then resets `isReplayOnboarding = false` in `onComplete`.

**Files to modify:** `OnboardingViewModel.swift`, `STASHApp.swift`

---

## Step Sequence After Changes

| # | Step | Progress dot | Exit visible |
|---|------|-------------|--------------|
| 0 | welcome | no | no |
| 1 | personaPicker | yes | yes |
| 2 | firstCapture | yes | yes (skipped on replay) |
| 3 | acornExplainer | yes | yes |
| 4 | streakIntro | yes | yes |
| 5 | permissions | yes | yes |
| 6 | notifications | yes | yes |
| 7 | futureTeaser | yes | yes |
| 8 | siriSetup | yes | yes |
| 9 | completion | no | no |
