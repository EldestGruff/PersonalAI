# Watch Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add haptic feedback, notification foreground display, and WidgetKit complications to the watchOS STASH app.

**Architecture:** Three independent additions to the Watch target. Haptics are inline edits to `WatchCaptureView.swift`. The notification delegate is a new file wired into `WatchSTASHApp.init()`. Complications are a new WidgetKit file; the watchOS runtime discovers it automatically alongside the `@main` App via `fileSystemSynchronizedGroups` — no `project.pbxproj` edits needed.

**Tech Stack:** WatchKit (`WKInterfaceDevice.current().play(_:)`), UserNotifications (`UNUserNotificationCenterDelegate`), WidgetKit (`.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`)

---

## Task 1: Haptic Feedback

Add `WKHapticType` feedback at three points in the recording lifecycle: start (`.start`), stop (`.stop`), and success acknowledgment (`.success`).

**Files:**
- Modify: `STASH Watch App Watch App/WatchCaptureView.swift`

**Step 1: Add haptic to `startCapture()` — after `isRecording = true`**

Locate this block (lines 148–155):
```swift
try await WatchSpeechService.shared.startRecording()
await MainActor.run {
    isRecording = true
    startLevelPolling()
}
```

Change to:
```swift
try await WatchSpeechService.shared.startRecording()
await MainActor.run {
    WKInterfaceDevice.current().play(.start)
    isRecording = true
    startLevelPolling()
}
```

**Step 2: Add `import WatchKit` at the top of the file**

After `import SwiftUI`, add:
```swift
import WatchKit
```

**Step 3: Add haptic to `stopCapture()` — after `isRecording = false`**

Locate (lines 160–162):
```swift
guard isRecording else { return }
stopLevelPolling()
isRecording = false
```

Change to:
```swift
guard isRecording else { return }
stopLevelPolling()
WKInterfaceDevice.current().play(.stop)
isRecording = false
```

**Step 4: Add haptic after acknowledgment is set — inside the `Task` block**

Locate (lines 171–174):
```swift
withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
    acknowledgment = .random()
}
```

Change to:
```swift
WKInterfaceDevice.current().play(.success)
withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
    acknowledgment = .random()
}
```

**Step 5: Build the Watch target**

In Xcode: select the `STASH Watch App Watch App` scheme, choose a Watch simulator or device, and build (`Cmd+B`). Expected: no errors.

Or via CLI:
```bash
xcodebuild -project PersonalAI.xcodeproj \
  -scheme "STASH Watch App Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  build 2>&1 | tail -20
```

**Step 6: Commit**

```bash
git add "STASH Watch App Watch App/WatchCaptureView.swift"
git commit -m "feat(watch): add haptic feedback for record start, stop, and acknowledgment"
```

---

## Task 2: Notification Foreground Display Delegate

iOS sends local notifications that the system automatically forwards to the Watch when appropriate. Without a delegate, watchOS silences these when the Watch app is in the foreground. This task adds a delegate so banners appear even while the app is open.

**Files:**
- Create: `STASH Watch App Watch App/WatchNotificationDelegate.swift`
- Modify: `STASH Watch App Watch App/WatchSTASHApp.swift`

**Step 1: Create `WatchNotificationDelegate.swift`**

```swift
//
//  WatchNotificationDelegate.swift
//  STASH Watch App
//
//  Displays notification banners even when the app is in the foreground.
//  Wired into WatchSTASHApp.init().
//

import UserNotifications

final class WatchNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WatchNotificationDelegate()
    private override init() {}

    /// Show banner + play sound even when the Watch app is active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
```

**Step 2: Wire delegate into `WatchSTASHApp.init()`**

Open `WatchSTASHApp.swift`. Change:
```swift
init() {
    WatchConnectivityManager.shared.activate()
}
```

To:
```swift
init() {
    WatchConnectivityManager.shared.activate()
    UNUserNotificationCenter.current().delegate = WatchNotificationDelegate.shared
}
```

Also add `import UserNotifications` after `import SwiftUI`.

**Step 3: Build**

Same build command as Task 1. Expected: no errors or warnings.

**Step 4: Commit**

```bash
git add "STASH Watch App Watch App/WatchNotificationDelegate.swift" \
        "STASH Watch App Watch App/WatchSTASHApp.swift"
git commit -m "feat(watch): show notification banners in foreground via UNUserNotificationCenterDelegate"
```

---

## Task 3: WidgetKit Complications

Add three complication families: `.accessoryCircular` (the circular spot on watch faces), `.accessoryRectangular` (the wide banner slot), and `.accessoryInline` (the thin one-line slot above the time). All tap directly into the Watch app. No user configuration, so `StaticConfiguration` is used.

The Watch target uses `fileSystemSynchronizedGroups` — placing the file in the `STASH Watch App Watch App/` folder is sufficient for it to compile. No `project.pbxproj` edits needed.

**Files:**
- Create: `STASH Watch App Watch App/STASHComplications.swift`

**Step 1: Create `STASHComplications.swift`**

```swift
//
//  STASHComplications.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch complications
//
//  Three WidgetKit complication families:
//    - .accessoryCircular  — circular slot (most watch faces)
//    - .accessoryRectangular — wide banner slot (Modular, Infograph Modular)
//    - .accessoryInline    — one-line slot above the time
//
//  Tapping any complication opens the Watch app directly.
//  StaticConfiguration used — no per-user widget configuration.
//
//  watchOS discovers this WidgetBundle automatically alongside the @main App
//  when the file is in the same fileSystemSynchronizedGroups target.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct STASHComplicationEntry: TimelineEntry {
    let date: Date
}

// MARK: - Provider

struct STASHComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> STASHComplicationEntry {
        STASHComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (STASHComplicationEntry) -> Void) {
        completion(STASHComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<STASHComplicationEntry>) -> Void) {
        // Refresh every hour — the complication is static (tap-to-open only)
        let entry = STASHComplicationEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Complication Views

struct STASHCircularView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct STASHRectangularView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14, weight: .semibold))
            Text("Capture thought")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.white)
    }
}

struct STASHInlineView: View {
    var body: some View {
        Label("Capture", systemImage: "brain.head.profile")
    }
}

// MARK: - Widget

struct STASHComplicationWidget: Widget {
    let kind = "STASHComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: STASHComplicationProvider()) { _ in
            STASHComplicationEntryView()
        }
        .configurationDisplayName("STASH")
        .description("Tap to capture a thought.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Entry View (dispatches to family-specific views)

struct STASHComplicationEntryView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            STASHCircularView()
        case .accessoryRectangular:
            STASHRectangularView()
        case .accessoryInline:
            STASHInlineView()
        default:
            STASHCircularView()
        }
    }
}

// MARK: - Widget Bundle (auto-discovered by watchOS runtime)

struct STASHComplicationBundle: WidgetBundle {
    var body: some Widget {
        STASHComplicationWidget()
    }
}
```

**Step 2: Build**

Same build command. If WidgetKit is not linked, add it to the Watch target's "Frameworks, Libraries, and Embedded Content" in Xcode (drag `WidgetKit.framework` from the framework picker). Expected: no errors.

**Step 3: Verify on device or simulator**

On Watch simulator: long-press watch face → Edit → add complication → find "STASH" in the list. The circular, rectangular, and inline slots should all show STASH.

**Step 4: Commit**

```bash
git add "STASH Watch App Watch App/STASHComplications.swift"
git commit -m "feat(watch): add WidgetKit complications (circular, rectangular, inline)"
```

---

## Task 4: Final Verification and Branch Completion

**Step 1: Full clean build**

```bash
xcodebuild -project PersonalAI.xcodeproj \
  -scheme "STASH Watch App Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  clean build 2>&1 | grep -E "(error:|warning:|BUILD)"
```

Expected: `BUILD SUCCEEDED`, zero errors.

**Step 2: Use finishing-a-development-branch skill**

Follow the `superpowers:finishing-a-development-branch` skill to present merge/PR options.
