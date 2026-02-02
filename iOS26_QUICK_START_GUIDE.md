# iOS 26 Quick Start Implementation Guide

**Concrete steps to implement the highest ROI iOS 26 features in PersonalAI**

---

## Week 1: Critical Foundation (4 days)

### Day 1: Privacy Manifests 🔴 CRITICAL

**Why:** App Store requirement as of iOS 17+, enforced for all apps

**File to create:** `/PrivacyInfo.xcprivacy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>

    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <key>NSPrivacyCollectedDataTypes</key>
    <array/>

    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults Usage -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string> <!-- Store user preferences and app settings -->
            </array>
        </dict>

        <!-- File Timestamp Usage -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string> <!-- Access timestamps for thought sorting -->
            </array>
        </dict>

        <!-- System Boot Time (if using uptime) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>35F9.1</string> <!-- Measure time intervals for performance -->
            </array>
        </dict>

        <!-- Disk Space (if checking storage) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>E174.1</string> <!-- Check available space before database operations -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Add to Xcode project:**
1. File → New File → Resource → Property List
2. Name it `PrivacyInfo.xcprivacy`
3. Copy above content
4. Ensure it's included in app target

**Validation:**
```bash
# Build and check warnings
xcodebuild -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
# Look for privacy-related warnings
```

---

### Day 2: Swift Testing Setup 🔴 CRITICAL

**Why:** Modern testing framework, enables quality at scale

**Step 1: Create test target**

```bash
# If not already created
# File → New → Target → Unit Testing Bundle
# Name: PersonalAITests
# Testing Framework: Swift Testing
```

**Step 2: Add your first test**

Create `/Tests/ThoughtTests.swift`:

```swift
import Testing
@testable import PersonalAI

@Suite("Thought Model Tests")
struct ThoughtTests {

    @Test("Thought content is trimmed on creation")
    func testContentTrimming() {
        let context = PersistenceService.preview.container.viewContext
        let thought = ThoughtEntity(context: context)
        thought.content = "  test thought  "
        thought.normalizeContent()

        #expect(thought.content == "test thought")
    }

    @Test("Empty content validation fails")
    func testEmptyValidation() {
        let context = PersistenceService.preview.container.viewContext
        let thought = ThoughtEntity(context: context)
        thought.content = "   "

        #expect(thought.isValid == false)
    }
}

@Suite("Classification Tests", .tags(.ai))
struct ClassificationTests {

    @Test("Reminder detection works correctly")
    func testReminderDetection() async throws {
        let service = ClassificationService()
        let result = await service.classify("don't forget to call mom tomorrow")

        #expect(result.type == .reminder)
        #expect(result.confidence > 0.5)
    }

    @Test("Date parsing extracts tomorrow correctly")
    func testDateParsing() async throws {
        let service = ClassificationService()
        let result = await service.parseDateTime("meeting tomorrow at 3pm")

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        #expect(Calendar.current.isDate(result.date!, inSameDayAs: tomorrow))

        let hour = Calendar.current.component(.hour, from: result.date!)
        #expect(hour == 15)
    }
}

// Tag definitions
extension Tag {
    @Tag static var ai: Self
    @Tag static var integration: Self
    @Tag static var performance: Self
}
```

**Step 3: Add preview/test data helpers**

Create `/Tests/TestHelpers.swift`:

```swift
import Foundation
import CoreData
@testable import PersonalAI

extension PersistenceService {
    static var preview: PersistenceService {
        let service = PersistenceService(inMemory: true)
        let context = service.container.viewContext

        // Create sample thoughts for testing
        for i in 1...10 {
            let thought = ThoughtEntity(context: context)
            thought.id = UUID()
            thought.content = "Test thought \(i)"
            thought.timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600))
            thought.type = ThoughtType.allCases.randomElement()!.rawValue
        }

        try? context.save()
        return service
    }
}

extension ClassificationService {
    static var mock: ClassificationService {
        // Return mock service for testing
        ClassificationService(useMockData: true)
    }
}
```

**Step 4: Run tests**

```bash
# Command line
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode: Cmd+U
```

**Success criteria:**
- ✅ Tests run and pass
- ✅ Test output shows Swift Testing format
- ✅ Tags work for filtering tests

---

### Day 3: @Observable Migration (Part 1) 🟠 HIGH

**Why:** Better performance, simpler code than @Published

**Step 1: Update ThemeEngine**

Before:
```swift
import Foundation
import Combine

class ThemeEngine: ObservableObject {
    @Published var currentTheme: ThemeVariant = MinimalistTheme()
}
```

After:
```swift
import Foundation
import Observation

@Observable
class ThemeEngine {
    var currentTheme: ThemeVariant = MinimalistTheme()

    static let shared = ThemeEngine()

    func applyTheme(_ theme: ThemeVariant) {
        currentTheme = theme
        saveTheme()
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
    }
}
```

**Step 2: Update views to use @Observable**

Before:
```swift
@StateObject private var themeEngine = ThemeEngine()
```

After:
```swift
@State private var themeEngine = ThemeEngine.shared
// Or use @Environment if providing via environment
```

**Step 3: Inject into SwiftUI environment**

In `PersonalAIApp.swift`:

```swift
@main
struct PersonalAIApp: App {
    @State private var themeEngine = ThemeEngine.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeEngine)
        }
    }
}
```

**Step 4: Access in child views**

```swift
struct BrowseScreen: View {
    @Environment(ThemeEngine.self) private var themeEngine

    var body: some View {
        VStack {
            // ...
        }
        .background(themeEngine.currentTheme.backgroundColor)
    }
}
```

**Success criteria:**
- ✅ No @Published needed
- ✅ Views update automatically when theme changes
- ✅ Better performance (fine-grained updates)

---

### Day 4: Xcode Previews Fixes 🟠 HIGH

**Why:** Fast iteration, better DX

**Step 1: Add preview data to all models**

In `ThoughtEntity+Extensions.swift`:

```swift
#if DEBUG
extension ThoughtEntity {
    static var preview: ThoughtEntity {
        let context = PersistenceService.preview.container.viewContext
        let thought = ThoughtEntity(context: context)
        thought.id = UUID()
        thought.content = "This is a sample thought for previewing"
        thought.timestamp = Date()
        thought.type = ThoughtType.idea.rawValue
        thought.sentiment = 0.7
        thought.tags = ["work", "ios"]
        return thought
    }

    static func previewThoughts(count: Int) -> [ThoughtEntity] {
        let context = PersistenceService.preview.container.viewContext
        return (1...count).map { i in
            let thought = ThoughtEntity(context: context)
            thought.id = UUID()
            thought.content = "Sample thought \(i)"
            thought.timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600))
            thought.type = ThoughtType.allCases.randomElement()!.rawValue
            return thought
        }
    }
}
#endif
```

**Step 2: Add preview to every view**

In `CaptureScreen.swift`:

```swift
#Preview("Capture Screen - Empty") {
    CaptureScreen(viewModel: CaptureViewModel.preview)
}

#Preview("Capture Screen - With Content") {
    let vm = CaptureViewModel.preview
    vm.content = "Sample thought content"
    return CaptureScreen(viewModel: vm)
}

#Preview("Capture Screen - Dark Mode") {
    CaptureScreen(viewModel: CaptureViewModel.preview)
        .preferredColorScheme(.dark)
}
```

**Step 3: Create ViewModel preview helpers**

In `CaptureViewModel+Preview.swift`:

```swift
#if DEBUG
extension CaptureViewModel {
    static var preview: CaptureViewModel {
        CaptureViewModel(
            thoughtRepository: ThoughtRepository.preview,
            classificationService: ClassificationService.mock
        )
    }
}

extension ThoughtRepository {
    static var preview: ThoughtRepository {
        ThoughtRepository(persistenceService: PersistenceService.preview)
    }
}
#endif
```

**Success criteria:**
- ✅ All screens have working previews
- ✅ Previews load quickly (<1 second)
- ✅ Multiple variants for different states

---

## Week 2: App Intents Foundation (5 days)

### Day 5-7: Basic App Intents Setup 🔴 CRITICAL

**Why:** Enables Siri, Shortcuts, Focus Filters for 7+ issues

**Step 1: Create App Intents folder structure**

```
Sources/
└── AppIntents/
    ├── AppIntentsProvider.swift
    ├── CaptureIntents.swift
    ├── SearchIntents.swift
    ├── SubscriptionIntents.swift
    └── Entities/
        └── ThoughtEntity+AppEntity.swift
```

**Step 2: Define basic thought capture intent**

`CaptureIntents.swift`:

```swift
import AppIntents

struct CaptureThoughtIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Thought"
    static var description = IntentDescription("Quickly capture a thought in PersonalAI")

    @Parameter(title: "Content")
    var content: String

    @Parameter(title: "Use Voice", default: false)
    var useVoice: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Save thought
        let thought = try await ThoughtRepository.shared.createThought(content: content)

        return .result(
            dialog: "Saved: \(content)"
        )
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$content)")
    }
}
```

**Step 3: Create app shortcuts**

`AppIntentsProvider.swift`:

```swift
import AppIntents

struct PersonalAIAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureThoughtIntent(),
            phrases: [
                "Capture a thought in \(.applicationName)",
                "New note in \(.applicationName)",
                "Remember this in \(.applicationName)"
            ],
            shortTitle: "Capture Thought",
            systemImageName: "text.badge.plus"
        )
    }
}
```

**Step 4: Register in app**

`PersonalAIApp.swift`:

```swift
import AppIntents

@main
struct PersonalAIApp: App {
    init() {
        // Register app intents
        PersonalAIAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Step 5: Test with Siri**

1. Build and run app
2. Say "Hey Siri, capture a thought in PersonalAI"
3. Siri should prompt for content
4. Verify thought is saved

**Success criteria:**
- ✅ Siri recognizes intent
- ✅ Thought is created
- ✅ Appears in Shortcuts app
- ✅ Shows in Siri Suggestions

---

### Day 8-9: String Catalogs Setup 🟡 MEDIUM

**Why:** Enables message variants (#11) and localization (#14)

**Step 1: Create String Catalog**

1. File → New File → String Catalog
2. Name: `Localizable.xcstrings`
3. Add to app target

**Step 2: Define message variants**

`Localizable.xcstrings`:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "thought.saved" : {
      "comment" : "Success message when thought is saved",
      "localizations" : {
        "en" : {
          "variations" : {
            "device" : {
              "chatty" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "Nice! Your thought is saved ✨"
                }
              },
              "minimal" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "→ Saved"
                }
              },
              "formal" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "Thought saved successfully."
                }
              }
            }
          }
        }
      }
    },
    "capture.button.new" : {
      "comment" : "Button to capture new thought",
      "localizations" : {
        "en" : {
          "variations" : {
            "device" : {
              "branded" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "Ooh, Shiny!"
                }
              },
              "generic" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "New Note"
                }
              }
            }
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

**Step 3: Create helper to get variant**

`LocalizedStrings.swift`:

```swift
enum CommunicationStyle: String {
    case chatty
    case minimal
    case formal

    var deviceVariation: String {
        rawValue
    }
}

extension String {
    static func localized(
        _ key: String,
        style: CommunicationStyle = UserDefaults.communicationStyle
    ) -> String {
        // String catalog will automatically use the variant based on device settings
        NSLocalizedString(key, comment: "")
    }
}

extension UserDefaults {
    var communicationStyle: CommunicationStyle {
        get {
            CommunicationStyle(rawValue: string(forKey: "communicationStyle") ?? "chatty") ?? .chatty
        }
        set {
            set(newValue.rawValue, forKey: "communicationStyle")
        }
    }
}
```

**Step 4: Use in code**

```swift
// Instead of:
Text("Nice! Your thought is saved ✨")

// Use:
Text(.localized("thought.saved", style: .chatty))
```

**Success criteria:**
- ✅ String catalog contains all UI strings
- ✅ Variants can be selected at runtime
- ✅ Ready for localization

---

## Week 3: High-Impact Features (5 days)

### Day 10-12: Semantic Search 🟠 HIGH

**Why:** Differentiated feature, search by meaning not keywords

**Step 1: Create semantic search service**

`Sources/Services/Intelligence/SemanticSearchService.swift`:

```swift
import Foundation
import NaturalLanguage

@MainActor
class SemanticSearchService {
    static let shared = SemanticSearchService()

    private let embedding: NLEmbedding?

    init() {
        embedding = NLEmbedding.contextualEmbedding(for: .english, revision: .latest)
    }

    func search(query: String, in thoughts: [Thought]) async -> [SearchResult] {
        guard let queryVector = try? embedding?.vector(for: query) else {
            // Fallback to keyword search
            return keywordSearch(query: query, in: thoughts)
        }

        var results: [(thought: Thought, similarity: Double)] = []

        for thought in thoughts {
            if let thoughtVector = try? embedding?.vector(for: thought.content) {
                let similarity = cosineSimilarity(queryVector, thoughtVector)
                if similarity > 0.3 { // Relevance threshold
                    results.append((thought, similarity))
                }
            }
        }

        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(20)
            .map { SearchResult(thought: $0.thought, score: $0.similarity) }
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }
        return dotProduct / (magnitudeA * magnitudeB)
    }

    private func keywordSearch(query: String, in thoughts: [Thought]) -> [SearchResult] {
        thoughts
            .filter { $0.content.localizedCaseInsensitiveContains(query) }
            .map { SearchResult(thought: $0, score: 1.0) }
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let thought: Thought
    let score: Double

    var relevancePercentage: Int {
        Int(score * 100)
    }
}
```

**Step 2: Update SearchViewModel**

```swift
@Observable
class SearchViewModel {
    var searchQuery: String = ""
    var searchResults: [SearchResult] = []
    var isSearching: Bool = false

    private let semanticSearch = SemanticSearchService.shared
    private let repository: ThoughtRepository

    func performSearch() async {
        isSearching = true
        defer { isSearching = false }

        let thoughts = await repository.fetchAllThoughts()
        searchResults = await semanticSearch.search(query: searchQuery, in: thoughts)
    }
}
```

**Step 3: Update SearchScreen UI**

```swift
struct SearchScreen: View {
    @State private var viewModel: SearchViewModel

    var body: some View {
        List(viewModel.searchResults) { result in
            VStack(alignment: .leading) {
                ThoughtRowView(thought: result.thought)

                // Show relevance score
                if result.score < 1.0 {
                    Text("\(result.relevancePercentage)% relevant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $viewModel.searchQuery)
        .onChange(of: viewModel.searchQuery) {
            Task {
                await viewModel.performSearch()
            }
        }
    }
}
```

**Success criteria:**
- ✅ Semantic search finds related concepts
- ✅ Query "productivity" matches "focus", "efficiency", etc.
- ✅ Fallback to keyword search if embedding unavailable
- ✅ Relevance scores displayed

---

### Day 13: App Intents for Charts 🟠 HIGH

**Why:** Voice queries for insights

**Step 1: Create chart query intent**

`AppIntents/ChartIntents.swift`:

```swift
import AppIntents

struct ViewSentimentTrendIntent: AppIntent {
    static var title: LocalizedStringResource = "View Sentiment Trend"

    @Parameter(title: "Time Range")
    var timeRange: TimeRangeParameter

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let insights = await InsightsViewModel.shared.loadSentimentTrend(for: timeRange)

        return .result(
            view: SentimentTrendSnippet(data: insights)
        )
    }
}

enum TimeRangeParameter: String, AppEnum {
    case today
    case week
    case month

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Range")

    static var caseDisplayRepresentations: [TimeRangeParameter : DisplayRepresentation] = [
        .today: "Today",
        .week: "This Week",
        .month: "This Month"
    ]
}
```

**Step 2: Create snippet view**

```swift
import AppIntents
import Charts

struct SentimentTrendSnippet: View {
    let data: [SentimentDataPoint]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Sentiment Trend")
                .font(.headline)

            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Sentiment", point.score)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)

            HStack {
                Text("Average: \(averageSentiment.formatted(.percent))")
                Spacer()
                Button(intent: OpenInsightsIntent()) {
                    Text("View Full Insights")
                }
            }
        }
        .padding()
    }

    var averageSentiment: Double {
        data.map(\.score).reduce(0, +) / Double(data.count)
    }
}
```

**Success criteria:**
- ✅ "Hey Siri, show my sentiment this week" works
- ✅ Snippet view displays chart
- ✅ Tapping opens full insights screen

---

### Day 14: App Intents for Subscription 🔴 CRITICAL

**Why:** Voice queries for usage/status

**Step 1: Create subscription intents**

`AppIntents/SubscriptionIntents.swift`:

```swift
import AppIntents

struct CheckSubscriptionStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Subscription Status"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = SubscriptionManager.shared
        let status = await manager.subscriptionStatus

        let message: String
        switch status {
        case .free(let used, let limit):
            message = "You're on the free plan. Used \(used) of \(limit) thoughts this month."
        case .trial(let daysRemaining):
            message = "You have \(daysRemaining) days left in your trial."
        case .subscribed(let tier):
            message = "You're subscribed to \(tier). Enjoying unlimited thoughts!"
        }

        return .result(dialog: message)
    }
}

struct CheckThoughtUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Thought Usage"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = SubscriptionManager.shared
        let usage = await manager.currentMonthUsage
        let limit = SubscriptionManager.freeThoughtLimit

        if manager.isSubscribed {
            return .result(dialog: "You have unlimited thoughts! You've captured \(usage) this month.")
        } else {
            let remaining = limit - usage
            return .result(dialog: "You have \(remaining) thoughts remaining this month.")
        }
    }
}
```

**Step 2: Add to shortcuts**

```swift
extension PersonalAIAppShortcuts {
    static var subscriptionShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: CheckSubscriptionStatusIntent(),
                phrases: [
                    "Check my \(.applicationName) subscription",
                    "What's my \(.applicationName) plan"
                ]
            ),
            AppShortcut(
                intent: CheckThoughtUsageIntent(),
                phrases: [
                    "How many thoughts do I have left",
                    "Check my thought limit"
                ]
            )
        ]
    }
}
```

**Success criteria:**
- ✅ "Hey Siri, check my subscription" works
- ✅ "Hey Siri, how many thoughts do I have left" works
- ✅ Accurate usage/limit reporting

---

## Testing Your Implementation

### Run comprehensive tests

```bash
# Unit tests
xcodebuild test -scheme PersonalAI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Check code coverage
xcodebuild test \
  -scheme PersonalAI \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES
```

### Test App Intents

1. Build and run app
2. Open Shortcuts app
3. Look for PersonalAI actions
4. Test with Siri:
   - "Hey Siri, capture a thought in PersonalAI"
   - "Hey Siri, check my subscription status"
   - "Hey Siri, show my sentiment this week"

### Test Previews

1. Open any SwiftUI file
2. Click "Resume" in preview canvas
3. Verify preview loads correctly
4. Test different variants (dark mode, large text)

---

## Success Metrics

After Week 3, you should have:

- ✅ Privacy manifest (App Store compliant)
- ✅ Swift Testing (10+ tests passing)
- ✅ @Observable (1+ ViewModel migrated)
- ✅ Xcode Previews (working for all screens)
- ✅ App Intents (3+ working intents)
- ✅ String Catalogs (message variants working)
- ✅ Semantic Search (MVP functional)

**Code coverage:** Aim for 30%+ after Week 3 (on path to 70%)

**Siri integration:** 5+ voice commands working

**Development speed:** Previews reduce iteration time by 50%+

---

## Next Steps (Week 4+)

Choose one path based on priorities:

### Path A: Medication Management (ADHD-critical)
- Live Activities for dose reminders
- HealthKit integration
- Interactive widgets for logging

### Path B: Advanced Search (User engagement)
- Spotlight integration
- Natural language query parsing
- Search tokens UI

### Path C: Squirrel-sona (Differentiation)
- Theme system with @Observable
- Communication style variants
- Focus filter integration

**Recommendation:** Path A (Medication) if targeting ADHD users, Path B (Search) if broad appeal

---

## Common Issues & Solutions

### Issue: Previews not working
**Solution:** Ensure all preview data is wrapped in `#if DEBUG` and dependencies are mockable

### Issue: App Intents not appearing
**Solution:** Clean build folder, ensure `PersonalAIAppShortcuts.updateAppShortcutParameters()` is called in init

### Issue: Swift Testing tests not running
**Solution:** Ensure test target uses "Swift Testing" framework, not XCTest

### Issue: Privacy manifest warnings
**Solution:** Add all UserDefaults and file access API reasons (see Day 1)

---

## Resources

- [Apple App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Swift Testing Guide](https://developer.apple.com/documentation/testing)
- [Privacy Manifest Requirements](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [NLEmbedding Documentation](https://developer.apple.com/documentation/naturallanguage/nlembedding)

---

**Full detailed analysis:** See `iOS26_ENHANCEMENT_OPPORTUNITIES.md`
**Quick reference:** See `iOS26_ENHANCEMENTS_SUMMARY.md`
