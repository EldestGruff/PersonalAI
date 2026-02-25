# Onboarding: Siri Screen, Exit Button, Skip FirstCapture on Replay

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Siri setup screen to onboarding, an exit button on all mid-flow steps, and skip the first-capture step when replaying the tutorial.

**Architecture:** Three independent changes to the existing enum-based onboarding state machine. The step enum gains one new case (siriSetup at position 8, completion shifts to 9). OnboardingViewModel gains an `isReplay` flag used to skip `.firstCapture` in `advance()`. The exit button is a single overlay addition to `OnboardingScreen`.

**Tech Stack:** SwiftUI, @Observable, UserDefaults, existing OnboardingStep enum

---

### Task 1: Add siriSetupIntro copy to OnboardingCopy

**Files:**
- Modify: `Sources/UI/Onboarding/OnboardingCopy.swift` (after line 162, before completionMessage)

**Step 1: Add the static function**

Add after `futureTeaser(for:)` (after line 162):

```swift
static func siriSetupIntro(for persona: SquirrelPersona) -> String {
    switch persona.id {
    case "supportiveListener":
        return "You can reach me from anywhere — even without opening the app. Just tell Siri, and I'll catch it for you."
    case "brainstormPartner":
        return "Best ideas happen mid-run, mid-drive, mid-shower. Set this up so we never lose one."
    case "socraticQuestioner":
        return "What's the cost of a thought that slips away? Set this up so you can capture from anywhere."
    case "journalGuide":
        return "Sometimes a moment needs to be held right as it happens. This lets you do that hands-free."
    case "devilsAdvocate":
        return "You're going to forget it. You always do. Unless you tell Siri right now."
    default:
        return "Capture thoughts anywhere — just tell Siri."
    }
}
```

**Step 2: Build to verify no errors**

```bash
xcodebuild -scheme STASH -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add Sources/UI/Onboarding/OnboardingCopy.swift
git commit -m "feat: add siriSetupIntro copy to OnboardingCopy"
```

---

### Task 2: Create SiriSetupStepView

**Files:**
- Create: `Sources/UI/Onboarding/Steps/SiriSetupStepView.swift`

**Step 1: Create the file**

```swift
//
//  SiriSetupStepView.swift
//  STASH
//
//  Onboarding step: teaches user the Siri phrases for voice capture.
//

import SwiftUI

struct SiriSetupStepView: View {
    let persona: SquirrelPersona
    let onContinue: () -> Void

    private let phrases = [
        "Hey Siri, stash a thought",
        "Hey Siri, stash a thought in STASH",
        "Hey Siri, save a note in STASH",
        "Hey Siri, remember something in STASH",
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(.purple)

            // Persona-voiced intro
            VStack(spacing: 8) {
                Text("Talk to Siri")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(OnboardingCopy.siriSetupIntro(for: persona))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Phrase chips
            VStack(alignment: .leading, spacing: 0) {
                Text("Pick whichever feels natural — all of them work.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(phrases, id: \.self) { phrase in
                        HStack {
                            Image(systemName: "mic.fill")
                                .font(.caption)
                                .foregroundStyle(.purple)
                            Text(phrase)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // CTA
            Button(action: onContinue) {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    SiriSetupStepView(
        persona: SquirrelPersona(
            id: "supportiveListener",
            name: "Supportive Listener",
            emoji: "🐿️",
            systemPrompt: "",
            colorHex: "#A78BFA",
            isCustom: false,
            isDefault: true,
            createdAt: Date()
        ),
        onContinue: {}
    )
}
```

**Step 2: Build**

```bash
xcodebuild -scheme STASH -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add Sources/UI/Onboarding/Steps/SiriSetupStepView.swift
git commit -m "feat: add SiriSetupStepView"
```

---

### Task 3: Add siriSetup to OnboardingStep enum and update OnboardingViewModel

**Files:**
- Modify: `Sources/UI/ViewModels/OnboardingViewModel.swift`

**Step 1: Update the OnboardingStep enum**

Replace the current enum cases (lines 16–24). Add `siriSetup` before `completion` and shift `completion` to 9:

```swift
enum OnboardingStep: Int, CaseIterable {
    case welcome       = 0
    case personaPicker = 1
    case firstCapture  = 2
    case acornExplainer = 3
    case streakIntro   = 4
    case permissions   = 5
    case notifications = 6
    case futureTeaser  = 7
    case siriSetup     = 8
    case completion    = 9
}
```

**Step 2: Update showProgressDots**

The existing `showProgressDots` returns `false` for `.welcome` and `.completion`. Verify it still compiles cleanly — no change needed since it only excludes by name.

**Step 3: Add isReplay property and update init**

Add `isReplay: Bool = false` property and init parameter:

```swift
// In the state properties section (around line 49), add:
let isReplay: Bool

// Update init signature (line 78):
init(
    isReplay: Bool = false,
    personaService: SquirrelPersonaService = .shared,
    permissionCoordinator: PermissionCoordinator = .shared,
    reminderService: SquirrelReminderService = .shared,
    captureViewModel: CaptureViewModel,
    onComplete: @escaping () -> Void
) {
    self.isReplay = isReplay
    // ...rest of existing init body unchanged
}
```

**Step 4: Update advance() to skip firstCapture on replay**

Find `advance()` (line 103). After the animation block opens, add the skip logic:

```swift
func advance() {
    guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
        completeOnboarding()
        return
    }
    // Skip firstCapture when replaying — user has already done this
    if next == .firstCapture && isReplay {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .acornExplainer
        }
        return
    }
    withAnimation(.easeInOut(duration: 0.3)) {
        currentStep = next
    }
    if currentStep == .completion {
        completeOnboarding()
    }
}
```

Note: Preserve the existing animation and completeOnboarding logic exactly — only add the isReplay guard.

**Step 5: Build**

```bash
xcodebuild -scheme STASH -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
Expected: `BUILD SUCCEEDED`

**Step 6: Commit**

```bash
git add Sources/UI/ViewModels/OnboardingViewModel.swift
git commit -m "feat: add siriSetup step and isReplay to OnboardingViewModel"
```

---

### Task 4: Wire siriSetup into OnboardingScreen and add exit button

**Files:**
- Modify: `Sources/UI/Screens/OnboardingScreen.swift`

**Step 1: Add siriSetup case to stepView**

In the `stepView` switch (around line 72), add before the `.completion` case:

```swift
case .siriSetup:
    SiriSetupStepView(
        persona: viewModel.selectedPersona,
        onContinue: { viewModel.advance() }
    )
```

**Step 2: Add exit button overlay**

The top-level `ZStack` or `VStack` in `OnboardingScreen.body` needs an exit button overlay. Add it as an overlay on the outermost container, shown only when the step is not `.welcome` and not `.completion`:

```swift
// Add this inside the body, as an overlay on the main ZStack/VStack:
.overlay(alignment: .topTrailing) {
    if viewModel.currentStep != .welcome && viewModel.currentStep != .completion {
        Button {
            viewModel.completeOnboarding()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(16)
        }
        .accessibilityLabel("Exit tutorial")
    }
}
```

Note: `completeOnboarding()` is currently `private`. Check — if it is, change it to `internal` (remove the `private` modifier) so `OnboardingScreen` can call it. The exit button calling `completeOnboarding()` directly is intentional: it marks the tutorial done and fires analytics.

**Step 3: Build**

```bash
xcodebuild -scheme STASH -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
Expected: `BUILD SUCCEEDED`

**Step 4: Commit**

```bash
git add Sources/UI/Screens/OnboardingScreen.swift
git commit -m "feat: wire siriSetup step and add exit button to OnboardingScreen"
```

---

### Task 5: Update STASHApp to pass isReplay when replaying

**Files:**
- Modify: `Sources/STASHApp.swift`

**Step 1: Add isReplayOnboarding state to STASHApp**

In `STASHApp` (around line 27, near `showOnboarding`):

```swift
@State private var isReplayOnboarding = false
```

**Step 2: Update the fullScreenCover to pass isReplay**

In the `fullScreenCover` (around line 61), update the `OnboardingViewModel` init:

```swift
viewModel: OnboardingViewModel(
    isReplay: isReplayOnboarding,
    captureViewModel: CaptureViewModel(
        thoughtService: ThoughtService.shared,
        contextService: ContextService.shared,
        classificationService: ClassificationService.shared,
        fineTuningService: FineTuningService.shared,
        taskService: TaskService.shared
    ),
    onComplete: {
        showOnboarding = false
        isReplayOnboarding = false
    }
)
```

**Step 3: Update the replayOnboarding handler**

Find the `.onReceive` handler (around line 78):

```swift
.onReceive(NotificationCenter.default.publisher(for: .replayOnboarding)) { _ in
    _Concurrency.Task { @MainActor in
        OnboardingViewModel.resetOnboarding()
        isReplayOnboarding = true
        showOnboarding = true
    }
}
```

**Step 4: Build**

```bash
xcodebuild -scheme STASH -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add Sources/STASHApp.swift
git commit -m "feat: pass isReplay to OnboardingViewModel on tutorial replay"
```

---

### Task 6: Final verification

**Step 1: Full build**

```bash
xcodebuild -scheme STASH -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|warning:|BUILD)"
```
Expected: `BUILD SUCCEEDED`, no new errors.

**Step 2: Manual test checklist**

First-run flow:
- [ ] All 10 steps appear in order (welcome → … → siriSetup → completion)
- [ ] firstCapture step appears on first run
- [ ] Exit × button visible on steps 1–8, hidden on welcome and completion
- [ ] Tapping × dismisses onboarding and does not show it again on next launch
- [ ] Siri screen shows all 4 phrases with mic icon
- [ ] Progress dots count matches step count

Replay flow (Settings → Replay Onboarding):
- [ ] firstCapture step is skipped (jumps from personaPicker to acornExplainer)
- [ ] siriSetup still appears
- [ ] Exit × still works
- [ ] Replay doesn't break normal flow on subsequent first-run simulator reset

**Step 3: Push branch**

```bash
git push origin feature/onboarding-siri-exit
```
