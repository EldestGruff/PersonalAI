# Foundation Models Implementation Plan

**Last Updated**: 2026-01-30
**iOS Target**: iOS 26.0+ (current release)
**Xcode Version**: 26.1.1
**Device Requirements**: iPhone 17 Pro+, M-series Macs

## Executive Summary

PersonalAI will use **Apple's Foundation Models framework exclusively** for all AI features. This eliminates OpenAI API costs entirely, provides 100% on-device privacy, and enables offline functionality.

**Key Decision**: No OpenAI fallback. iOS 26+ only.

---

## Technical Requirements

### Platform Support
- **Minimum**: iOS 26.0, iPadOS 26.0, macOS 26.0
- **Device Requirements**:
  - iPhone: iPhone 17 Pro, iPhone 17 Pro Max, or later
  - iPad: iPad Pro with M2 or later, iPad Air with M2 or later
  - Mac: Any Mac with Apple Silicon (M1 or later)
- **Apple Intelligence**: Must be enabled in Settings

### Framework Import
```swift
import FoundationModels

// Check availability before use
guard SystemLanguageModel.availability == .available else {
    // Show error: "Apple Intelligence required"
    return
}
```

---

## Architecture Overview

### Current (Theoretical OpenAI)
```
Thought Capture → OpenAI API Call → Classification Response
                  (network, costs, privacy risk)
```

### New (Foundation Models)
```
Thought Capture → LanguageModelSession → Classification Response
                  (on-device, free, private, offline)
```

---

## Implementation Tasks

### 1. Thought Classification

**Goal**: Replace hypothetical OpenAI classification with Foundation Models structured output.

**Data Model** (already exists in `ThoughtClassification.swift`):
```swift
@Generable
struct ThoughtClassification {
    @Guide(description: "Type of thought: note, idea, task, event, or question")
    var type: ThoughtType

    @Guide(description: "Confidence score from 0.0 to 1.0")
    var confidence: Double

    @Guide(description: "3-5 contextual tags based on content", .count(3...5))
    var suggestedTags: [String]

    @Guide(description: "Emotional sentiment from -1.0 (very negative) to 1.0 (very positive)")
    var sentiment: Double
}
```

**Service Implementation** (`AIClassificationService.swift` - new file):
```swift
import FoundationModels

@Observable
final class AIClassificationService {
    private var session: LanguageModelSession?

    init() {
        setupSession()
    }

    private func setupSession() {
        guard SystemLanguageModel.availability == .available else {
            print("Apple Intelligence not available")
            return
        }

        session = LanguageModelSession(
            instructions: """
            You are an expert at analyzing personal thoughts and categorizing them.

            Thought types:
            - note: Reference information, observations, facts
            - idea: Creative thoughts, possibilities, innovations
            - task: Action items, to-dos, things to accomplish
            - event: Time-based activities, meetings, appointments
            - question: Things to research or answer

            Provide accurate classification, relevant tags, and emotional tone.
            Be concise but insightful.
            """
        )
    }

    func classify(thought: String, context: Context? = nil) async throws -> ThoughtClassification {
        guard let session else {
            throw AIError.notAvailable
        }

        // Build prompt with optional context
        var prompt = "Classify this thought:\n\n\"\(thought)\""

        if let context {
            prompt += "\n\nContext:"
            if let location = context.location {
                prompt += "\n- Location: \(location)"
            }
            if let energy = context.energy {
                prompt += "\n- Energy level: \(energy.rawValue)"
            }
            if let focus = context.focusState {
                prompt += "\n- Focus state: \(focus.rawValue)"
            }
        }

        // Get structured classification
        let response = try await session.respond(
            to: prompt,
            generating: ThoughtClassification.self
        )

        return response.content
    }

    func prewarm() {
        // Pre-load model when user likely to capture (e.g., capture screen opens)
        session?.prewarm()
    }
}

enum AIError: Error {
    case notAvailable
    case classificationFailed
}
```

**Usage in CaptureViewModel**:
```swift
@Observable
final class CaptureViewModel {
    private let aiService = AIClassificationService()

    func captureThought() async {
        guard !thoughtContent.isEmpty else { return }

        isClassifying = true

        do {
            // Pre-warm was already called when screen appeared
            let classification = try await aiService.classify(
                thought: thoughtContent,
                context: currentContext
            )

            // Create thought with classification
            let thought = Thought(
                content: thoughtContent,
                type: classification.type,
                tags: Set(classification.suggestedTags),
                sentiment: classification.sentiment,
                context: currentContext,
                classification: classification
            )

            try await thoughtRepository.create(thought)

            // Optionally save State of Mind to HealthKit
            if enableMentalWellness {
                try await saveStateOfMind(
                    sentiment: classification.sentiment,
                    thought: thought
                )
            }

            isClassifying = false
            dismiss()

        } catch {
            isClassifying = false
            errorMessage = "Classification failed: \(error.localizedDescription)"
        }
    }

    func onAppear() {
        // Pre-warm model when capture screen opens
        aiService.prewarm()
    }
}
```

---

### 2. Auto-Tagging (Premium Feature)

**Goal**: Generate additional tag suggestions based on thought content and existing tags.

**Service Method**:
```swift
extension AIClassificationService {
    @Generable
    struct TagSuggestions {
        @Guide(description: "3-5 additional relevant tags", .count(3...5))
        var tags: [String]
    }

    func suggestAdditionalTags(
        thought: String,
        existingTags: Set<String>,
        previousThoughts: [Thought]
    ) async throws -> [String] {
        guard let session else {
            throw AIError.notAvailable
        }

        // Build prompt with context from user's tag vocabulary
        let userTags = Set(previousThoughts.flatMap(\.tags)).sorted()

        let prompt = """
        Suggest additional tags for this thought:

        "\(thought)"

        Existing tags: \(existingTags.joined(separator: ", "))

        User's tag vocabulary (prefer these): \(userTags.prefix(20).joined(separator: ", "))

        Suggest 3-5 additional relevant tags.
        """

        let response = try await session.respond(
            to: prompt,
            generating: TagSuggestions.self
        )

        return response.content.tags
    }
}
```

---

### 3. Insights Generation (Premium Feature)

**Goal**: Generate natural language insights from thought patterns using tool calling.

**Tool Implementation**:
```swift
import FoundationModels

struct ThoughtAnalysisTool: Tool {
    let name = "analyzeThoughts"
    let description = "Analyze user's thought patterns and correlations"

    @Generable
    struct Arguments {
        @Guide(description: "Date range to analyze: 7d, 30d, 90d, 1y, all")
        var dateRange: String

        @Guide(description: "Include health data correlation if available")
        var includeHealthData: Bool
    }

    private let thoughtRepository: ThoughtRepository
    private let healthService: HealthService?

    func call(arguments: Arguments) async throws -> ToolOutput {
        // Query thoughts
        let thoughts = try await thoughtRepository.fetch(in: parseDateRange(arguments.dateRange))

        // Calculate statistics
        let avgSentiment = thoughts.map(\.sentiment).average()
        let typeDistribution = Dictionary(grouping: thoughts, by: \.type)
            .mapValues { $0.count }
        let topTags = thoughts.flatMap(\.tags)
            .frequency()
            .sorted { $0.value > $1.value }
            .prefix(5)

        var analysis = """
        Thought Analysis (\(arguments.dateRange)):
        - Total thoughts: \(thoughts.count)
        - Average sentiment: \(avgSentiment.formatted(.number.precision(.fractionLength(2))))
        - Type distribution: \(typeDistribution.description)
        - Top tags: \(topTags.map(\.key).joined(separator: ", "))
        """

        // Add health correlation if enabled
        if arguments.includeHealthData, let healthService {
            let energyLevels = try await healthService.fetchEnergyLevels(in: parseDateRange(arguments.dateRange))
            let emotions = try await healthService.fetchStateOfMind(in: parseDateRange(arguments.dateRange))

            analysis += """

            Health Correlation:
            - Average energy: \(energyLevels.average())
            - Average emotional valence: \(emotions.map(\.valence).average())
            - High energy thoughts: \(thoughts.filter { $0.context?.energy == .high }.count)
            - Low energy thoughts: \(thoughts.filter { $0.context?.energy == .low }.count)
            """
        }

        return ToolOutput(analysis)
    }
}
```

**Insights Service**:
```swift
@Observable
final class InsightsService {
    private var session: LanguageModelSession?

    init(thoughtRepository: ThoughtRepository, healthService: HealthService?) {
        let analysisTool = ThoughtAnalysisTool(
            thoughtRepository: thoughtRepository,
            healthService: healthService
        )

        session = LanguageModelSession(
            instructions: """
            You are a thoughtful analyst helping users understand their mental patterns.

            Analyze the data provided and generate 2-3 actionable insights:
            - Identify trends (improving, declining, stable)
            - Find correlations (energy, emotions, productivity)
            - Suggest optimizations (best times, helpful patterns)

            Be concise, specific, and encouraging.
            """,
            tools: [analysisTool]
        )
    }

    func generateInsights(for dateRange: ChartDateRange, includeHealth: Bool) async throws -> [String] {
        guard let session else {
            throw AIError.notAvailable
        }

        let response = try await session.respond(
            to: """
            Analyze my thought patterns for the \(dateRange.displayName.lowercased()) period.
            \(includeHealth ? "Include health data correlation." : "")

            Provide 3 key insights.
            """
        )

        // Parse response into individual insights
        return response.content
            .components(separatedBy: "\n")
            .filter { $0.trimmingCharacters(in: .whitespaces).count > 0 }
    }
}
```

---

### 4. Streaming Responses (Optional Enhancement)

**Goal**: Show insights populating in real-time for better UX.

**Implementation**:
```swift
extension InsightsService {
    @Generable
    struct StreamedInsight {
        @Guide(description: "Key insight about thought patterns")
        var insight: String

        @Guide(description: "Supporting data or evidence")
        var evidence: String

        @Guide(description: "Actionable recommendation")
        var recommendation: String
    }

    func streamInsights(for dateRange: ChartDateRange) -> AsyncThrowingStream<StreamedInsight.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let session else {
                    continuation.finish(throwing: AIError.notAvailable)
                    return
                }

                do {
                    let stream = try await session.streamResponse(
                        to: "Analyze my \(dateRange.displayName.lowercased()) thought patterns",
                        generating: StreamedInsight.self
                    )

                    for try await partial in stream {
                        continuation.yield(partial)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// Usage in SwiftUI
struct InsightsView: View {
    @State private var insights: [StreamedInsight.PartiallyGenerated] = []

    var body: some View {
        ForEach(insights, id: \.id) { insight in
            VStack(alignment: .leading, spacing: 8) {
                if let text = insight.insight {
                    Text(text)
                        .font(.headline)
                }
                if let evidence = insight.evidence {
                    Text(evidence)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let recommendation = insight.recommendation {
                    Text(recommendation)
                        .font(.callout)
                        .foregroundColor(.teal)
                }
            }
            .transition(.opacity.combined(with: .slide))
        }
        .task {
            for try await partial in insightsService.streamInsights(for: .week) {
                withAnimation {
                    insights.append(partial)
                }
            }
        }
    }
}
```

---

## Error Handling

### Apple Intelligence Not Available

**Check at App Launch**:
```swift
@main
struct PersonalAIApp: App {
    @State private var showAppleIntelligenceRequired = false

    var body: some Scene {
        WindowGroup {
            if SystemLanguageModel.availability == .available {
                MainTabView()
            } else {
                AppleIntelligenceRequiredView()
            }
        }
    }
}
```

**AppleIntelligenceRequiredView**:
```swift
struct AppleIntelligenceRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.teal)

            Text("Apple Intelligence Required")
                .font(.title.bold())

            Text("PersonalAI uses on-device AI to classify and organize your thoughts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                RequirementRow(
                    icon: "iphone",
                    text: "iPhone 17 Pro or later"
                )
                RequirementRow(
                    icon: "macbook",
                    text: "Mac with Apple Silicon (M1+)"
                )
                RequirementRow(
                    icon: "gearshape.2",
                    text: "Apple Intelligence enabled in Settings"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            Button {
                if let url = URL(string: "App-prefs:APPLE_INTELLIGENCE") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.teal)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
```

### Classification Failures

**Graceful Degradation**:
```swift
func captureThought() async {
    do {
        let classification = try await aiService.classify(thought: thoughtContent)
        // Use AI classification
    } catch {
        // Fallback: Save without classification, allow manual type selection
        let thought = Thought(
            content: thoughtContent,
            type: .note, // Default type
            tags: [],
            sentiment: 0.0,
            context: currentContext,
            classification: nil
        )

        // Show alert: "Classification unavailable. Saved as Note. Tap to change type."
        showManualTypeSelection = true
    }
}
```

---

## Performance Optimization

### 1. Pre-warming
```swift
// In CaptureScreen
.onAppear {
    viewModel.prewarmAI()
}

// In DetailScreen (before editing)
.onChange(of: isEditing) { _, newValue in
    if newValue {
        viewModel.prewarmAI()
    }
}
```

### 2. Token Reduction
```swift
// Use examples instead of schema when possible
let response = try await session.respond(
    to: prompt,
    generating: ThoughtClassification.self,
    includeSchemaInPrompt: false  // Save tokens if using one-shot examples
)
```

### 3. Profiling with Instruments
- Use Xcode Instruments to measure model latency
- Identify bottlenecks (prompt length, response parsing)
- Optimize prompts based on data

---

## Migration from OpenAI (N/A)

Since PersonalAI is being built fresh with Foundation Models from day one, there's no migration needed. All AI features are designed around the `@Generable` pattern and tool calling from the start.

---

## App Store Metadata Updates

### App Description Addition
```
Powered by Apple Intelligence, PersonalAI runs 100% on your device.
No cloud servers. No data sharing. Complete privacy.

Requires:
• iOS 26.0 or later
• iPhone 17 Pro or later, or Mac with Apple Silicon
• Apple Intelligence enabled in Settings
```

### Keywords Addition
```
apple intelligence, on-device ai, private ai, mental health, wellbeing
```

### Screenshot Callout
```
"Powered by Apple Intelligence"
"100% On-Device Privacy"
```

---

## Testing Plan

### Unit Tests
```swift
@Test("Classification returns valid ThoughtType")
func testClassification() async throws {
    let service = AIClassificationService()
    let classification = try await service.classify(thought: "Remember to buy milk")

    #expect(classification.type == .task || classification.type == .reminder)
    #expect(classification.confidence > 0.0 && classification.confidence <= 1.0)
    #expect(classification.suggestedTags.count >= 3)
}

@Test("Classification handles empty thought")
func testEmptyThought() async throws {
    let service = AIClassificationService()

    await #expect(throws: AIError.self) {
        try await service.classify(thought: "")
    }
}
```

### Integration Tests
- Test on real device (iPhone 17 Pro with iOS 26.2)
- Verify model responses match expected structure
- Test offline functionality (Airplane mode)
- Test with Apple Intelligence disabled (should show requirement screen)

### Performance Tests
- Measure average classification time (target: <1 second)
- Test with long thoughts (>500 words)
- Test rapid successive captures (batch processing)

---

## Cost Analysis Update

### Before (Hypothetical OpenAI)
- Variable cost: $0.027/user/month
- Break-even: 150-400 paid users

### After (Foundation Models)
- Variable cost: **$0/user/month**
- Break-even: **~100 paid users** (fixed costs only)
- Gross margin: **100%** (no variable costs)

**Financial Impact**:
- Year 1 profit increases from $80K → **$90K+**
- No API rate limits or throttling
- No API key management or security concerns
- No network dependency (works offline)

---

## Timeline

### Week 1-2: Core Classification
- [ ] Create `AIClassificationService.swift`
- [ ] Implement `@Generable` ThoughtClassification struct
- [ ] Integrate with CaptureViewModel
- [ ] Add pre-warming to capture flow
- [ ] Test on device with real thoughts

### Week 3: Auto-Tagging
- [ ] Implement tag suggestion method
- [ ] Integrate with premium feature flag
- [ ] Test tag quality and relevance
- [ ] Add user feedback loop (accept/reject suggestions)

### Week 4: Insights Generation
- [ ] Create ThoughtAnalysisTool
- [ ] Implement InsightsService with tool calling
- [ ] Generate natural language insights
- [ ] Add to InsightsScreen UI

### Week 5: Polish & Error Handling
- [ ] Build AppleIntelligenceRequiredView
- [ ] Add graceful degradation for failures
- [ ] Implement retry logic
- [ ] Add loading states and progress indicators

### Week 6: Testing & Optimization
- [ ] Write unit tests
- [ ] Profile with Instruments
- [ ] Optimize prompts based on response quality
- [ ] Test edge cases (very long thoughts, empty, special characters)

---

## Documentation References

- [Foundation Models Framework](https://developer.apple.com/documentation/FoundationModels)
- [Meet the Foundation Models framework - WWDC25](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Code along with Foundation Models - WWDC25](https://developer.apple.com/videos/play/meet-with-apple/205/)
- [ML Frameworks Overview - WWDC25](https://developer.apple.com/videos/play/wwdc2025/360/)
- [Human Interface Guidelines: Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai)

---

## Success Criteria

- ✅ 100% of thoughts classified with Foundation Models (no fallback)
- ✅ Average classification time <1 second
- ✅ Classification accuracy >85% (measured by user corrections)
- ✅ Works offline (no network dependency)
- ✅ Zero variable costs (no API charges)
- ✅ Privacy: 100% on-device processing

---

**Status**: Ready for implementation
**Next Step**: Create AIClassificationService.swift and integrate with CaptureViewModel
**Blocker**: None (iOS 26 is live, device available, Xcode 26.1.1 installed)
