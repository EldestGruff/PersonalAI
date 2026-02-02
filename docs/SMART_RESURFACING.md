# Smart Thought Resurfacing System

**Status:** In Development
**Created:** February 1, 2026
**Purpose:** Solve the "notes graveyard" problem by proactively surfacing related thoughts

---

## Problem Statement

**The Issue:** Users write notes and never look at them again, even when the information would be relevant.

**Common Patterns:**
- Writing the same idea multiple times without realizing
- Capturing recurring thoughts/problems but never acting on them
- Missing connections between related notes
- Unresolved questions that fade into history
- Ideas mentioned repeatedly but never developed

**User Quote:** *"I tend to write things down on a note and then I forget about the note and never go back and look. A lot of times I have consistent and repeating ideas on those notes."*

---

## Solution Overview

The Smart Resurfacing System uses iOS 26's `NLEmbedding` (semantic search) to:

1. **Surface related thoughts** when viewing or capturing notes
2. **Detect possible duplicates** before you write the same thing twice
3. **Identify recurring patterns** across your thought history
4. **Highlight unresolved items** that need attention

---

## Architecture

### Core Components

#### 1. **SmartInsightsService**
`Sources/Services/Intelligence/SmartInsightsService.swift`

**Purpose:** Central service for thought analysis and pattern detection

**Key Methods:**
```swift
// Find thoughts related to a given thought
func findRelatedThoughts(for thought: Thought, in allThoughts: [Thought]) async -> [SearchResult]

// Detect possible duplicates (high similarity)
func findPossibleDuplicates(for thought: Thought, in allThoughts: [Thought]) async -> [SearchResult]

// Detect recurring patterns/themes
func detectPatterns(in thoughts: [Thought]) async -> [ThoughtPattern]

// Get comprehensive insights for a thought
func getInsights(for thought: Thought, in allThoughts: [Thought]) async -> ThoughtInsight

// Find unresolved ideas/questions
func findUnresolvedThoughts(in thoughts: [Thought]) -> [Thought]

// Generate human-readable summary
func generateSummary(for thoughts: [Thought]) async -> String
```

**Dependencies:**
- `SemanticSearchService` - Uses existing semantic search for similarity
- `NLEmbedding` - iOS 26 contextual embeddings

---

#### 2. **Data Models**

**ThoughtPattern:**
```swift
public struct ThoughtPattern: Identifiable {
    let theme: String              // Theme/topic name
    let thoughts: [Thought]        // All thoughts in this pattern
    let frequency: Int             // How many times it appears
    let firstSeen: Date           // When pattern started
    let lastSeen: Date            // Most recent occurrence

    var daySpan: Int              // Days between first and last
    var isRecent: Bool            // Last 7 days?
    var isLongTerm: Bool          // >30 days?
}
```

**ThoughtInsight:**
```swift
public struct ThoughtInsight {
    let thought: Thought
    let relatedThoughts: [SearchResult]      // Similar past thoughts
    let possibleDuplicates: [SearchResult]   // Very similar (>75%)
    let patterns: [ThoughtPattern]           // Patterns this belongs to

    var hasRelated: Bool
    var hasPossibleDuplicates: Bool
    var isPartOfPattern: Bool
}
```

---

## Implementation Phases

### Phase 1: Related Thoughts (Week 1 - 2 days) ✅ IN PROGRESS

**Goal:** Surface related thoughts when viewing notes

**UI Changes:**
1. **DetailScreen** - Add "Related Thoughts" section
   - Shows 3-5 most similar past thoughts
   - Displays relevance percentage
   - Tap to navigate to related thought

2. **CaptureScreen** - Add "Similar Thoughts" warning
   - Shows when capturing similar content
   - "You wrote something similar X days ago"
   - Option to view existing or continue

3. **InsightsScreen** - Add "Recurring Themes" section
   - Top 5 patterns by frequency
   - Time span for each pattern
   - Tap to see all thoughts in pattern

**User Experience:**
```
You capture: "Feeling overwhelmed with work tasks"

System shows banner:
┌─────────────────────────────────────────┐
│ 💡 You've thought about this before     │
│                                         │
│ "Work stress building up"              │
│ 3 days ago • 85% similar                │
│                                         │
│ [View Previous] [Continue Anyway]       │
└─────────────────────────────────────────┘
```

**Files to Modify:**
- `Sources/UI/Screens/DetailScreen.swift` - Add related section
- `Sources/UI/ViewModels/DetailViewModel.swift` - Load related thoughts
- `Sources/UI/Screens/CaptureScreen.swift` - Add similarity check
- `Sources/UI/ViewModels/CaptureViewModel.swift` - Check for similar
- `Sources/UI/Screens/InsightsScreen.swift` - Add patterns view

---

### Phase 2: Pattern Recognition (Week 2 - 3 days)

**Goal:** Detect and surface recurring themes

**Features:**
1. **Weekly Pattern Digest**
   - Notification every Sunday evening
   - Summary of patterns from the week
   - Unresolved items count

2. **Pattern Detail View**
   - All thoughts in a pattern, chronologically
   - Frequency graph over time
   - Action suggestions (create task, set reminder)

3. **Smart Suggestions**
   - "You've mentioned X 5 times but never created a task"
   - "You ask about Y repeatedly - would you like to research this?"
   - "Z keeps coming up when you're stressed - pattern detected"

**UI Example:**
```
📊 Recurring Themes This Week

🔥 exercise: 7 times over 14 days
   "You keep thinking about exercise but haven't
    logged a workout in 12 days"
   [Create Recurring Reminder] [View All 7 Thoughts]

💡 productivity system: 4 times over 6 days
   "You've explored this idea 4 times this week"
   [Create Task to Research] [View Pattern]

❓ project deadline: 3 times over 21 days
   "Repeated question - might need clarification"
   [Ask Team] [Set Reminder to Follow Up]
```

---

### Phase 3: Contextual Resurfacing (Week 3 - 2 weeks)

**Goal:** Proactive resurfacing at the right time

**Location-Based:**
```swift
// When user arrives at location
if userLocation.matches(pattern.commonLocation) {
    showNotification("You're at the gym. You've thought about
                     starting a workout routine 5 times.")
}
```

**Time-Based:**
```swift
// Pattern: User writes about planning on Monday mornings
if isMonday && isMorning {
    showNotification("Monday morning - here are your 5 unfinished
                     planning thoughts from previous weeks")
}
```

**Calendar-Based:**
```swift
// Before a meeting
if upcomingMeeting.contains("roadmap") {
    showNotification("Roadmap meeting in 30 min. Here are 3 related
                     thoughts you captured this week")
}
```

**Focus Mode Integration (iOS 26):**
```swift
// When entering Work focus
if focusMode == .work {
    showNotification("Work mode activated. You have 2 unresolved
                     work questions from this week")
}
```

---

## Technical Details

### Similarity Thresholds

```swift
// Related thoughts: 50% or higher
private let relatedThreshold: Double = 0.5

// Possible duplicates: 75% or higher
private let duplicateThreshold: Double = 0.75

// High confidence: 60% or higher (shown with green checkmark)
public var isHighConfidence: Bool {
    score > 0.6
}
```

### Pattern Detection Algorithm

1. **Group by Theme**
   - Tags (normalized, lowercased)
   - Classification types
   - Semantic clusters (future enhancement)

2. **Filter by Frequency**
   - Minimum 3 thoughts to be considered a "pattern"
   - Configurable threshold

3. **Time Analysis**
   - Calculate day span (first to last occurrence)
   - Flag as "recent" if within 7 days
   - Flag as "long-term" if >30 days

4. **Ranking**
   - Sort by frequency (most common first)
   - Secondary sort by recency

### Unresolved Detection

Identifies thoughts needing attention:

```swift
// Questions (contains "?")
"What's the best way to learn SwiftUI?"

// Ideas without tasks
Classification: idea
Has related task: false
→ Flag as unresolved

// Action tags without tasks
Tags: ["todo", "need", "should"]
Has related task: false
→ Flag as unresolved
```

---

## User Interface Components

### 1. Related Thoughts Section (DetailScreen)

```swift
VStack(alignment: .leading, spacing: 12) {
    HStack {
        Image(systemName: "link")
        Text("Related Thoughts")
            .font(.headline)
    }

    ForEach(relatedThoughts) { result in
        NavigationLink {
            DetailScreen(thought: result.thought)
        } label: {
            VStack(alignment: .leading) {
                Text(result.thought.content)
                    .lineLimit(2)

                HStack {
                    Text(result.thought.createdAt.formatted(.relative))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(result.relevancePercentage)% similar")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
```

### 2. Similarity Warning Banner (CaptureScreen)

```swift
if let similar = viewModel.similarThought {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)

        VStack(alignment: .leading) {
            Text("You wrote something similar before")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(similar.thought.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text("\(similar.daysAgo) days ago • \(similar.relevancePercentage)% similar")
                .font(.caption2)
                .foregroundColor(.secondary)
        }

        Button("View") {
            viewModel.showSimilarThought()
        }
        .buttonStyle(.bordered)
    }
    .padding()
    .background(Color.orange.opacity(0.1))
    .cornerRadius(8)
}
```

### 3. Pattern Summary Card (InsightsScreen)

```swift
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Text(pattern.theme)
            .font(.headline)

        if pattern.isRecent {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
        }

        Spacer()

        Text("\(pattern.frequency)×")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.blue)
    }

    Text("Over \(pattern.daySpan) days")
        .font(.caption)
        .foregroundColor(.secondary)

    HStack {
        Button("View All") {
            viewModel.showPattern(pattern)
        }

        Button("Create Task") {
            viewModel.createTaskForPattern(pattern)
        }
    }
}
.padding()
.background(Color.gray.opacity(0.1))
.cornerRadius(12)
```

---

## Performance Considerations

### Caching Strategy

```swift
// Cache insights for recently viewed thoughts
private var insightsCache: [UUID: ThoughtInsight] = [:]
private let cacheDuration: TimeInterval = 300 // 5 minutes

func getCachedInsights(for thought: Thought) -> ThoughtInsight? {
    guard let cached = insightsCache[thought.id],
          cached.timestamp.timeIntervalSinceNow > -cacheDuration else {
        return nil
    }
    return cached
}
```

### Async Loading

- Load related thoughts asynchronously
- Show UI immediately, populate when ready
- Use skeleton views for loading states

### Batch Processing

- Pattern detection runs once per screen load
- Cache results for session
- Background refresh on new thought capture

---

## Privacy & Data

### Local-Only Processing

- All semantic analysis happens on-device
- Uses iOS 26 `NLEmbedding` (on-device model)
- No data sent to servers
- No tracking of themes/patterns

### User Control

**Settings:**
- Enable/disable related thoughts
- Enable/disable duplicate warnings
- Enable/disable pattern notifications
- Clear insights cache

---

## Testing Strategy

### Unit Tests

```swift
@Test("Find related thoughts with semantic similarity")
func testFindRelatedThoughts() async {
    let service = SmartInsightsService.shared

    let thought1 = Thought(content: "Need to exercise more")
    let thought2 = Thought(content: "Should start working out")
    let thought3 = Thought(content: "Buy groceries")

    let related = await service.findRelatedThoughts(
        for: thought1,
        in: [thought2, thought3]
    )

    #expect(related.count == 1)
    #expect(related.first?.thought.id == thought2.id)
    #expect(related.first?.score > 0.5)
}

@Test("Detect patterns by tag")
func testPatternDetection() async {
    let service = SmartInsightsService.shared

    let thoughts = [
        Thought(content: "Exercise idea", tags: ["health"]),
        Thought(content: "Workout plan", tags: ["health"]),
        Thought(content: "Diet notes", tags: ["health"]),
        Thought(content: "Meeting notes", tags: ["work"])
    ]

    let patterns = await service.detectPatterns(in: thoughts)

    #expect(patterns.count >= 1)
    let healthPattern = patterns.first { $0.theme == "health" }
    #expect(healthPattern?.frequency == 3)
}

@Test("Identify unresolved questions")
func testUnresolvedThoughts() {
    let service = SmartInsightsService.shared

    let thoughts = [
        Thought(content: "What's the best productivity system?"),
        Thought(content: "Regular note"),
        Thought(content: "How do I learn SwiftUI?")
    ]

    let unresolved = service.findUnresolvedThoughts(in: thoughts)

    #expect(unresolved.count == 2)
}
```

### Manual Testing Checklist

**Phase 1:**
- [ ] Related thoughts appear on detail screen
- [ ] Similarity warning shows when capturing duplicate
- [ ] Clicking related thought navigates correctly
- [ ] Empty state when no related thoughts
- [ ] Performance with 1000+ thoughts

**Phase 2:**
- [ ] Patterns detected correctly
- [ ] Pattern frequency is accurate
- [ ] Time spans calculated correctly
- [ ] Unresolved thoughts identified
- [ ] Summary generation works

**Phase 3:**
- [ ] Location triggers work correctly
- [ ] Time-based triggers fire appropriately
- [ ] Calendar context works
- [ ] Focus mode integration functional

---

## Future Enhancements

### Semantic Clustering (Beyond Tags)

Use NLEmbedding to cluster thoughts by meaning, not just tags:

```swift
// Group by semantic similarity
let clusters = await semanticSearch.cluster(thoughts, threshold: 0.7)
// Result: ["productivity" cluster, "health" cluster, "work" cluster]
```

### AI-Generated Insights

Use Foundation Models to generate insights:

```swift
"You've thought about productivity 7 times this month.
 Common theme: You struggle with focus in the afternoons.
 Suggestion: Try time-blocking your afternoon tasks."
```

### Spaced Repetition Resurfacing

Surface important thoughts at optimal intervals:

```swift
// Resurface based on forgetting curve
- Day 1: Initial capture
- Day 3: First resurface
- Day 7: Second resurface
- Day 30: Third resurface
```

### Smart Linking

Automatically create relationships between thoughts:

```swift
// Detect project relationships
"Q1 roadmap" ← links to → "Product priorities" ← links to → "User feedback"
```

---

## Success Metrics

### Engagement Metrics
- **Related thoughts click rate:** % of users who tap related thoughts
- **Duplicate prevention:** % of duplicates caught before creation
- **Pattern action rate:** % of patterns that lead to task creation

### Utility Metrics
- **Thoughts revisited:** Average thoughts viewed per session
- **Pattern coverage:** % of thoughts that are part of a pattern
- **Unresolved resolution:** % of unresolved items that get acted on

### User Satisfaction
- **Feature usage:** % of active users using resurfacing features
- **Retention impact:** Retention improvement vs control group
- **Feedback:** User ratings and comments

---

## Implementation Status

### ✅ Completed
- [x] `SemanticSearchService.swift` - Semantic search foundation
- [x] `SmartInsightsService.swift` - Core resurfacing logic
- [x] Documentation

### 🚧 In Progress
- [ ] `DetailScreen` - Add related thoughts section
- [ ] `DetailViewModel` - Load related thoughts
- [ ] `CaptureScreen` - Add similarity warning
- [ ] `CaptureViewModel` - Check for similar thoughts

### 📋 Planned (Phase 2)
- [ ] `InsightsScreen` - Add pattern summary
- [ ] `InsightsViewModel` - Pattern analysis
- [ ] Weekly digest notification
- [ ] Pattern detail view

### 🔮 Future (Phase 3)
- [ ] Location-based triggers
- [ ] Time-based resurfacing
- [ ] Calendar integration
- [ ] Focus mode integration

---

## Developer Guide

### Adding a New Pattern Type

```swift
// 1. Extend pattern detection in SmartInsightsService
func detectCustomPattern(in thoughts: [Thought]) -> [ThoughtPattern] {
    // Your detection logic
}

// 2. Add to comprehensive pattern detection
func detectPatterns(in thoughts: [Thought]) async -> [ThoughtPattern] {
    var patterns = detectTagPatterns(in: thoughts)
    patterns.append(contentsOf: detectCustomPattern(in: thoughts))
    return patterns.sorted { $0.frequency > $1.frequency }
}
```

### Adding a New Insight Type

```swift
// 1. Define new insight struct
public struct CustomInsight {
    let type: String
    let severity: InsightSeverity
    let actionable: Bool
}

// 2. Add to ThoughtInsight
public struct ThoughtInsight {
    // ... existing properties
    let customInsights: [CustomInsight]
}

// 3. Implement detection
func detectCustomInsights(for thought: Thought) -> [CustomInsight] {
    // Your logic
}
```

---

## References

- **Semantic Search:** `Sources/Services/Intelligence/SemanticSearchService.swift`
- **Smart Insights:** `Sources/Services/Intelligence/SmartInsightsService.swift`
- **iOS 26 NLEmbedding:** [Apple Documentation](https://developer.apple.com/documentation/naturallanguage/nlembedding)
- **Design Inspiration:** Obsidian backlinks, Roam Research bidirectional links

---

**Last Updated:** February 1, 2026
**Next Review:** After Phase 1 completion
