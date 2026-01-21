# Monitoring & Error Tracking Setup

**Last Updated:** 2026-01-20

## Purpose

Set up monitoring so you know when your app is broken before customers tell you. Essential for maintaining quality and responding quickly to issues.

---

## What to Monitor

### 1. Crashes
**Critical:** App crashes for users

**Metrics:**
- Crash-free rate (target: >99.5%)
- Crash count per version
- Stack traces for debugging
- Affected users and devices

### 2. Errors
**Important:** Non-crash errors that degrade experience

**Examples:**
- API failures (classification service down)
- Context gathering failures
- Permission denied errors
- Network timeouts

### 3. Performance
**Nice-to-have:** App speed and responsiveness

**Metrics:**
- App launch time
- Context gathering duration
- Classification response time
- Memory usage

### 4. Usage
**Strategic:** How users interact with your app

**Metrics:**
- Daily/Monthly active users
- Feature adoption rates
- Retention (Day 1, Day 7, Day 30)
- Session length

---

## Recommended Monitoring Stack

### For Solo Developer (Free Tier)

**Tier 1: Essential (Free)**
1. **Firebase Crashlytics** - Crash reporting
2. **App Store Connect Analytics** - Basic usage metrics

**Tier 2: Growth (Mostly Free)**
3. **Sentry** (Free: 5K events/month) - Error tracking
4. **MetricKit** (Built-in iOS) - Performance metrics

**Tier 3: Advanced (Paid)**
5. **Mixpanel/Amplitude** ($0-50/month) - Advanced analytics
6. **Custom dashboard** (Grafana + backend) - Full control

**Recommendation:** Start with Tier 1, add Tier 2 when you have >100 users

---

## Setup Guide: Firebase Crashlytics

**Why Firebase?**
- Free forever
- Easy to set up
- Good iOS support
- Real-time crash reporting
- Stack traces with symbolication

### Step 1: Create Firebase Project

1. Go to [firebase.google.com](https://firebase.google.com)
2. Click "Get started"
3. Click "Add project"
4. Name it "PersonalAI"
5. Disable Google Analytics (you won't need it yet)
6. Create project

### Step 2: Add iOS App to Firebase

1. In Firebase console, click iOS icon
2. Enter your bundle ID: `com.yourname.PersonalAI`
3. Download `GoogleService-Info.plist`
4. Drag `GoogleService-Info.plist` into Xcode project root
5. Make sure "Copy items if needed" is checked

### Step 3: Add Firebase SDK

**Using Swift Package Manager (recommended):**

1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Version: Up to Next Major (11.0.0 or latest)
4. Select packages:
   - **FirebaseCrashlytics** ✓
   - FirebaseAnalytics (optional, skip for now)
5. Click "Add Package"

### Step 4: Initialize Firebase in App

**Edit `PersonalAIApp.swift`:**

```swift
import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

@main
struct PersonalAIApp: App {
    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Enable crash reporting
        #if DEBUG
        // Disable in debug builds to avoid pollution
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Step 5: Upload Debug Symbols

**Automatic symbolication (recommended):**

1. In Xcode, select project in navigator
2. Select "PersonalAI" target
3. Build Phases tab
4. Click "+" → "New Run Script Phase"
5. Name it "Firebase Crashlytics"
6. Paste script:

```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

7. Add input file:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}
```

**This uploads debug symbols automatically on each build.**

### Step 6: Test Crash Reporting

**Add test crash button (temporary, for testing):**

```swift
import FirebaseCrashlytics

// In a test view or settings
Button("Test Crash") {
    fatalError("Test crash for Firebase Crashlytics")
}
```

**Test the integration:**
1. Run app on device or simulator
2. Tap "Test Crash" button
3. App will crash
4. Reopen app (this sends crash report)
5. Check Firebase console → Crashlytics (may take 5 min to appear)

**Remove test button before shipping!**

### Step 7: Log Non-Fatal Errors

**For errors that don't crash the app:**

```swift
import FirebaseCrashlytics

// Example: Log classification service failure
func classifyThought(_ content: String) async throws -> Classification {
    do {
        return try await apiClient.classify(content)
    } catch {
        // Log non-fatal error to Crashlytics
        Crashlytics.crashlytics().record(error: error)

        // Log additional context
        Crashlytics.crashlytics().log("Classification failed for thought: \(content.prefix(50))")

        // Rethrow or handle
        throw error
    }
}
```

**Add custom keys for context:**

```swift
// Set user ID (if you have user accounts)
Crashlytics.crashlytics().setUserID(userID)

// Set custom keys for debugging
Crashlytics.crashlytics().setCustomValue(permissionsGranted, forKey: "healthkit_granted")
Crashlytics.crashlytics().setCustomValue(energyLevel, forKey: "current_energy")
```

---

## Setup Guide: Sentry (Optional, Advanced)

**Why Sentry?**
- Better error tracking for non-crash issues
- Performance monitoring
- Release tracking
- Issue de-duplication

**When to add:** When you have >100 users and want deeper insights

### Quick Setup

1. Sign up at [sentry.io](https://sentry.io)
2. Create project (iOS)
3. Add SPM package: `https://github.com/getsentry/sentry-cocoa`
4. Initialize:

```swift
import Sentry

@main
struct PersonalAIApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "YOUR_DSN_HERE"
            options.tracesSampleRate = 1.0 // Sample 100% of transactions
            options.enableCrashHandler = true
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Benefits over Crashlytics:**
- Better issue grouping
- Performance traces
- Release health tracking
- Breadcrumbs (what user did before error)

---

## Performance Monitoring with MetricKit

**MetricKit** is Apple's built-in performance monitoring (iOS 13+).

### Setup

**Create MetricKit Manager:**

```swift
import MetricKit

class MetricKitManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricKitManager()

    private override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    // Receive metrics daily
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // App launch time
            if let launchTime = payload.applicationLaunchMetrics?.histogrammedTimeToFirstDrawKey.averageValue {
                print("Average launch time: \(launchTime)ms")
            }

            // App hang time
            if let hangTime = payload.applicationResponsivenessMetrics?.histogrammedApplicationHangTime.averageValue {
                print("Average hang time: \(hangTime)ms")
            }

            // Memory usage
            if let memory = payload.memoryMetrics?.peakMemoryUsage {
                print("Peak memory: \(memory)MB")
            }

            // Send to your backend or log service
            sendToBackend(payload)
        }
    }

    // Receive crash diagnostics
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            // Crash reports
            if let crashDiagnostic = payload.crashDiagnostics?.first {
                print("Crash: \(crashDiagnostic)")
                // Send to backend
            }
        }
    }
}
```

**Initialize in app:**

```swift
@main
struct PersonalAIApp: App {
    init() {
        // Initialize MetricKit
        _ = MetricKitManager.shared
    }
}
```

**Metrics delivered daily**, not real-time. Good for aggregate trends.

---

## App Store Connect Analytics

**Free, basic analytics** built into App Store Connect.

### What You Get

**Usage:**
- App Units (downloads)
- Sales (if paid app)
- In-App Purchases (if applicable)
- Crashes and Metrics

**Crashes:**
- Crash rate per version
- Crash logs (with symbolication)
- Affected devices and OS versions

### How to Access

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → PersonalAI
3. **App Analytics** tab → Usage, retention, etc.
4. **TestFlight** tab → Beta metrics
5. **Activity** tab → Crashes

### Weekly Review

**Every Monday, check:**
- Crash rate (should be <0.5%)
- New crashes (investigate stack traces)
- Downloads trend
- User retention

---

## Setting Up Alerts

**Goal:** Get notified when something breaks

### Firebase Crashlytics Alerts

1. Firebase Console → Crashlytics
2. Settings → Alerts
3. Enable:
   - New issues detected
   - Crash-free rate drops below threshold (e.g., 99%)
4. Set notification method (email)

### Sentry Alerts (if using Sentry)

1. Sentry Project → Alerts
2. Create alert:
   - **Trigger:** "Crash rate exceeds 1% in 1 hour"
   - **Action:** Email + Slack (if you have it)

### Email Digest Setup

**Create weekly digest email to yourself:**

**Subject:** PersonalAI Weekly Metrics

**Body:**
- Crash-free rate: X%
- New users: X
- Active users: X
- Top crash: [description]
- Top feature request: [description]
- Support volume: X emails

**Tools:**
- Manual (review dashboards, write email)
- Automated (script that pulls data and emails you)
- Zapier/Make.com (no-code automation)

---

## Custom Logging

**For debugging issues in production:**

### Unified Logging (iOS 14+)

```swift
import os.log

// Create logger
let logger = Logger(subsystem: "com.yourname.PersonalAI", category: "ContextService")

// Log messages
logger.debug("Starting context gather")
logger.info("Location permission granted")
logger.warning("HealthKit query took \(duration)ms - slower than expected")
logger.error("Failed to classify thought: \(error.localizedDescription)")
```

**Benefits:**
- Structured logging
- Filterable in Console.app
- Privacy-respecting (PII redacted by default)

**View logs:**
- Connect device to Mac
- Open Console.app
- Filter by subsystem

### Remote Logging (Advanced)

**Send logs to backend for analysis:**

```swift
struct RemoteLogger {
    static func log(_ message: String, level: LogLevel, metadata: [String: Any] = [:]) {
        // Only send errors/warnings to backend
        guard level == .error || level == .warning else { return }

        let log = [
            "message": message,
            "level": level.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.appVersion,
            "ios_version": UIDevice.current.systemVersion,
            "metadata": metadata
        ] as [String : Any]

        // Send to backend API
        sendToBackend(log)
    }
}

enum LogLevel: String {
    case debug, info, warning, error
}
```

**Use case:** Debugging rare issues that don't crash

---

## Monitoring Dashboard (Future)

**When you have backend and want full visibility:**

### Option A: Hosted (Easier)

**Datadog** ($15/month):
- All-in-one monitoring
- Logs, metrics, traces
- Mobile SDKs
- Alerts

**New Relic** ($0-100/month):
- Application performance monitoring
- Error tracking
- Custom dashboards

### Option B: Self-Hosted (Cheaper at scale)

**Grafana + Prometheus:**
- Open source
- Full customization
- Host on Railway/Render
- ~$10/month

**Setup:**
- Backend collects metrics from app
- Stores in time-series database (Prometheus)
- Visualize with Grafana dashboards

---

## Privacy Considerations

**Important:** Be transparent about data collection

### What to Disclose

**App Store Privacy Labels:**
- Crash Data: "Used for app functionality"
- Performance Data: "Used for app functionality"
- Device ID: "Linked to user" (if tracking users)

**Privacy Policy (required):**
- What data is collected (crashes, errors, usage)
- Why (to improve app stability)
- Who has access (you, Firebase, etc.)
- How long it's stored (Firebase: 90 days)
- How to opt out (usually can't opt out of crash reporting)

### Respect User Privacy

**Don't log:**
- Thought content (sensitive user data)
- Personal identifiers (unless necessary)
- Location coordinates (unless needed for debugging)

**Do log:**
- Error messages
- Stack traces
- Device info (model, iOS version)
- App version
- Aggregated usage metrics

---

## Monitoring Workflow

### Daily (5 min)
- Check Firebase Crashlytics dashboard
- Any new crashes? Investigate stack trace
- Crash rate spike? Urgent issue
- Respond to critical issues immediately

### Weekly (30 min)
- Review App Store Connect analytics
- Check performance trends (launch time, etc.)
- Review top crashes of the week
- Plan fixes for next release

### Monthly (1 hour)
- Analyze usage trends
- Feature adoption rates
- User retention analysis
- Adjust roadmap based on data

---

## Key Metrics Tracking

### Reliability
- **Crash-free rate:** >99.5% (Target)
- **App Store rating:** >4.0 stars
- **Support volume:** <5 hours/week

### Performance
- **Launch time:** <2 seconds (cold start)
- **Context gathering:** <300ms (cached)
- **Memory usage:** <100MB (active use)

### Usage
- **DAU (Daily Active Users):** Track growth
- **Retention:**
  - Day 1: >40%
  - Day 7: >20%
  - Day 30: >10%
- **Session length:** Avg 2-5 minutes
- **Thoughts captured:** Avg 3-5 per active user per day

### Business (if monetizing)
- **Conversion rate:** Free → Paid
- **Churn rate:** Monthly cancellations
- **LTV (Lifetime Value):** Revenue per user
- **CAC (Customer Acquisition Cost):** Cost to acquire user

---

## When Something Goes Wrong

### High Crash Rate Alert

1. **Assess severity:**
   - What % of users affected?
   - Which version?
   - Which devices/iOS versions?

2. **Investigate:**
   - Read stack trace
   - Reproduce locally
   - Check recent code changes

3. **Fix:**
   - If critical (affecting >10% users): Hotfix immediately
   - If moderate: Include in next patch release
   - If minor: Note and fix when convenient

4. **Communicate:**
   - If severe: Tweet/email users about known issue
   - If moderate: Mention in next release notes
   - If minor: Just fix quietly

5. **Post-mortem:**
   - What caused it?
   - How did it get through testing?
   - How to prevent in future?

---

## Success Criteria

**Your monitoring setup is working when:**

✅ You hear about crashes from Crashlytics, not customers
✅ You can reproduce and fix crashes within 24 hours
✅ You know your crash-free rate without looking it up
✅ You check metrics weekly without forgetting
✅ You make data-driven decisions about features

---

## Next Steps

1. Set up Firebase Crashlytics (1 hour)
2. Test crash reporting
3. Add error logging to critical paths
4. Set up crash rate alert
5. Check dashboards daily for 1 week (build habit)
6. Review metrics weekly

Then move on to: **[CI_CD_SETUP.md](./CI_CD_SETUP.md)**
