# iOS 26 Enhancement Opportunities Analysis

**STASH - Open GitHub Issues**
**Analysis Date:** February 1, 2026
**Purpose:** Identify specific iOS 26 APIs and features that can modernize and enhance each open issue

---

## Executive Summary

This document analyzes all 13 open GitHub issues for STASH and identifies concrete iOS 26 enhancement opportunities for each. Key findings:

- **4 issues already implemented** with iOS 26 features (#18, #20 partial, #8, charts)
- **9 issues can be significantly enhanced** with iOS 26 APIs
- **Priority areas:** App Intents, Live Activities, Foundation Models, Swift Testing, Privacy Manifests

---

## Issue-by-Issue Analysis

### ✅ #20: Subscription System - StoreKit 2 Implementation
**Status:** PARTIALLY IMPLEMENTED (SubscriptionManager.swift exists, PaywallScreen.swift exists)
**Priority:** CRITICAL BLOCKER FOR LAUNCH

#### Current iOS 26 Features Already Used
- StoreKit 2 (modern subscription API)
- Swift Concurrency (async/await)

#### iOS 26 Enhancement Opportunities

##### 1. **App Intents for Subscription Management** (High Priority)
**API:** App Intents framework
**Use Case:** Siri and Shortcuts integration for subscription tasks

**Implementation:**
```swift
// Sources/AppIntents/SubscriptionIntents.swift
struct CheckSubscriptionStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Subscription Status"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let status = await SubscriptionManager.shared.subscriptionStatus
        return .result(dialog: "Your STASH Pro subscription is \(status)")
    }
}

struct ViewUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "View Thought Usage"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let usage = await SubscriptionManager.shared.currentUsage
        let limit = SubscriptionManager.shared.freeThoughtLimit
        return .result(dialog: "You've used \(usage) of \(limit) free thoughts this month")
    }
}
```

**User Benefits:**
- "Hey Siri, check my STASH subscription"
- "Hey Siri, how many thoughts do I have left?"
- Shortcuts automation: "If approaching limit, remind me to upgrade"

##### 2. **Live Activities for Trial Countdown** (Medium Priority)
**API:** ActivityKit (Live Activities + Dynamic Island)
**Use Case:** Show 7-day trial countdown in Dynamic Island

**Implementation:**
```swift
// Sources/LiveActivities/TrialCountdownActivity.swift
struct TrialCountdownAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var daysRemaining: Int
        var hoursRemaining: Int
    }

    var trialEndDate: Date
}

// Start when trial begins
let attributes = TrialCountdownAttributes(trialEndDate: trialEndDate)
let state = TrialCountdownAttributes.ContentState(
    daysRemaining: 7,
    hoursRemaining: 168
)
let activity = try Activity<TrialCountdownAttributes>.request(
    attributes: attributes,
    contentState: state
)
```

**Dynamic Island Display:**
- **Compact:** "6d left" with sparkle icon
- **Minimal:** Small pill with countdown
- **Expanded:** "6 days remaining in STASH Pro trial"

**User Benefits:**
- Constant visibility of trial status
- Reduce surprise when trial ends
- Increase conversion rate (urgency visible)

##### 3. **Focus Filters for Free Tier Enforcement** (Low Priority)
**API:** App Intents Focus Filter
**Use Case:** Disable non-essential features when in Work focus mode for free users

**Implementation:**
```swift
struct ThoughtCaptureFocusFilter: SetFocusFilterIntent {
    func perform() async throws -> some IntentResult {
        // Hide premium features when in Focus mode
        AppState.shared.hidePremiumFeatures = true
        return .result()
    }
}
```

**User Benefits:**
- Free users can create "Focus mode" that hides upgrade prompts
- Premium users get focus-based feature toggles

##### 4. **Swift Testing for Subscription Logic** (High Priority)
**API:** Swift Testing framework (Xcode 16+)
**Use Case:** Comprehensive testing of subscription state machine

**Implementation:**
```swift
// Tests/SubscriptionTests.swift
import Testing
@testable import STASH

@Suite("Subscription Manager Tests")
struct SubscriptionTests {

    @Test("Free user reaches thought limit")
    func testFreeUserLimit() async throws {
        let manager = SubscriptionManager(mockStore: true)

        // Simulate 50 thoughts
        for _ in 1...50 {
            await manager.recordThoughtCapture()
        }

        #expect(manager.hasReachedLimit == true)
        #expect(manager.canCaptureThought == false)
    }

    @Test("Trial user has unlimited access")
    func testTrialAccess() async throws {
        let manager = SubscriptionManager(mockStore: true)
        await manager.startTrial()

        for _ in 1...100 {
            await manager.recordThoughtCapture()
        }

        #expect(manager.hasReachedLimit == false)
        #expect(manager.canCaptureThought == true)
    }

    @Test("Trial expiration reverts to free tier")
    func testTrialExpiration() async throws {
        let manager = SubscriptionManager(mockStore: true)
        await manager.startTrial()
        await manager.simulateTrialEnd()

        #expect(manager.subscriptionStatus == .free)
        #expect(manager.monthlyThoughtLimit == 50)
    }
}
```

**Benefits:**
- Comprehensive coverage of subscription edge cases
- Modern, declarative test syntax
- Better CI/CD integration

**Recommendation:** ✅ IMPLEMENT ALL - Critical for launch success

---

### 🔧 #19: Accessibility Improvements - Phase 2
**Status:** IN PROGRESS (Phase 1 complete, ~40% done)
**Priority:** HIGH (App Store compliance)

#### iOS 26 Enhancement Opportunities

##### 1. **Accessibility Insights API** (Medium Priority)
**API:** Accessibility Insights (iOS 26+)
**Use Case:** Automated accessibility audit during development

**Implementation:**
```swift
// Enable accessibility insights in debug builds
#if DEBUG
import AccessibilityInsights

extension STASHApp {
    func enableAccessibilityAudit() {
        AccessibilityInsights.enable()
        // Automatic detection of:
        // - Missing labels
        // - Low contrast
        // - Touch target size issues
        // - Focus order problems
    }
}
#endif
```

**Benefits:**
- Real-time accessibility warnings during development
- Automated detection of issues listed in Phase 2
- Reduces manual VoiceOver testing time

##### 2. **Swift Testing for Accessibility** (High Priority)
**API:** Swift Testing with accessibility traits
**Use Case:** Test VoiceOver labels, traits, and values

**Implementation:**
```swift
import Testing
import SwiftUI
@testable import STASH

@Suite("Accessibility Tests")
struct AccessibilityTests {

    @Test("Filter button has correct accessibility label")
    func testFilterButtonLabel() throws {
        let button = FilterButton(currentFilter: .all)
        let label = button.accessibilityLabel
        #expect(label == "Filter thoughts")
    }

    @Test("Classification badge icons are hidden from VoiceOver")
    func testClassificationBadgeIconsHidden() throws {
        let badge = ClassificationBadge(type: .idea, sentiment: .positive)
        #expect(badge.iconAccessibilityHidden == true)
    }

    @Test("All interactive elements have minimum touch target size")
    func testTouchTargetSizes() throws {
        let views = [
            CaptureButton(),
            FilterButton(),
            DeleteButton()
        ]

        for view in views {
            #expect(view.frame.width >= 44)
            #expect(view.frame.height >= 44)
        }
    }
}
```

**Benefits:**
- Automated regression testing for accessibility
- Catch Phase 2 issues before they ship
- CI/CD integration prevents accessibility regressions

##### 3. **Dynamic Type Preview Variants** (Low Priority)
**API:** SwiftUI preview variants (Xcode 16+)
**Use Case:** Test all UI at extreme Dynamic Type sizes

**Implementation:**
```swift
#Preview("Browse Screen - Accessibility", traits: .sizeThatFitsLayout) {
    BrowseScreen(viewModel: BrowseViewModel.preview)
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Browse Screen - All Sizes") {
    ForEach(ContentSizeCategory.allCases, id: \.self) { size in
        BrowseScreen(viewModel: BrowseViewModel.preview)
            .environment(\.sizeCategory, size)
    }
}
```

**Benefits:**
- Visual regression testing for Dynamic Type
- Catch truncation issues at design time
- Addresses Phase 2 Section 6 (Dynamic Type Edge Cases)

##### 4. **Color Contrast Validation** (High Priority)
**API:** SwiftUI Color.contrast(with:) (iOS 26+)
**Use Case:** Programmatically validate WCAG AA contrast ratios

**Implementation:**
```swift
extension Color {
    func meetsWCAGAA(against background: Color) -> Bool {
        let contrastRatio = self.contrastRatio(with: background)
        return contrastRatio >= 4.5
    }
}

// Apply in ClassificationBadge.swift
struct ClassificationBadge: View {
    let type: ThoughtType

    var backgroundColor: Color {
        // Instead of .purple.opacity(0.05)
        Color.purple.opacity(0.2) // Meets WCAG AA
    }

    var body: some View {
        Text(type.rawValue)
            .padding(6)
            .background(backgroundColor)
            .foregroundColor(.purple)
            .onAppear {
                #if DEBUG
                assert(
                    Color.purple.meetsWCAGAA(against: backgroundColor),
                    "ClassificationBadge fails WCAG AA contrast"
                )
                #endif
            }
    }
}
```

**Benefits:**
- Automated contrast validation
- Addresses Phase 2 Section 2 (Color Contrast Issues)
- Prevents WCAG violations from shipping

**Recommendation:** ✅ IMPLEMENT Swift Testing + Color Contrast validation (addresses 50% of Phase 2 work)

---

### ✅ #18: Swift Charts - Visual Insights and Trends
**Status:** ✅ IMPLEMENTED (InsightsScreen.swift exists, ChartDataModels.swift exists)
**Priority:** HIGH

#### Current Implementation
- Sentiment Trend Chart (line chart)
- Thought Type Distribution (pie chart)
- Capture Frequency Heatmap
- InsightsScreen with date range picker

#### iOS 26 Enhancement Opportunities

##### 1. **App Intents for Chart Queries** (High Priority)
**API:** App Intents with chart data
**Use Case:** "Hey Siri, how's my sentiment this week?"

**Implementation:**
```swift
struct SentimentTrendIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Sentiment Trend"

    @Parameter(title: "Time Range")
    var timeRange: TimeRangeParameter

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let insights = await InsightsViewModel.shared.loadInsights(for: timeRange)

        return .result(
            dialog: "Your average sentiment this \(timeRange) is \(insights.averageSentiment)",
            view: SentimentChartSnippet(data: insights.sentimentData)
        )
    }
}
```

**User Benefits:**
- Voice queries for insights without opening app
- Shortcuts: "Show my weekly sentiment every Sunday"
- Siri Suggestions: "You usually check insights on Mondays"

##### 2. **Interactive Widgets with Charts** (High Priority)
**API:** WidgetKit interactive widgets + Swift Charts
**Use Case:** Home screen widget showing mini sentiment chart

**Implementation:**
```swift
struct SentimentChartWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SentimentChart", provider: Provider()) { entry in
            VStack {
                Text("This Week's Sentiment")
                Chart(entry.sentimentData) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Sentiment", point.score)
                    )
                }
                .frame(height: 100)

                Button(intent: OpenInsightsIntent()) {
                    Text("View Details")
                }
            }
        }
    }
}
```

**User Benefits:**
- Glanceable sentiment trends on home screen
- One-tap navigation to full insights
- Widget suggestions based on usage patterns

##### 3. **Live Activities for Sentiment Tracking** (Medium Priority)
**API:** ActivityKit with chart updates
**Use Case:** Real-time sentiment chart during journaling session

**Implementation:**
```swift
struct SentimentSessionActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var recentSentiments: [Double]
        var currentAverage: Double
    }
}

// Update after each thought capture
let state = SentimentSessionActivity.ContentState(
    recentSentiments: [0.6, 0.4, 0.8],
    currentAverage: 0.6
)
await activity.update(using: state)
```

**Dynamic Island Display:**
- **Compact:** Sentiment emoji (😊/😐/😔)
- **Expanded:** Mini trend chart of last 5 thoughts

**User Benefits:**
- See sentiment patterns emerge during capture session
- Gamification: "Keep the trend positive!"

##### 4. **Focus Filters for Chart Display** (Low Priority)
**API:** App Intents Focus Filters
**Use Case:** Show/hide specific chart types based on focus mode

**Implementation:**
```swift
struct InsightsFocusFilter: SetFocusFilterIntent {
    @Parameter(title: "Chart Types")
    var allowedCharts: [ChartType]

    func perform() async throws -> some IntentResult {
        InsightsViewModel.shared.visibleCharts = allowedCharts
        return .result()
    }
}
```

**User Benefits:**
- Work focus: Hide sentiment charts, show productivity metrics only
- Personal focus: Show all emotional insights
- Sleep focus: Hide all charts (distraction-free)

**Recommendation:** ✅ IMPLEMENT App Intents + Interactive Widgets (HIGH ROI for user engagement)

---

### 🎨 #14: STASH Brand Terminology & Logo Integration
**Status:** NOT STARTED
**Priority:** LOW (Phase 5 Polish)

#### iOS 26 Enhancement Opportunities

##### 1. **SF Symbols 6 Custom Symbols** (Medium Priority)
**API:** SF Symbols 6 custom symbol creation
**Use Case:** Create custom squirrel, acorn, and gem symbols

**Implementation:**
```swift
// Create custom symbols in SF Symbols app
// Export as .svg with proper annotations
// Import to Assets.xcassets/Symbols/

Image(systemName: "squirrel.stash") // Custom symbol
Image(systemName: "acorn.fill.stash") // Custom symbol
Image(systemName: "gem.shiny") // Custom symbol
```

**Benefits:**
- Consistent with system icons
- Automatic color/size/weight variants
- VoiceOver integration
- Dark mode support

##### 2. **App Icon Variants** (Low Priority)
**API:** Alternate app icons (iOS 18+, enhanced in iOS 26)
**Use Case:** Let users choose squirrel theme (pixel art, minimalist, geometric)

**Implementation:**
```swift
// Settings → Appearance → App Icon
UIApplication.shared.setAlternateIconName("PixelSquirrel") { error in
    if let error {
        print("Failed to set icon: \(error)")
    }
}
```

**Benefits:**
- User personalization
- Ties into squirrel-sona theme system (#13)
- No code changes, just asset variants

##### 3. **Localized Terminology with String Catalogs** (High Priority)
**API:** String Catalogs (Xcode 15+)
**Use Case:** Localize STASH terminology for international users

**Implementation:**
```swift
// Localizable.xcstrings (String Catalog)
{
  "capture.button.new": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "variations": {
          "branded": { "stringUnit": { "value": "Ooh, Shiny!" } },
          "generic": { "stringUnit": { "value": "New Note" } }
        }
      },
      "es": {
        "variations": {
          "branded": { "stringUnit": { "value": "¡Algo Brillante!" } },
          "generic": { "stringUnit": { "value": "Nueva Nota" } }
        }
      }
    }
  }
}
```

**Benefits:**
- Proper localization of squirrel metaphor (may not translate)
- Support for branded/generic toggle in all languages
- Centralized terminology management

##### 4. **Haptic Patterns for Squirrel Actions** (Low Priority)
**API:** Core Haptics custom patterns
**Use Case:** Custom haptic for "Stash It" button (acorn drop feeling)

**Implementation:**
```swift
import CoreHaptics

class SquirrelHaptics {
    let engine: CHHapticEngine

    func playStashHaptic() {
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0.1
            )
        ]

        let pattern = try? CHHapticPattern(events: events, parameters: [])
        let player = try? engine.makePlayer(with: pattern!)
        try? player?.start(atTime: 0)
    }
}
```

**Benefits:**
- Tactile personality
- Reinforces STASH brand through haptics
- Accessibility: confirms actions for low-vision users

**Recommendation:** ✅ IMPLEMENT String Catalogs + SF Symbols (foundational), defer haptics to Phase 5

---

### 🐿️ #13: STASH Squirrel-sona Personalization Epic
**Status:** NOT STARTED (Design phase)
**Priority:** MEDIUM (Phase 4-5)

#### iOS 26 Enhancement Opportunities

##### 1. **App Intents for Squirrel-sona Switching** (High Priority)
**API:** App Intents
**Use Case:** "Hey Siri, switch to Arcade theme" or "Hey Siri, make STASH chatty"

**Implementation:**
```swift
struct ChangeThemeIntent: AppIntent {
    static var title: LocalizedStringResource = "Change STASH Theme"

    @Parameter(title: "Theme")
    var theme: ThemeParameter

    func perform() async throws -> some IntentResult {
        ThemeEngine.shared.applyTheme(theme.value)
        return .result(dialog: "Switched to \(theme.displayName) theme")
    }
}

struct ChangeCommunicationStyleIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Communication Style"

    @Parameter(title: "Style")
    var style: CommunicationStyleParameter

    func perform() async throws -> some IntentResult {
        PersonalityEngine.shared.setStyle(style.value)
        return .result(dialog: "Now using \(style.displayName) style")
    }
}
```

**User Benefits:**
- Context-based automation: "When I start Work focus, use Minimal theme"
- Quick switching without navigating settings
- Shortcuts: "Morning routine" includes switching to Chatty mode

##### 2. **Focus Filters for Automatic Theme Switching** (High Priority)
**API:** App Intents Focus Filter
**Use Case:** Auto-switch to Minimal theme + Silent mode during Work focus

**Implementation:**
```swift
struct SquirrelsonaFocusFilter: SetFocusFilterIntent {
    @Parameter(title: "Theme")
    var theme: ThemeParameter

    @Parameter(title: "Communication Style")
    var style: CommunicationStyleParameter

    @Parameter(title: "Interaction Frequency")
    var frequency: InteractionFrequencyParameter

    func perform() async throws -> some IntentResult {
        ThemeEngine.shared.applyTheme(theme.value)
        PersonalityEngine.shared.setStyle(style.value)
        PersonalityEngine.shared.setFrequency(frequency.value)
        return .result()
    }
}
```

**User Benefits:**
- Work focus: Minimalist theme + Minimal style + Silent frequency
- Personal focus: Arcade theme + Chatty style + Always-on frequency
- Sleep focus: Dark theme + Silent style
- No manual switching needed

##### 3. **Live Preview with Interactive Widgets** (Medium Priority)
**API:** Interactive widget previews
**Use Case:** Test squirrel-sona settings from home screen widget

**Implementation:**
```swift
struct SquirrelsonaPreviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SquirrelPreview", provider: Provider()) { entry in
            VStack {
                Text("Your Squirrel-sona")

                // Live preview of current theme
                RoundedRectangle(cornerRadius: 8)
                    .fill(entry.theme.primaryColor)
                    .frame(height: 60)

                Text(entry.sampleMessage)
                    .font(.caption)

                // Quick theme switcher buttons
                HStack {
                    Button(intent: ChangeThemeIntent(theme: .minimalist)) {
                        Text("🎨")
                    }
                    Button(intent: ChangeThemeIntent(theme: .arcade)) {
                        Text("🕹️")
                    }
                    Button(intent: ChangeThemeIntent(theme: .dark)) {
                        Text("🌙")
                    }
                }
            }
        }
    }
}
```

**User Benefits:**
- Quick theme switching from home screen
- Visual preview of current squirrel-sona
- No need to open app to change settings

##### 4. **SharePlay for Squirrel-sona Sharing** (Low Priority)
**API:** SharePlay
**Use Case:** Share custom squirrel-sona with friends via FaceTime

**Implementation:**
```swift
struct SquirrelsonaActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "Check out my STASH squirrel-sona!"
        metadata.type = .generic
        return metadata
    }

    let themeData: ThemeExportData
    let styleData: CommunicationStyleData
}

// During FaceTime call
let activity = SquirrelsonaActivity(
    themeData: ThemeEngine.shared.exportCurrentTheme(),
    styleData: PersonalityEngine.shared.exportCurrentStyle()
)

try await activity.prepareForActivation()
try await activity.activate()
```

**User Benefits:**
- Social feature: "Here's how I personalized STASH!"
- Viral marketing: friends see customization and want it
- Community: popular squirrel-sonas become shareable

**Recommendation:** ✅ IMPLEMENT App Intents + Focus Filters (HIGH ROI for iOS 26 integration), defer SharePlay

---

### 🎨 #12: Personalization Settings UI - Squirrel-sona Customization
**Status:** NOT STARTED (depends on #10, #11)
**Priority:** MEDIUM (Phase 4C)

#### iOS 26 Enhancement Opportunities

##### 1. **Interactive Preview with SwiftUI Animations** (High Priority)
**API:** SwiftUI phase animator + keyframe animator (iOS 17+, enhanced iOS 26)
**Use Case:** Animated preview of theme/style changes

**Implementation:**
```swift
struct ThemePreviewCard: View {
    let theme: ThemeVariant
    @State private var isAnimating = false

    var body: some View {
        VStack {
            // Animated squirrel mascot
            Image(systemName: "squirrel.stash")
                .font(.system(size: 60))
                .foregroundStyle(theme.primaryColor)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(phase ? 1.2 : 1.0)
                        .rotationEffect(.degrees(phase ? 5 : -5))
                } animation: { _ in
                    .easeInOut(duration: 0.5)
                }

            Text(theme.sampleMessage)
                .font(.caption)
                .foregroundStyle(theme.textColor)
        }
        .padding()
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
    }
}
```

**User Benefits:**
- See theme come to life before selecting
- Engaging, delightful UX
- Clear visual distinction between themes

##### 2. **Haptic Feedback on Selection** (Medium Priority)
**API:** UIImpactFeedbackGenerator + Sensory Feedback (SwiftUI)
**Use Case:** Tactile confirmation when selecting theme or style

**Implementation:**
```swift
Button(action: {
    selectedTheme = .arcade
}) {
    ThemePreviewCard(theme: .arcade)
}
.sensoryFeedback(.selection, trigger: selectedTheme)
```

**User Benefits:**
- Tactile confirmation of selection
- Enhanced accessibility (non-visual feedback)
- Premium feel

##### 3. **State Restoration** (High Priority)
**API:** SwiftUI Scene Storage + State Restoration
**Use Case:** Remember personalization screen scroll position and previews

**Implementation:**
```swift
struct PersonalizationScreen: View {
    @SceneStorage("selectedThemeIndex") private var selectedIndex = 0
    @SceneStorage("scrollPosition") private var scrollPosition: String?

    var body: some View {
        ScrollView {
            // Theme carousel
        }
        .scrollPosition(id: $scrollPosition)
    }
}
```

**User Benefits:**
- Return to exact spot if app is backgrounded
- Smooth UX during customization
- iOS expected behavior

##### 4. **Accessibility Preview Mode** (High Priority)
**API:** Environment overrides for accessibility testing
**Use Case:** Preview themes with VoiceOver labels and Dynamic Type

**Implementation:**
```swift
struct PersonalizationScreen: View {
    @State private var previewAccessibility = false

    var body: some View {
        VStack {
            Toggle("Preview with Accessibility", isOn: $previewAccessibility)

            ThemePreviewCard(theme: selectedTheme)
                .environment(\.sizeCategory, previewAccessibility ? .accessibilityExtraExtraLarge : .large)
                .environment(\.accessibilityShowBoundingBoxes, previewAccessibility)
        }
    }
}
```

**User Benefits:**
- Users can verify accessibility of themes before applying
- Ensures WCAG compliance (#19 integration)
- Inclusive design

**Recommendation:** ✅ IMPLEMENT animated previews + accessibility mode (core to UX)

---

### 💬 #11: Communication Style Engine - Squirrel-sona Messaging
**Status:** NOT STARTED (depends on #10)
**Priority:** MEDIUM (Phase 4B)

#### iOS 26 Enhancement Opportunities

##### 1. **Foundation Models for Dynamic Message Generation** (High Priority)
**API:** Foundation Models (NLContextualEmbedding, NLLanguageModel)
**Use Case:** Generate personalized messages based on user preferences and context

**Implementation:**
```swift
import NaturalLanguage

class PersonalityEngine {
    static let shared = PersonalityEngine()

    func generateMessage(
        category: MessageCategory,
        style: MessageStyle,
        context: MessageContext
    ) async -> String {
        // Use Foundation Models to generate contextual message
        let session = NLLanguageModelSession(
            languageModel: .defaultModel,
            options: .init()
        )

        let prompt = """
        Generate a \(style.rawValue) message for:
        Category: \(category)
        User context: \(context.description)
        Constraints: \(style.constraints)
        """

        let result = try? await session.generateText(
            for: prompt,
            maxTokens: 50
        )

        return result?.generatedText ?? fallbackMessage(category, style)
    }

    // Context-aware messaging
    func thoughtSavedMessage(context: MessageContext) async -> String {
        let style = UserDefaults.communicationStyle

        switch style {
        case .chatty:
            // Use Foundation Models for variety
            return await generateMessage(
                category: .success(.thoughtSaved),
                style: .chatty,
                context: context
            )
            // Possible outputs:
            // - Morning: "Great start to the day! Thought saved ✨"
            // - Evening: "Nice reflection! Saved that thought 🌙"
            // - After many thoughts: "You're on a roll! Another one saved!"

        case .minimal:
            return "→ Saved"
        }
    }
}
```

**User Benefits:**
- Messages never feel repetitive
- Context-aware (time of day, user state, thought frequency)
- Truly personalized communication
- Foundation Models = on-device = privacy

##### 2. **App Intents for Style Switching** (Medium Priority)
**API:** App Intents
**Use Case:** "Hey Siri, make STASH more chatty" or "Hey Siri, switch to minimal mode"

**Implementation:**
```swift
struct SetCommunicationStyleIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Communication Style"

    @Parameter(title: "Style")
    var style: CommunicationStyleParameter

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PersonalityEngine.shared.setStyle(style.value)

        let confirmation = await PersonalityEngine.shared.styleChangedMessage(to: style.value)
        return .result(dialog: confirmation)
    }
}

// Example dialogs (style-appropriate):
// Chatty: "You got it! I'll be more talkative now 🎉"
// Minimal: "→ Chatty mode"
```

**User Benefits:**
- Voice control of personality
- Automation: "When Work focus starts, set STASH to minimal"
- Accessibility: users with motor impairments can switch styles via voice

##### 3. **String Catalogs with Variations** (High Priority)
**API:** String Catalogs with variations (Xcode 15+)
**Use Case:** Centralized management of all message variants

**Implementation:**
```swift
// Localizable.xcstrings
{
  "message.thought_saved": {
    "localizations": {
      "en": {
        "variations": {
          "chatty": {
            "stringUnit": { "value": "Nice! Your thought is saved ✨" }
          },
          "minimal": {
            "stringUnit": { "value": "→ Saved" }
          },
          "formal": {
            "stringUnit": { "value": "Thought persisted successfully." }
          },
          "playful": {
            "stringUnit": { "value": "*chittering* Shiny thought stashed! 🌰" }
          }
        }
      }
    }
  }
}
```

**Benefits:**
- Single source of truth for all message variants
- Localization support for all styles
- Easy to add new styles (Phase 5: Formal, Playful, Silent)
- Compile-time safety

##### 4. **A/B Testing with TipKit** (Low Priority)
**API:** TipKit (iOS 17+)
**Use Case:** Educate users about communication style options

**Implementation:**
```swift
import TipKit

struct CommunicationStyleTip: Tip {
    var title: Text {
        Text("Customize How STASH Talks to You")
    }

    var message: Text? {
        Text("Try different communication styles: Chatty for encouragement, Minimal for focus")
    }

    var actions: [Action] {
        [
            Action(id: "customize", title: "Customize Now")
        ]
    }
}

// Show tip after 5 successful thought captures
struct CaptureScreen: View {
    let styleTip = CommunicationStyleTip()

    var body: some View {
        VStack {
            TipView(styleTip)
            // ... rest of capture UI
        }
        .onAppear {
            if viewModel.thoughtCount >= 5 {
                styleTip.invalidate(reason: .actionPerformed)
            }
        }
    }
}
```

**User Benefits:**
- Discoverable feature
- Contextual education (after user understands app)
- Increased customization adoption

**Recommendation:** ✅ IMPLEMENT Foundation Models + String Catalogs (HIGH ROI for personalization quality)

---

### 🎨 #10: Theme System Architecture - Squirrel-sona Foundation
**Status:** NOT STARTED
**Priority:** MEDIUM (Phase 4A Foundation)

#### iOS 26 Enhancement Opportunities

##### 1. **SwiftUI Observable Macro for Theme State** (High Priority)
**API:** @Observable macro (iOS 17+)
**Use Case:** Reactive theme changes without Combine overhead

**Implementation:**
```swift
import Observation

@Observable
class ThemeEngine {
    static let shared = ThemeEngine()

    var currentTheme: ThemeVariant = MinimalistTheme() {
        didSet {
            // Automatic UI updates via @Observable
            saveTheme()
        }
    }

    func applyTheme(_ theme: ThemeVariant) {
        currentTheme = theme
    }

    private func saveTheme() {
        UserDefaults.standard.set(
            currentTheme.name,
            forKey: "selectedTheme"
        )
    }
}

// Usage in views (no @Published or @StateObject needed)
struct BrowseScreen: View {
    @Environment(ThemeEngine.self) private var themeEngine

    var body: some View {
        VStack {
            // Automatically updates when theme changes
        }
        .background(themeEngine.currentTheme.backgroundColor)
    }
}
```

**Benefits:**
- Simpler than Combine/@Published
- Better performance (fine-grained tracking)
- Modern Swift concurrency pattern
- Less boilerplate

##### 2. **Color Assets with Appearance Variants** (High Priority)
**API:** Asset Catalog color sets with Any/Light/Dark variants
**Use Case:** Automatic dark mode support for all themes

**Implementation:**
```swift
// Assets.xcassets/Colors/
// - MinimalistPrimary (Light: #F5F5F5, Dark: #1C1C1E)
// - ArcadePrimary (Light: #FF00FF, Dark: #DD00DD)
// - DarkModePrimary (Always: #000000)

struct MinimalistTheme: ThemeVariant {
    var primaryColor: Color {
        Color("MinimalistPrimary") // Auto light/dark
    }
}
```

**Benefits:**
- Automatic dark mode support
- Centralized color management
- Interface Builder support
- ColorSync profile support (P3 wide color)

##### 3. **Dynamic Type Scaling with Custom Fonts** (High Priority)
**API:** SwiftUI scaledMetric property wrapper
**Use Case:** Theme-specific fonts that scale with Dynamic Type

**Implementation:**
```swift
struct ArcadeTheme: ThemeVariant {
    @ScaledMetric(relativeTo: .largeTitle) var headingSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) var bodySize: CGFloat = 17

    var headingFont: Font {
        .custom("PressStart2P", size: headingSize)
            .weight(.bold)
    }

    var bodyFont: Font {
        .custom("PressStart2P", size: bodySize)
            .weight(.regular)
    }
}
```

**Benefits:**
- Accessibility compliance (#19)
- Custom fonts scale properly
- Respects user preferences
- No manual calculation needed

##### 4. **State Restoration for Theme Selection** (Medium Priority)
**API:** App Storage + Scene Storage
**Use Case:** Persist theme across app launches and restore during development

**Implementation:**
```swift
@Observable
class ThemeEngine {
    @AppStorage("selectedTheme") private var themeName: String = "minimalist"

    var currentTheme: ThemeVariant {
        get {
            switch themeName {
            case "arcade": return ArcadeTheme()
            case "dark": return DarkModeTheme()
            default: return MinimalistTheme()
            }
        }
        set {
            themeName = newValue.name
        }
    }
}
```

**Benefits:**
- Automatic persistence
- No manual UserDefaults management
- SwiftUI property wrapper benefits
- iCloud sync support (if enabled)

##### 5. **Swift Testing for Theme System** (High Priority)
**API:** Swift Testing framework
**Use Case:** Test theme application and WCAG compliance

**Implementation:**
```swift
import Testing
@testable import STASH

@Suite("Theme System Tests")
struct ThemeTests {

    @Test("All themes meet WCAG AA contrast")
    func testThemeContrast() throws {
        let themes: [ThemeVariant] = [
            MinimalistTheme(),
            ArcadeTheme(),
            DarkModeTheme()
        ]

        for theme in themes {
            let contrastRatio = theme.textColor.contrastRatio(
                with: theme.backgroundColor
            )
            #expect(contrastRatio >= 4.5, "Theme \(theme.name) fails WCAG AA")
        }
    }

    @Test("Theme persistence works correctly")
    func testThemePersistence() async throws {
        let engine = ThemeEngine()

        engine.applyTheme(ArcadeTheme())
        #expect(UserDefaults.standard.string(forKey: "selectedTheme") == "arcade")

        // Simulate app restart
        let newEngine = ThemeEngine()
        #expect(newEngine.currentTheme.name == "arcade")
    }

    @Test("Theme application is instant (<100ms)")
    func testThemePerformance() async throws {
        let engine = ThemeEngine()

        let start = ContinuousClock.now
        engine.applyTheme(DarkModeTheme())
        let duration = ContinuousClock.now - start

        #expect(duration < .milliseconds(100))
    }
}
```

**Benefits:**
- Automated regression testing
- Performance validation
- Accessibility compliance verification
- CI/CD integration

**Recommendation:** ✅ IMPLEMENT @Observable + Color Assets + Swift Testing (CRITICAL foundation)

---

### 📊 #9: iOS 26 Modernization Epic
**Status:** IN PROGRESS (tracking issue for modernization)
**Priority:** HIGH (ongoing)

#### Current Progress
This epic is the meta-issue tracking all iOS 26 modernization efforts. Based on the analysis:

**Phase 1 Critical Items:**
1. Privacy Manifests - NOT STARTED
2. Swift 6 Concurrency - NOT STARTED
3. Xcode Previews - PARTIAL (some working)
4. SwiftUI Modernization - NOT STARTED

**Phase 2-4 High Priority:**
- App Intents - NOT STARTED (but critical for #13, #18, #20)
- Live Activities - NOT STARTED
- Interactive Widgets - NOT STARTED
- Swift Charts - ✅ IMPLEMENTED (#18)

#### Recommendations for #9

##### Immediate Next Steps (Week 1-2):

1. **Create Privacy Manifest** (1-2 days)
```xml
<!-- PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string> <!-- App functionality -->
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string> <!-- Document management -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

2. **Enable Swift 6 Concurrency Checking** (3-5 days)
```swift
// Build Settings → Swift Compiler
SWIFT_STRICT_CONCURRENCY = complete

// Fix common issues:
// - Mark all ViewModels as @MainActor
// - Ensure Core Data operations are on correct context
// - Add Sendable conformance where needed
```

3. **Fix All Xcode Previews** (2-3 days)
```swift
// Add preview data to all models
extension ThoughtEntity {
    static var preview: ThoughtEntity {
        let context = PersistenceService.preview.container.viewContext
        let thought = ThoughtEntity(context: context)
        thought.id = UUID()
        thought.content = "Sample thought"
        thought.timestamp = Date()
        return thought
    }
}

// Add previews to all views
#Preview("Browse Screen") {
    BrowseScreen(viewModel: BrowseViewModel.preview)
}
```

##### Phase 2 Quick Win (Week 3):
4. **App Intents Foundation** (5-7 days)
Create basic infrastructure for #13, #18, #20 to build on:

```swift
// Sources/AppIntents/AppIntentsProvider.swift
struct STASHAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureThoughtIntent(),
            phrases: [
                "Capture a thought in \(.applicationName)",
                "New note in \(.applicationName)"
            ],
            shortTitle: "Capture Thought",
            systemImageName: "text.badge.plus"
        )
    }
}
```

**Recommendation:** ✅ Complete Phase 1 items before App Store submission

---

### 🤖 #8: Refine Foundation Models date/time parsing and classification
**Status:** ✅ FUNCTIONALLY COMPLETE (refinements needed)
**Priority:** MEDIUM

#### Current Implementation
- Date/time parsing working
- AI classification working
- Fallback to NSDataDetector
- Concurrent request prevention

#### iOS 26 Enhancement Opportunities

##### 1. **NLContextualEmbedding for Improved Classification** (High Priority)
**API:** Natural Language Contextual Embedding (iOS 26+)
**Use Case:** Better semantic understanding of thought types

**Implementation:**
```swift
import NaturalLanguage

extension ClassificationService {
    func classifyWithEmbeddings(content: String) async -> ThoughtType {
        let embedding = NLEmbedding.contextualEmbedding(
            for: .english,
            revision: .latest
        )

        // Generate embedding for thought content
        let thoughtVector = try? embedding?.vector(for: content)

        // Compare to type exemplars
        let typeExemplars: [ThoughtType: String] = [
            .reminder: "don't forget to pick up milk tomorrow",
            .idea: "what if we built a feature that",
            .question: "how does this work",
            .event: "meeting with sarah on tuesday",
            .note: "interesting observation about"
        ]

        var bestMatch: (type: ThoughtType, similarity: Double) = (.note, 0.0)

        for (type, exemplar) in typeExemplars {
            if let exemplarVector = try? embedding?.vector(for: exemplar),
               let thoughtVector = thoughtVector {
                let similarity = cosineSimilarity(thoughtVector, exemplarVector)
                if similarity > bestMatch.similarity {
                    bestMatch = (type, similarity)
                }
            }
        }

        return bestMatch.similarity > 0.7 ? bestMatch.type : .note
    }
}
```

**Benefits:**
- More accurate classification than string matching
- Better handling of edge cases
- Improves over time with more exemplars
- On-device = privacy

##### 2. **NLLanguageRecognizer for Multi-language Support** (Medium Priority)
**API:** Natural Language Language Recognizer
**Use Case:** Detect language and use appropriate parsing rules

**Implementation:**
```swift
extension ClassificationService {
    func detectLanguageAndClassify(content: String) async -> Classification {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(content)

        let dominantLanguage = recognizer.dominantLanguage ?? .english

        // Use language-specific classification prompts
        let prompt = classificationPrompt(for: dominantLanguage, content: content)
        return await classifyWithPrompt(prompt)
    }
}
```

**Benefits:**
- International user support
- More accurate classification for non-English
- Addresses localization (#14 integration)

##### 3. **Swift Testing for Classification Edge Cases** (High Priority)
**API:** Swift Testing framework
**Use Case:** Test all edge cases mentioned in #8

**Implementation:**
```swift
import Testing
@testable import STASH

@Suite("Classification Tests")
struct ClassificationTests {

    @Test("Ambiguous times default to next occurrence")
    func testAmbiguousTime() async throws {
        let service = ClassificationService()

        let result = await service.parseDateTime("at 9")
        let hour = Calendar.current.component(.hour, from: result.date!)

        // Should default to next 9am if before 9am, or 9pm if after 9am
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)

        if currentHour < 9 {
            #expect(hour == 9)
        } else if currentHour < 21 {
            #expect(hour == 21)
        } else {
            #expect(hour == 9) // Next day
        }
    }

    @Test("'tonight' parses to today at evening")
    func testTonight() async throws {
        let service = ClassificationService()
        let result = await service.parseDateTime("dinner tonight")

        #expect(Calendar.current.isDateInToday(result.date!))
        let hour = Calendar.current.component(.hour, from: result.date!)
        #expect(hour >= 18) // Evening time
    }

    @Test("Misspellings are handled gracefully")
    func testMisspellings() async throws {
        let service = ClassificationService()

        let tests = [
            "remindre me tomorrow", // Missing 'i'
            "meetting on tuesday",  // Double 't'
            "questoin about code"   // Transposed 'io'
        ]

        for test in tests {
            let result = await service.classify(test)
            #expect(result.type != .note) // Should still classify
        }
    }

    @Test("Passwords not classified as sensitive")
    func testPasswordDetection() async throws {
        let service = ClassificationService()
        let result = await service.classify("password is abc123")

        #expect(result.containsSensitiveData == true)
        #expect(result.suggestEncryption == true)
    }
}
```

**Benefits:**
- Addresses all known edge cases from #8
- Regression prevention
- Documents expected behavior
- CI/CD integration

##### 4. **Query Rewriting for Typo Correction** (Medium Priority)
**API:** Foundation Models text generation
**Use Case:** Fix typos before classification (addresses #9 Phase 3)

**Implementation:**
```swift
extension ClassificationService {
    func correctTypos(_ text: String) async -> String {
        let session = NLLanguageModelSession(
            languageModel: .defaultModel,
            options: .init()
        )

        let prompt = """
        Fix any spelling errors in the following text, preserving meaning:
        "\(text)"
        """

        let result = try? await session.generateText(
            for: prompt,
            maxTokens: text.count + 20
        )

        return result?.generatedText ?? text
    }

    func classifyWithCorrection(content: String) async -> Classification {
        let corrected = await correctTypos(content)
        return await classify(corrected)
    }
}
```

**Benefits:**
- Better classification accuracy
- User-friendly (typos don't break parsing)
- Leverages Foundation Models (already integrated)

**Recommendation:** ✅ IMPLEMENT Swift Testing + NLContextualEmbedding (high ROI for quality)

---

### 💊 #7: Medication Management Module
**Status:** NOT STARTED
**Priority:** HIGH (ADHD-critical feature)

#### iOS 26 Enhancement Opportunities

##### 1. **App Intents for Medication Logging** (CRITICAL)
**API:** App Intents
**Use Case:** "Hey Siri, I took my Adderall" (fastest possible logging)

**Implementation:**
```swift
struct LogMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Medication Dose"

    @Parameter(title: "Medication")
    var medication: MedicationEntity

    @Parameter(title: "Time", default: .now)
    var time: Date

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MedicationService.shared.logDose(
            medication: medication,
            time: time,
            status: .taken
        )

        return .result(dialog: "Logged \(medication.name) at \(time.formatted(.relative))")
    }
}

// Even better: Suggested shortcuts
struct MedicationAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMedicationIntent(),
            phrases: [
                "I took my \(.applicationName) medication",
                "Log medication in \(.applicationName)"
            ],
            shortTitle: "Log Medication",
            systemImageName: "pills.fill"
        )
    }
}
```

**User Benefits:**
- ZERO friction logging (Siri from lock screen)
- Hands-free (critical for ADHD)
- Suggested shortcuts learn user patterns
- No need to open app

##### 2. **Live Activities for Dose Reminders** (CRITICAL)
**API:** ActivityKit with Live Activities
**Use Case:** Persistent, escalating reminders in Dynamic Island

**Implementation:**
```swift
struct MedicationReminderActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var medicationName: String
        var scheduledTime: Date
        var escalationLevel: Int
    }
}

// Start reminder at dose time
let attributes = MedicationReminderActivity(
    medicationName: "Adderall XR 20mg"
)
let initialState = MedicationReminderActivity.ContentState(
    medicationName: "Adderall XR 20mg",
    scheduledTime: Date(),
    escalationLevel: 0
)

let activity = try await Activity<MedicationReminderActivity>.request(
    attributes: attributes,
    content: .init(state: initialState, staleDate: nil)
)

// Escalate every 15 minutes
Task {
    for level in 1...4 {
        try await Task.sleep(for: .minutes(15))
        let newState = MedicationReminderActivity.ContentState(
            medicationName: "Adderall XR 20mg",
            scheduledTime: Date().addingTimeInterval(-15 * 60 * Double(level)),
            escalationLevel: level
        )
        await activity.update(using: newState)
    }
}
```

**Dynamic Island Display:**
- **Level 0 (Compact):** 💊 "8:00 AM"
- **Level 1 (Compact):** 💊 "⚠️ 8:15"
- **Level 2 (Expanded):** "Adderall XR - Take now (30min late)"
- **Level 3+:** Pulsing red icon

**Interactive Buttons:**
```swift
ActivityConfiguration(for: MedicationReminderActivity.self) { context in
    VStack {
        Text("\(context.state.medicationName)")
        Text("Scheduled: \(context.state.scheduledTime.formatted())")

        HStack {
            Button(intent: LogMedicationIntent(medication: context.attributes.medication)) {
                Label("Take Now", systemImage: "checkmark")
            }
            .tint(.green)

            Button(intent: SnoozeMedicationIntent(minutes: 15)) {
                Label("Snooze 15min", systemImage: "clock")
            }
            .tint(.orange)
        }
    }
}
```

**User Benefits:**
- CANNOT miss (Dynamic Island always visible)
- One-tap logging from lock screen
- Escalation prevents ignoring
- No notification fatigue (Live Activity vs 10 notifications)

##### 3. **HealthKit Integration for Medication Logging** (High Priority)
**API:** HealthKit medication samples (iOS 16+)
**Use Case:** Log doses to Health app for cross-app visibility

**Implementation:**
```swift
import HealthKit

extension MedicationService {
    func logDoseToHealthKit(
        medication: MedicationEntity,
        time: Date
    ) async throws {
        let healthStore = HKHealthStore()

        // Request authorization
        let medicationType = HKObjectType.clinicalType(
            forIdentifier: .medicationRecord
        )!

        try await healthStore.requestAuthorization(
            toShare: [medicationType],
            read: []
        )

        // Create medication sample
        let sample = HKClinicalRecord(
            type: medicationType,
            // ... medication data
        )

        try await healthStore.save(sample)
    }
}
```

**User Benefits:**
- Integration with Apple Health
- Doctor visibility (if sharing Health data)
- Correlate with other health metrics
- Future: Apple Watch complications

##### 4. **Focus Filters for Medication Reminders** (Medium Priority)
**API:** App Intents Focus Filters
**Use Case:** Suppress medication reminders during Sleep focus

**Implementation:**
```swift
struct MedicationReminderFocusFilter: SetFocusFilterIntent {
    @Parameter(title: "Allow Critical Only")
    var criticalOnly: Bool

    func perform() async throws -> some IntentResult {
        MedicationService.shared.focusMode = criticalOnly ? .criticalOnly : .all
        return .result()
    }
}
```

**User Benefits:**
- Sleep focus: Suppress non-critical meds
- Work focus: Only show work-related supplements
- Personal focus: All medications

##### 5. **Swift Charts for Adherence Tracking** (High Priority)
**API:** Swift Charts
**Use Case:** Visualize adherence patterns (integrates with #18)

**Implementation:**
```swift
struct MedicationAdherenceChart: View {
    let logs: [MedicationLog]

    var body: some View {
        Chart(logs) { log in
            BarMark(
                x: .value("Date", log.scheduledTime, unit: .day),
                y: .value("Status", log.status == .taken ? 1 : 0)
            )
            .foregroundStyle(log.status == .taken ? .green : .red)
        }
        .chartYAxis {
            AxisMarks(values: [0, 1]) { value in
                AxisValueLabel(value.as(Int.self) == 1 ? "Taken" : "Missed")
            }
        }
    }
}
```

**User Benefits:**
- Visual adherence history
- Identify patterns (always miss weekends?)
- Motivation (see streaks)
- Share with doctor

##### 6. **Interactive Widgets for Quick Logging** (High Priority)
**API:** WidgetKit interactive widgets
**Use Case:** Log medication from home screen widget

**Implementation:**
```swift
struct MedicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MedicationTracker", provider: Provider()) { entry in
            VStack {
                ForEach(entry.medications) { med in
                    HStack {
                        Text(med.name)
                        Spacer()
                        if med.isDueNow {
                            Button(intent: LogMedicationIntent(medication: med)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Text(med.nextDose.formatted(.relative))
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}
```

**User Benefits:**
- Fastest possible logging (no app open)
- See all medications at a glance
- Next dose countdown
- Lock screen widget support

**Recommendation:** ✅ IMPLEMENT App Intents + Live Activities + HealthKit (CRITICAL for ADHD users)

---

### 🧪 #6: Add Unit Tests for ViewModels and Services
**Status:** NOT STARTED
**Priority:** MEDIUM (tech debt, but important)

#### iOS 26 Enhancement Opportunities

##### 1. **Swift Testing Framework** (CRITICAL)
**API:** Swift Testing (Xcode 16+)
**Use Case:** Replace XCTest with modern, Swift-native testing

**Implementation:**
```swift
import Testing
@testable import STASH

@Suite("CaptureViewModel Tests")
struct CaptureViewModelTests {

    @Test("Thought content is trimmed before saving")
    func testContentTrimming() async throws {
        let viewModel = CaptureViewModel.testInstance

        viewModel.content = "  test thought  "
        await viewModel.saveThought()

        #expect(viewModel.savedContent == "test thought")
    }

    @Test("Empty thoughts are not saved")
    func testEmptyThought() async throws {
        let viewModel = CaptureViewModel.testInstance

        viewModel.content = "   "
        await viewModel.saveThought()

        #expect(viewModel.error != nil)
        #expect(viewModel.thoughtWasSaved == false)
    }

    @Test("Classification is triggered automatically", .tags(.ai))
    func testAutoClassification() async throws {
        let viewModel = CaptureViewModel.testInstance

        viewModel.content = "remind me to buy milk tomorrow"
        await viewModel.saveThought()

        #expect(viewModel.classification?.type == .reminder)
        #expect(viewModel.classification?.parsedDate != nil)
    }

    @Test("Voice capture toggles correctly")
    func testVoiceToggle() {
        let viewModel = CaptureViewModel.testInstance

        #expect(viewModel.isRecording == false)

        viewModel.toggleVoiceCapture()
        #expect(viewModel.isRecording == true)

        viewModel.toggleVoiceCapture()
        #expect(viewModel.isRecording == false)
    }
}

@Suite("BrowseViewModel Tests")
struct BrowseViewModelTests {

    @Test("Filter updates thought list")
    func testFilterApplication() async throws {
        let viewModel = BrowseViewModel.testInstance

        viewModel.filter = .type(.idea)
        await viewModel.loadThoughts()

        #expect(viewModel.thoughts.allSatisfy { $0.type == .idea })
    }

    @Test("Search filters by content")
    func testSearchFiltering() async throws {
        let viewModel = BrowseViewModel.testInstance

        viewModel.searchQuery = "medication"
        await viewModel.search()

        #expect(viewModel.searchResults.allSatisfy {
            $0.content.localizedCaseInsensitiveContains("medication")
        })
    }
}

@Suite("Classification Service Tests", .tags(.ai, .integration))
struct ClassificationServiceTests {

    @Test("Reminder detection works")
    func testReminderDetection() async throws {
        let service = ClassificationService()

        let result = await service.classify("don't forget to call mom")

        #expect(result.type == .reminder)
        #expect(result.confidence > 0.7)
    }

    @Test("Date parsing extracts correct date")
    func testDateParsing() async throws {
        let service = ClassificationService()

        let result = await service.parseDateTime("meeting tomorrow at 3pm")

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let hour = Calendar.current.component(.hour, from: result.date!)

        #expect(Calendar.current.isDate(result.date!, inSameDayAs: tomorrow))
        #expect(hour == 15)
    }
}
```

**Benefits:**
- Modern syntax (easier to read/write)
- Better error messages
- Parameterized tests
- Parallel execution by default
- Tags for test organization
- No XCTestCase inheritance needed

##### 2. **Preview Data for Testing** (High Priority)
**API:** SwiftUI preview data
**Use Case:** Reusable test fixtures for ViewModels

**Implementation:**
```swift
extension CaptureViewModel {
    static var testInstance: CaptureViewModel {
        CaptureViewModel(
            thoughtRepository: ThoughtRepository.preview,
            classificationService: ClassificationService.mock
        )
    }

    static var preview: CaptureViewModel {
        let vm = testInstance
        vm.content = "Sample thought content"
        return vm
    }
}

extension ThoughtRepository {
    static var preview: ThoughtRepository {
        ThoughtRepository(
            persistenceService: PersistenceService.preview
        )
    }
}

extension ClassificationService {
    static var mock: ClassificationService {
        ClassificationService(useMockResponses: true)
    }
}
```

**Benefits:**
- Shared test data between tests and previews
- Consistent fixtures
- Easy to maintain
- DRY principle

##### 3. **Coverage Tools Integration** (Medium Priority)
**API:** Xcode Code Coverage
**Use Case:** Track and improve test coverage to 70% goal

**Implementation:**
```bash
# Enable code coverage in scheme settings
# Xcode → Edit Scheme → Test → Options → Code Coverage

# Run tests with coverage
xcodebuild test \
  -scheme STASH \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES

# Generate coverage report
xcrun xccov view \
  --report \
  --json \
  DerivedData/.../Coverage.xcresult > coverage.json
```

**CI/CD Integration:**
```yaml
# .github/workflows/tests.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme STASH \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -enableCodeCoverage YES
      - name: Check coverage
        run: |
          COVERAGE=$(xcrun xccov view --report coverage.xcresult | grep "STASH" | awk '{print $4}')
          if (( $(echo "$COVERAGE < 70.0" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 70% threshold"
            exit 1
          fi
```

**Benefits:**
- Automated coverage tracking
- Prevent coverage regressions
- Visual coverage in Xcode
- CI/CD enforcement

##### 4. **Mock Services for Isolated Testing** (High Priority)
**API:** Swift protocols + test doubles
**Use Case:** Test ViewModels without dependencies

**Implementation:**
```swift
protocol ClassificationServiceProtocol {
    func classify(_ content: String) async -> Classification
    func parseDateTime(_ content: String) async -> DateTimeParseResult
}

class MockClassificationService: ClassificationServiceProtocol {
    var classifyCallCount = 0
    var classifyResponse: Classification?

    func classify(_ content: String) async -> Classification {
        classifyCallCount += 1
        return classifyResponse ?? Classification(type: .note, confidence: 0.5)
    }

    func parseDateTime(_ content: String) async -> DateTimeParseResult {
        // Return predictable test data
        return DateTimeParseResult(date: Date(), confidence: 0.9)
    }
}

@Suite("ViewModel Dependency Injection Tests")
struct DependencyTests {

    @Test("ViewModel uses injected service")
    func testServiceInjection() async throws {
        let mockService = MockClassificationService()
        mockService.classifyResponse = Classification(type: .reminder, confidence: 0.95)

        let viewModel = CaptureViewModel(
            classificationService: mockService
        )

        viewModel.content = "test"
        await viewModel.saveThought()

        #expect(mockService.classifyCallCount == 1)
        #expect(viewModel.classification?.type == .reminder)
    }
}
```

**Benefits:**
- Isolated unit tests
- Predictable test results
- Fast tests (no network/disk I/O)
- Easy to test error conditions

**Recommendation:** ✅ IMPLEMENT Swift Testing + Mock Services (essential for 70% coverage goal)

---

### 📦 #5: Bulk Actions - Select Multiple Thoughts
**Status:** NOT STARTED
**Priority:** LOW (nice-to-have)

#### iOS 26 Enhancement Opportunities

##### 1. **SwiftUI Selection APIs** (High Priority)
**API:** SwiftUI List selection binding
**Use Case:** Native multi-select with minimal code

**Implementation:**
```swift
struct BrowseScreen: View {
    @State private var selection = Set<UUID>()
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List(selection: $selection) {
            ForEach(viewModel.thoughts) { thought in
                ThoughtRowView(thought: thought)
            }
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }

            if editMode == .active {
                ToolbarItem(placement: .bottomBar) {
                    bulkActionMenu
                }
            }
        }
    }

    var bulkActionMenu: some View {
        HStack {
            Button(role: .destructive) {
                viewModel.deleteThoughts(ids: selection)
            } label: {
                Label("Delete (\(selection.count))", systemImage: "trash")
            }

            Menu {
                ForEach(Tag.common) { tag in
                    Button {
                        viewModel.applyTag(tag, to: selection)
                    } label: {
                        Label(tag.name, systemImage: "tag")
                    }
                }
            } label: {
                Label("Tag (\(selection.count))", systemImage: "tag.fill")
            }

            Button {
                viewModel.archiveThoughts(ids: selection)
            } label: {
                Label("Archive (\(selection.count))", systemImage: "archivebox")
            }
        }
    }
}
```

**Benefits:**
- Native iOS multi-select UX
- Automatic checkmark UI
- Swipe gestures still work
- Accessibility built-in

##### 2. **App Intents for Bulk Operations** (Medium Priority)
**API:** App Intents
**Use Case:** "Hey Siri, archive all thoughts from last week"

**Implementation:**
```swift
struct BulkArchiveIntent: AppIntent {
    static var title: LocalizedStringResource = "Archive Thoughts"

    @Parameter(title: "Date Range")
    var dateRange: DateRangeParameter

    @Parameter(title: "Filters")
    var filters: ThoughtFilterParameter?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let thoughts = await ThoughtRepository.shared.fetchThoughts(
            in: dateRange,
            matching: filters
        )

        await ThoughtRepository.shared.archive(thoughts)

        return .result(dialog: "Archived \(thoughts.count) thoughts")
    }
}
```

**User Benefits:**
- Voice-based bulk operations
- Automation: "Archive all thoughts from last month every 1st"
- Shortcuts: Complex multi-step cleanup workflows

##### 3. **Undo/Redo Support** (High Priority)
**API:** UndoManager integration
**Use Case:** Undo accidental bulk delete

**Implementation:**
```swift
extension BrowseViewModel {
    func deleteThoughts(ids: Set<UUID>) {
        let deletedThoughts = thoughts.filter { ids.contains($0.id) }

        // Register undo
        undoManager?.registerUndo(withTarget: self) { viewModel in
            viewModel.restoreThoughts(deletedThoughts)
        }
        undoManager?.setActionName("Delete \(ids.count) thoughts")

        // Perform delete
        thoughtRepository.delete(ids: ids)
    }

    func restoreThoughts(_ thoughts: [Thought]) {
        undoManager?.registerUndo(withTarget: self) { viewModel in
            viewModel.deleteThoughts(ids: Set(thoughts.map(\.id)))
        }

        thoughtRepository.restore(thoughts)
    }
}
```

**User Benefits:**
- Safety net for bulk operations
- Shake to undo (iOS standard)
- Multi-level undo
- Confidence to use bulk delete

##### 4. **Confirmation Alerts for Destructive Actions** (High Priority)
**API:** SwiftUI confirmation dialog
**Use Case:** Confirm before bulk delete

**Implementation:**
```swift
@State private var showDeleteConfirmation = false

Button(role: .destructive) {
    showDeleteConfirmation = true
} label: {
    Label("Delete (\(selection.count))", systemImage: "trash")
}
.confirmationDialog(
    "Delete \(selection.count) thoughts?",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("Delete", role: .destructive) {
        viewModel.deleteThoughts(ids: selection)
        selection.removeAll()
        editMode = .inactive
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This action cannot be undone.")
}
```

**User Benefits:**
- Prevent accidents
- Clear consequences
- Standard iOS pattern

**Recommendation:** ✅ IMPLEMENT SwiftUI selection + Undo support (critical for safety)

---

### 🔍 #4: Search and Filter - Advanced Search
**Status:** NOT STARTED
**Priority:** MEDIUM

#### iOS 26 Enhancement Opportunities

##### 1. **Semantic Search with NLEmbedding** (CRITICAL)
**API:** Natural Language Contextual Embedding
**Use Case:** Search by meaning, not just keywords (related to #9 Phase 4)

**Implementation:**
```swift
import NaturalLanguage

class SemanticSearchService {
    private let embedding = NLEmbedding.contextualEmbedding(
        for: .english,
        revision: .latest
    )

    func search(query: String, in thoughts: [Thought]) async -> [Thought] {
        guard let queryVector = try? embedding?.vector(for: query) else {
            return [] // Fallback to keyword search
        }

        // Compute similarity for each thought
        var results: [(thought: Thought, similarity: Double)] = []

        for thought in thoughts {
            if let thoughtVector = try? embedding?.vector(for: thought.content) {
                let similarity = cosineSimilarity(queryVector, thoughtVector)
                results.append((thought, similarity))
            }
        }

        // Sort by similarity, return top results
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(20)
            .map(\.thought)
    }

    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
```

**Example:**
- Query: "productivity tips"
- Matches: "focus techniques", "time management ideas", "efficiency hacks"
- Traditional search would miss these!

**User Benefits:**
- Find thoughts by concept, not exact words
- Better than Core Data predicates
- Privacy-preserving (on-device)

##### 2. **Spotlight Integration** (High Priority)
**API:** Core Spotlight
**Use Case:** Search thoughts from iOS Spotlight

**Implementation:**
```swift
import CoreSpotlight
import MobileCoreServices

extension ThoughtRepository {
    func indexThoughtForSpotlight(_ thought: Thought) {
        let attributeSet = CSSearchableItemAttributeSet(
            contentType: .text
        )

        attributeSet.title = thought.content.prefix(100).description
        attributeSet.contentDescription = thought.content
        attributeSet.keywords = thought.tags.map(\.name)
        attributeSet.contentCreationDate = thought.timestamp
        attributeSet.contentType = "com.personalai.thought"

        let item = CSSearchableItem(
            uniqueIdentifier: thought.id.uuidString,
            domainIdentifier: "thoughts",
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item])
    }

    func removeThoughtFromSpotlight(_ thoughtID: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [thoughtID.uuidString]
        )
    }
}
```

**User Benefits:**
- Search thoughts from home screen
- iOS-wide search integration
- Siri suggestions: "You searched for this before"
- Deep linking into app

##### 3. **App Intents for Natural Language Queries** (High Priority)
**API:** App Intents with natural language parameters
**Use Case:** "Hey Siri, show me happy thoughts from December"

**Implementation:**
```swift
struct SearchThoughtsIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Thoughts"

    @Parameter(title: "Query")
    var query: String?

    @Parameter(title: "Date Range")
    var dateRange: DateRangeParameter?

    @Parameter(title: "Type")
    var type: ThoughtTypeParameter?

    @Parameter(title: "Sentiment")
    var sentiment: SentimentParameter?

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let results = await SearchService.shared.search(
            query: query,
            dateRange: dateRange,
            type: type,
            sentiment: sentiment
        )

        return .result(view: SearchResultsSnippet(results: results))
    }
}

// Siri suggestions
static var appShortcuts: [AppShortcut] {
    AppShortcut(
        intent: SearchThoughtsIntent(),
        phrases: [
            "Search for \(\.$query) in \(.applicationName)",
            "Find \(\.$sentiment) thoughts in \(.applicationName)"
        ]
    )
}
```

**User Benefits:**
- Voice-based search
- Hands-free (ADHD-friendly)
- Shortcuts automation
- Siri suggestions based on patterns

##### 4. **SwiftUI Searchable with Tokens** (High Priority)
**API:** SwiftUI searchable with search tokens
**Use Case:** Visual filter chips for complex queries

**Implementation:**
```swift
struct SearchScreen: View {
    @State private var searchText = ""
    @State private var tokens: [SearchToken] = []

    var body: some View {
        List(viewModel.searchResults) { thought in
            ThoughtRowView(thought: thought)
        }
        .searchable(
            text: $searchText,
            tokens: $tokens
        ) { token in
            Label(token.label, systemImage: token.icon)
        }
        .searchSuggestions {
            ForEach(viewModel.searchSuggestions) { suggestion in
                Button {
                    tokens.append(suggestion.token)
                } label: {
                    Label(suggestion.label, systemImage: suggestion.icon)
                }
            }
        }
    }
}

struct SearchToken: Identifiable {
    let id = UUID()
    let type: TokenType

    enum TokenType {
        case type(ThoughtType)
        case sentiment(Sentiment)
        case dateRange(DateRange)
        case tag(Tag)
    }

    var label: String {
        switch type {
        case .type(let t): return t.rawValue
        case .sentiment(let s): return s.emoji
        case .dateRange(let d): return d.label
        case .tag(let t): return t.name
        }
    }
}
```

**User Benefits:**
- Visual query builder
- No typing needed for filters
- Discoverable search options
- Mobile-friendly

##### 5. **Search Scopes** (Medium Priority)
**API:** SwiftUI searchable scopes
**Use Case:** Quick filter by time range

**Implementation:**
```swift
enum SearchScope: String, CaseIterable {
    case all = "All Time"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
}

struct SearchScreen: View {
    @State private var searchText = ""
    @State private var scope: SearchScope = .all

    var body: some View {
        List(filteredThoughts) { thought in
            ThoughtRowView(thought: thought)
        }
        .searchable(text: $searchText)
        .searchScopes($scope) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue)
            }
        }
    }
}
```

**User Benefits:**
- Quick time filtering
- Standard iOS pattern
- Keyboard accessible

**Recommendation:** ✅ IMPLEMENT Semantic Search + Spotlight + App Intents (HUGE UX improvement)

---

## Priority Matrix

### CRITICAL (Implement Before Launch)
1. **#20 (Subscription):** App Intents, Live Activities, Swift Testing
2. **#9 (Modernization):** Privacy Manifests, Swift 6 concurrency
3. **#7 (Medication):** App Intents, Live Activities, HealthKit

### HIGH PRIORITY (Implement Soon After Launch)
4. **#19 (Accessibility):** Swift Testing, Color validation
5. **#18 (Charts):** App Intents, Interactive Widgets
6. **#4 (Search):** Semantic Search, Spotlight, App Intents
7. **#6 (Testing):** Swift Testing framework

### MEDIUM PRIORITY (Phase 4-5)
8. **#13 (Squirrel-sona):** App Intents, Focus Filters
9. **#11 (Communication):** Foundation Models, String Catalogs
10. **#10 (Theme System):** @Observable, Swift Testing

### LOW PRIORITY (Polish)
11. **#14 (Branding):** SF Symbols, String Catalogs
12. **#12 (Personalization UI):** Animated previews
13. **#5 (Bulk Actions):** SwiftUI selection
14. **#8 (Foundation Models):** NLEmbedding, Swift Testing

---

## Quick Wins (High ROI, Low Effort)

### Week 1: Foundation
- Privacy Manifests (1 day) - **App Store requirement**
- Swift Testing setup (1 day) - **Enables all testing improvements**
- @Observable for ViewModels (2 days) - **Better performance**

### Week 2: User-Facing
- App Intents foundation (3 days) - **Siri integration for multiple issues**
- String Catalogs (2 days) - **Localization + message variants**

### Week 3: High-Impact Features
- Semantic Search (#4) (3 days) - **WOW feature**
- Interactive Widgets (#18) (2 days) - **Visibility**
- Live Activities for subscriptions (#20) (2 days) - **Conversion**

---

## Conclusion

Every open issue can be significantly enhanced with iOS 26 APIs. The highest ROI opportunities are:

1. **App Intents** - Affects 8 issues (#4, #7, #11, #13, #18, #20, #5)
2. **Swift Testing** - Affects 5 issues (#6, #8, #10, #19, #20)
3. **Live Activities** - Affects 3 issues (#7, #18, #20)
4. **Foundation Models** - Affects 3 issues (#8, #11, #4 semantic search)
5. **@Observable** - Affects 3 issues (#10, #11, #13)

**Recommended immediate focus:** App Intents + Swift Testing + Privacy Manifests (enables the rest)
