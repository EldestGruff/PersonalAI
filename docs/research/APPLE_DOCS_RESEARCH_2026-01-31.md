# Apple Developer Documentation Research
**Date:** January 31, 2026
**Focus Areas:** Foundation Models, App Intents, HealthKit State of Mind
**iOS Version:** iOS 26+

---

## 1. Foundation Models Framework

### Overview
- **Availability:** iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
- **Purpose:** On-device large language model for text generation, structured output, and tool calling
- **Requirement:** Apple Intelligence must be enabled on device
- **Supported Devices:** iPhone 17 Pro+, M-series Macs (see apple.com/apple-intelligence)

### Key Capabilities

#### 1. **Text Generation**
- Summarization
- Entity extraction
- Text understanding and refinement
- Dialog generation for games
- Creative content generation

#### 2. **Guided Generation (`@Generable`)**
- Strong guarantees for structured output
- Prevents malformed responses
- No manual string parsing needed
- Supports: `Bool`, `Int`, `Float`, `Double`, `Decimal`, `String`, `Array`
- Custom nested types supported

**Example:**
```swift
@Generable(description: "Basic profile information")
struct CatProfile {
    var name: String

    @Guide(description: "Age of the cat", .range(0...20))
    var age: Int

    @Guide(description: "One sentence personality profile")
    var profile: String
}

let response = try await session.respond(
    to: "Generate a cute rescue cat",
    generating: CatProfile.self
)
```

#### 3. **Tool Calling**
- Extend model functionality with custom code
- Model decides when to call tools
- Query databases, perform actions, integrate with other frameworks
- Tools run concurrently

**Tool Calling Flow:**
1. Present available tools and parameters to model
2. Submit prompt to model
3. Model generates arguments for tool invocation
4. Tool runs code using model's arguments
5. Tool passes output back to model
6. Model produces final response using tool output

**Example:**
```swift
struct BreadDatabaseTool: Tool {
    let name = "searchBreadDatabase"
    let description = "Searches local database for bread recipes"

    @Generable
    struct Arguments {
        @Guide(description: "Type of bread to search for")
        var searchTerm: String

        @Guide(description: "Number of recipes to get", .range(1...6))
        var limit: Int
    }

    func call(arguments: Arguments) async throws -> [String] {
        // Query database, return formatted results
        // Model can call this multiple times in parallel
    }
}

let session = LanguageModelSession(
    tools: [BreadDatabaseTool()],
    instructions: "Help with bread recipes"
)
```

#### 4. **Session Management**
- `LanguageModelSession` - maintains conversation context
- `Instructions` - define model's intended behavior
- `Transcript` - observable history of interactions
- `GenerationOptions` - control response generation
- Pre-warming support for performance optimization

#### 5. **Dynamic Schemas (Runtime)**
- Create schemas at runtime when structure isn't known at compile time
- Useful for user-generated content or varying data structures

```swift
let menuSchema = DynamicGenerationSchema(
    name: "Menu",
    properties: [
        DynamicGenerationSchema.Property(
            name: "dailySoup",
            schema: DynamicGenerationSchema(
                name: "dailySoup",
                anyOf: ["Tomato", "Chicken Noodle", "Clam Chowder"]
            )
        )
    ]
)

let schema = try GenerationSchema(root: menuSchema, dependencies: [])
let response = try await session.respond(to: "...", schema: schema)
```

### Performance Considerations
- Keep descriptions short (reduces context size, improves latency)
- Use Instruments to profile token consumption
- Manage context window size carefully
- See TN3193 for context window management

### Safety & Compliance
- Built-in safety mechanisms for sensitive inputs
- Respect user privacy
- Follow acceptable use requirements (see apple.com/apple-intelligence/acceptable-use)

### Key API Types
- `SystemLanguageModel` - on-device LLM
- `SystemLanguageModel.UseCase` - use case enum
- `LanguageModelSession` - session management
- `@Generable` - structured output macro
- `@Guide` - property constraints
- `Tool` - custom tool protocol
- `Transcript` - session history
- `GeneratedContent` - model output

---

## 2. App Intents Framework

### Overview
- **Availability:** iOS 16.0+ (enhanced in iOS 26)
- **Purpose:** Deep integration with Siri, Spotlight, Shortcuts, Controls, Apple Intelligence
- **Key Enhancement (iOS 26):** Apple Intelligence integration with assistant schemas

### Siri & Apple Intelligence Integration

#### Assistant Schemas (iOS 18+)
New capability to integrate with Apple Intelligence's pre-trained models using schemas.

**Three Key Macros:**
1. `@AppIntent(schema: .domain.action)` - For app intents
2. `@AppEntity(schema: .domain.content)` - For app entities
3. `@AppEnum(schema: .domain.type)` - For app enumerations

**Schema Structure:**
- **Domain:** Category of functionality (e.g., `.photos`, `.notes`, `.messages`)
- **Schema:** Specific action or content type within domain

**Example:**
```swift
@AppIntent(schema: .photos.openAsset)
struct OpenAssetIntent: OpenIntent {
    var target: AssetEntity  // Required by schema

    @Dependency
    var library: MediaLibrary

    @MainActor
    func perform() async throws -> some IntentResult {
        let assets = library.assets(for: [target.id])
        guard let asset = assets.first else {
            throw IntentError.noEntity
        }
        navigation.openAsset(asset)
        return .result()
    }
}

@AppEntity(schema: .photos.asset)
struct AssetEntity: IndexedEntity {
    static let defaultQuery = AssetQuery()

    let id: String
    let asset: Asset

    @Property(title: "Title")
    var title: String?

    var creationDate: Date?
    var location: CLPlacemark?
    var isFavorite: Bool
}
```

#### Schema Requirements
**Constraints:**
- Can't require parameters beyond what schema expects
- Optional parameters only available in Shortcuts app
- App entities can't use required properties beyond schema
- Optional properties are allowed
- Maximum 10 app enums with assistant schemas per app

**Best Practice:** Use `isAssistantOnly = true` for new schema-conforming intents to avoid breaking existing shortcuts:

```swift
@AppIntent(schema: .photos.createAssets)
struct CreateAssetsIntent: AppIntent {
    static let isAssistantOnly: Bool = true  // Only available to Siri

    @MainActor
    func perform() async throws -> some ReturnsValue<[AssetEntity]> {
        // Implementation
    }
}
```

### System Integration Points
- **Siri** - Voice commands, contextual awareness
- **Spotlight** - Search and suggestions
- **Shortcuts** - Automation and actions
- **Action Button** - Hardware triggers (iPhone/Apple Watch)
- **Controls** - System-wide controls
- **Widgets** - Interactive widgets using App Intents
- **Live Activities** - Real-time updates
- **Visual Intelligence** - Camera-based discovery
- **Focus** - Reduce distractions

### Key Features (iOS 26)
1. **Personal Context Understanding** (in development)
2. **Onscreen Awareness** (in development)
3. **In-App Actions** (in development)
4. **Entity Queries** - Help system find app content
5. **Snippet Intents** - Interactive results display
6. **Parameter Resolution** - Runtime parameter handling

### App Intent Domains
Available domains for assistant schemas:
- `.photos` - Photo and video functionality
- `.notes` - Note-taking and document management
- `.messages` - Messaging and communication
- (See full list in App Intent Domains documentation)

### Migration from SiriKit
- SiriKit custom intents can be migrated to App Intents
- See "Soup Chef with App Intents" sample for migration guide
- App Intents is the modern replacement for SiriKit

---

## 3. HealthKit - State of Mind

### Overview
- **Availability:** iOS 18.0+, iPadOS 18.0+, macOS 15.0+, visionOS 2.0+, watchOS 11.0+
- **Purpose:** Mental health and wellbeing tracking
- **API:** `HKStateOfMind` class

### Core Components

#### `HKStateOfMind` Class
Inherits from `HKSample`, conforms to `Sendable`

**Properties:**
- `kind` - Type of state of mind reflection
- `valence` - Emotional valence (pleasantness/unpleasantness)
- `valenceClassification` - Categorized valence
- `labels` - Descriptive labels for the state
- `associations` - Contextual associations

**Initializer:**
```swift
init(
    date: Date,
    kind: Kind,
    valence: Double,
    labels: [Label],
    associations: [Association],
    metadata: [String: Any]?
)
```

#### Associated Types

**`HKStateOfMind.Kind`** - Type of reflection:
- Momentary state
- Daily mood
- (Other kinds in enum)

**`HKStateOfMind.Label`** - Emotional/mental state labels:
- Descriptive keywords for the state
- User-selected or inferred

**`HKStateOfMind.Association`** - Contextual factors:
- `.health` - Health-related associations
- `.dating` - Relationship-related associations
- (Other association types)

**`HKStateOfMindType`** - HealthKit type identifier:
```swift
HKObjectType.stateOfMindType()
```

### Querying State of Mind

**Predicate Support:**
```swift
HKSamplePredicate.stateOfMind(_:)
```

**Sample Code:** See "Visualizing HealthKit State of Mind in visionOS" for implementation examples.

### Integration with Other HealthKit Features
- **Mental Health Assessments:**
  - `HKGAD7Assessment` - Generalized Anxiety Disorder assessment
  - `HKPHQ9Assessment` - Depression assessment
  - `HKScoredAssessment` - Base class for scored assessments

### Privacy & Authorization
- Requires HealthKit authorization
- User controls read/write permissions separately
- State of Mind is sensitive data - handle with care
- Follow HealthKit privacy guidelines

### Use Cases for PersonalAI
1. **Correlation Analysis:**
   - Link thoughts to state of mind data
   - Identify patterns between thought types and emotional states
   - Show insights: "You tend to capture creative ideas when feeling content"

2. **Context Enrichment:**
   - Include state of mind in thought context
   - Enhance AI classification with emotional state

3. **Wellness Insights:**
   - Track emotional patterns over time
   - Correlate with energy levels, sleep, activity
   - Premium feature: AI-generated wellness recommendations

4. **Journaling Integration:**
   - Suggest reflection prompts based on state of mind
   - Track mood alongside thoughts
   - Export combined data for self-reflection

---

## 4. Implementation Recommendations for PersonalAI

### Foundation Models Integration

**Current Status:** ✅ Implemented
- `FoundationModelsClassifier` created
- `ThoughtClassificationResponse` with `@Generable`
- Maps to existing `ClassificationType` and `Sentiment` enums

**Next Steps:**
1. **Add Tool Calling for Insights** (Premium Feature)
```swift
struct InsightsTool: Tool {
    let name = "generateInsights"
    let description = "Analyze thought patterns and generate insights"

    @Generable
    struct Arguments {
        @Guide(description: "Time period to analyze")
        var period: String  // "week", "month", "all"

        @Guide(description: "Focus area", .count(1...3))
        var focusAreas: [String]  // "productivity", "mood", "energy"
    }

    func call(arguments: Arguments) async throws -> String {
        // Query ThoughtService for patterns
        // Analyze with HealthKit correlations
        // Return formatted insights
    }
}
```

2. **Streaming Responses for Real-Time Insights**
   - Use `PartiallyGenerated` types
   - Update UI progressively as insights generate
   - Better UX for premium insights feature

3. **Pre-warming Strategy**
   - Call `session.prewarm()` when InsightsScreen appears
   - Reduces latency for first insight generation
   - Reset on app backgrounding

### App Intents Enhancement

**Current Status:** ✅ Implemented (basic intents)
- `CaptureThoughtIntent`
- `ReviewIntent`
- `SearchThoughtsIntent`

**iOS 26 Enhancement: Add Assistant Schemas**

Need to identify appropriate domains and schemas. Candidates:

1. **Note-Taking Domain** (if available):
```swift
@AppIntent(schema: .notes.createNote)  // Hypothetical
struct CaptureThoughtIntent: AppIntent {
    static let isAssistantOnly: Bool = true

    @Parameter(title: "Thought Content")
    var content: String

    // Existing implementation
}
```

2. **Custom Domain** (if note-taking not available):
   - Keep existing intents without schema
   - Monitor iOS 26 documentation for new domains
   - Add schemas when applicable domain becomes available

**Action:** Review [App Intent Domains documentation](/documentation/appintents/app-intent-domains) to find matching schemas.

### HealthKit State of Mind Integration

**Priority:** High (unique competitive advantage)

**Implementation Plan:**

1. **Phase 1: Data Reading** (Week 1)
```swift
// Add to ContextService
func gatherStateOfMind() async -> HKStateOfMind? {
    guard await requestAuthorization(for: .stateOfMindType()) else {
        return nil
    }

    // Query most recent state of mind
    let predicate = HKQuery.predicateForSamples(
        withStart: Date().addingTimeInterval(-3600), // Last hour
        end: Date()
    )

    // Return most recent HKStateOfMind
}
```

2. **Phase 2: Context Integration** (Week 1)
```swift
// Update Context model
struct Context {
    // ... existing properties
    var stateOfMind: StateOfMindSnapshot?
}

struct StateOfMindSnapshot: Codable {
    var valence: Double  // -1.0 to 1.0
    var classification: String  // "pleasant", "unpleasant", "neutral"
    var labels: [String]
    var associations: [String]
}
```

3. **Phase 3: Charts & Insights** (Week 2-3)
   - Valence trend chart (Swift Charts)
   - Correlation with thought types
   - AI-generated insights using Foundation Models tool calling

4. **Phase 4: Premium Feature Gating** (Week 3)
   - Basic state of mind tracking: Free
   - AI insights & correlations: Premium

**Privacy Considerations:**
- Clear authorization prompts
- Explain value proposition before requesting access
- Graceful degradation if permission denied
- Never store state of mind data outside HealthKit

---

## 5. Technical Architecture Updates

### Recommended Changes

#### 1. **FoundationModelsClassifier Enhancement**
```swift
actor FoundationModelsClassifier {
    private var session: LanguageModelSession?
    private var tools: [Tool] = []

    init() {
        setupSession()
    }

    private func setupSession() {
        tools = [
            InsightsTool(),
            PatternAnalysisTool(),
            RecommendationTool()
        ]

        session = LanguageModelSession(
            tools: tools,
            instructions: """
            You are an expert at analyzing personal thoughts and identifying patterns.
            Help users understand their thinking patterns and emotional states.
            Be encouraging, insightful, and respectful of privacy.
            """
        )
    }

    // Existing classify() method

    // NEW: Insights generation
    func generateInsights(period: String, focusAreas: [String]) async throws -> String {
        guard let session else { throw ClassificationError.notAvailable }

        let prompt = """
        Analyze thought patterns from the past \(period) focusing on: \(focusAreas.joined(separator: ", ")).
        Provide actionable insights and encouraging observations.
        """

        // Model will call InsightsTool to query data
        let response = try await session.respond(to: prompt)
        return response
    }
}
```

#### 2. **Context Service Update**
```swift
actor ContextService {
    // Add state of mind gathering
    func gatherContext() async -> Context {
        async let location = gatherLocation()
        async let energy = gatherEnergyLevel()
        async let focus = gatherFocusState()
        async let stateOfMind = gatherStateOfMind()  // NEW

        return await Context(
            location: location,
            energy: energy,
            focusState: focus,
            stateOfMind: stateOfMind  // NEW
        )
    }

    private func gatherStateOfMind() async -> StateOfMindSnapshot? {
        // HealthKit query implementation
    }
}
```

#### 3. **InsightsService (New)**
```swift
actor InsightsService {
    private let classifier: FoundationModelsClassifier
    private let thoughtService: ThoughtService
    private let healthStore: HKHealthStore

    func generateWeeklyInsights() async throws -> [Insight] {
        // Use Foundation Models with tool calling
        // Query ThoughtService, HealthKit
        // Return AI-generated insights
    }

    func correlateWithHealth() async throws -> [HealthCorrelation] {
        // Correlate thoughts with state of mind, energy, sleep
    }
}
```

---

## 6. Monetization Impact

### Premium Features Enabled by These Technologies

1. **AI-Generated Insights** (Foundation Models + Tool Calling)
   - Weekly pattern analysis
   - Personalized recommendations
   - Trend detection
   - Value: High willingness to pay

2. **Health Correlations** (HealthKit State of Mind)
   - Unique competitive advantage
   - No competitors doing this with Foundation Models
   - Appeals to wellness-focused users
   - Value: Premium differentiator

3. **Advanced Search** (App Intents + Foundation Models)
   - Semantic search powered by on-device LLM
   - Natural language queries
   - Value: Productivity enhancement

### Free Tier Features
- Basic thought capture (50/month limit)
- Standard classification
- Manual tags
- Basic context (location, energy, focus)
- Calendar/Reminder creation

### Pro Tier Features ($3.99/mo or $39.99/yr)
- Unlimited thoughts
- AI auto-tagging
- **AI-generated weekly insights** (Foundation Models)
- **Health correlation analysis** (State of Mind integration)
- Advanced charts with AI narratives
- Semantic search
- Export capabilities
- Priority support

---

## 7. Development Priorities

### Immediate (This Week)
1. ✅ Foundation Models integration complete
2. ⏳ HealthKit State of Mind integration (1-2 days)
3. ⏳ Tool calling for insights (2-3 days)

### Short-term (Next 2 Weeks)
1. Swift Charts implementation (4 charts)
2. InsightsService with Foundation Models
3. Subscription system (StoreKit 2)
4. Premium feature gating

### Medium-term (4-6 Weeks)
1. App Intents assistant schemas (when available)
2. Advanced insights with streaming
3. Onboarding flow optimization
4. Beta testing

### Pre-Launch
1. Privacy Policy & Terms of Service
2. App Store assets & screenshots
3. TestFlight beta
4. Press kit & marketing materials

---

## 8. Key Documentation Links

### Foundation Models
- Main: https://developer.apple.com/documentation/foundationmodels/
- Tool Calling: https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling/
- Guided Generation: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation/
- WWDC25 Session 286: Foundation Models overview

### App Intents
- Main: https://developer.apple.com/documentation/appintents/
- Siri Integration: https://developer.apple.com/documentation/appintents/integrating-actions-with-siri-and-apple-intelligence/
- App Intent Domains: https://developer.apple.com/documentation/appintents/app-intent-domains/

### HealthKit
- State of Mind: https://developer.apple.com/documentation/healthkit/hkstateofmind/
- visionOS Sample: https://developer.apple.com/documentation/healthkit/visualizing_healthkit_state_of_mind_in_visionos/
- WWDC24 Session 10109: Mental health APIs

---

## 9. Questions for Further Research

1. **App Intents:** What are all available assistant schemas for iOS 26? Need full domain list.
2. **Foundation Models:** Token limits and context window size for on-device model?
3. **HealthKit:** Best practices for presenting state of mind correlation insights?
4. **Privacy:** Any special considerations for combining HealthKit data with AI insights?
5. **Performance:** Benchmarks for Foundation Models response times with tool calling?

---

## 10. Competitive Advantage Summary

### Unique Position
**PersonalAI is positioned to be the FIRST app combining:**
1. On-device Foundation Models (zero cost, 100% private)
2. HealthKit State of Mind integration
3. AI-powered insights generation
4. iOS 26 native features

### No Competitor Has:
- Foundation Models integration (requires iOS 26, most apps target iOS 17+)
- State of Mind correlation (new API, requires HealthKit expertise)
- Zero-cost AI (competitors use OpenAI = ongoing costs)
- 100% on-device privacy (competitors send data to cloud)

### Market Timing
- iOS 26 just released (January 2026)
- Foundation Models brand new
- State of Mind API only 1 year old
- **First-mover advantage in this exact combination**

### Target Launch
- **Before WWDC 2026** (June 2026)
- 4-5 months to build, test, and launch
- Establish market presence before Apple showcases these features
- Potential for Apple feature consideration

---

**Next Actions:**
1. Implement HealthKit State of Mind integration
2. Build InsightsTool with Foundation Models tool calling
3. Create InsightsService actor
4. Design insights UI with Swift Charts
5. Gate premium features behind subscription
