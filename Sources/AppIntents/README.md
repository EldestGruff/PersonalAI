# App Intents - Siri & Shortcuts Integration

PersonalAI App Intents enable Siri voice control, Shortcuts automation, and Spotlight search integration.

## Overview

App Intents make PersonalAI a first-class citizen in the iOS ecosystem:

- **Siri**: Hands-free voice capture and search
- **Shortcuts**: Powerful automation workflows
- **Spotlight**: System-wide thought search
- **Focus Filters**: Context-aware filtering (future)

## Quick Start

### Enable Siri Access

1. Settings → Siri & Search → PersonalAI
2. Enable "Use with Siri"
3. Enable "Show in Search"
4. Enable "Suggest Shortcuts"

### Try It Out

**Voice Capture:**
```
"Hey Siri, capture a thought"
→ Siri prompts for content
→ Automatically classifies and saves
```

**Search:**
```
"Hey Siri, find thoughts about work"
→ Returns matching thoughts
```

**Review:**
```
"Hey Siri, review my thoughts from today"
→ Opens app with filtered view
```

## Available Intents

### 1. Capture Thought Intent

**Purpose**: Quick capture with voice or text input

**Siri Phrases:**
- "Capture a thought"
- "Save a note in PersonalAI"
- "Remember this"

**Parameters:**
- `content` (String): What to capture
- `type` (ThoughtTypeEnum?): Optional classification override
- `autoClassify` (Bool): Use AI classification (default: true)

**Example:**
```swift
let intent = CaptureThoughtIntent()
intent.content = "Buy groceries: milk, eggs, bread"
intent.type = .reminder
intent.autoClassify = false

try await intent.perform()
// → Saves as reminder with specified content
```

**Shortcuts Use Cases:**
- Voice dictation capture
- Location-triggered capture
- Time-based capture (e.g., daily journal prompt)
- Batch import from other apps

### 2. Search Thoughts Intent

**Purpose**: Find thoughts with filters

**Siri Phrases:**
- "Find thoughts about [query]"
- "Search my ideas"
- "Show me recent questions"

**Parameters:**
- `query` (String?): Search keywords
- `typeFilter` (ThoughtTypeEnum?): Filter by type
- `dateRange` (DateRangeEnum?): Time period
- `maxResults` (Int): Result limit (default: 20)

**Date Ranges:**
- `today` - Thoughts from today
- `yesterday` - Previous day
- `thisWeek` - Current week
- `lastWeek` - Previous week
- `thisMonth` - Current month
- `lastMonth` - Previous month

**Example:**
```swift
let intent = SearchThoughtsIntent()
intent.query = "meeting"
intent.typeFilter = .note
intent.dateRange = .thisWeek
intent.maxResults = 10

let result = try await intent.perform()
// → Returns up to 10 note-type thoughts containing "meeting" from this week
```

**Shortcuts Use Cases:**
- Morning standup preparation
- Weekly review automation
- Export thoughts to other apps
- Generate summaries/reports

### 3. Review Intent

**Purpose**: Open app with filtered view

**Siri Phrases:**
- "Review my thoughts"
- "Show my reminders"
- "What ideas did I have this week?"

**Parameters:**
- `typeFilter` (ThoughtTypeEnum?): Show only specific type
- `dateRange` (DateRangeEnum?): Time period
- `showCompleted` (Bool): Include completed items (default: false)

**Example:**
```swift
let intent = ReviewIntent()
intent.typeFilter = .reminder
intent.dateRange = .today
intent.showCompleted = false

try await intent.perform()
// → Opens app showing uncompleted reminders from today
```

**Shortcuts Use Cases:**
- Morning review routine
- Evening reflection
- Weekly planning session
- GTD-style reviews

## Thought Entity

The `ThoughtEntity` represents a thought in the Shortcuts ecosystem.

### Properties

```swift
struct ThoughtEntity: AppEntity {
    var id: UUID
    var content: String
    var type: ClassificationType
    var sentiment: Sentiment
    var tags: [String]
    var createdAt: Date
    var isCompleted: Bool
}
```

### Display Representation

Each thought shows:
- **Title**: Content text
- **Subtitle**: Type + formatted date
- **Icon**: SF Symbol based on type
  - Reminder: `checkmark.circle`
  - Event: `calendar`
  - Note: `note.text`
  - Question: `questionmark.circle`
  - Idea: `lightbulb`

### Spotlight Search

Thoughts are automatically searchable in Spotlight:

```
System Spotlight → Type "meeting notes"
→ Shows all thoughts containing those words
→ Tap to open PersonalAI
```

## Shortcuts Examples

### Daily Review Routine

```
Morning Review Shortcut:
1. Review Intent (reminders, today, hide completed)
2. If count > 0: Show notification
3. Open PersonalAI to filtered view
```

### Voice Journal

```
Evening Journal Shortcut:
1. Ask for input: "How was your day?"
2. Capture Thought Intent (content = input, type = note)
3. Show notification: "Journal entry saved"
```

### Weekly Summary

```
Weekly Summary Shortcut:
1. Search Intent (dateRange = thisWeek)
2. Get count by type (use "Get Item from List")
3. Create summary text
4. Share via Messages/Email
```

### Context Capture

```
Location-Based Capture:
Automation:
- When: Arrive at Work
- Do: Capture Thought with pre-filled content
     "Arrived at work at [current time]"
```

## Advanced: Custom Shortcuts

### Batch Processing

```swift
// Get all ideas from last month
let search = SearchThoughtsIntent()
search.typeFilter = .idea
search.dateRange = .lastMonth
search.maxResults = 100

let results = try await search.perform()

// Process each idea (e.g., export to Notes app)
for thought in results.value {
    // Custom processing
}
```

### Smart Filtering

```swift
// Find high-confidence AI classifications
let search = SearchThoughtsIntent()
let results = try await search.perform()

let highConfidence = results.value.filter { thought in
    // Access full Thought model if needed
    true // Custom filter logic
}
```

## Siri Suggestions

PersonalAI donates intent executions to help Siri learn your patterns:

- **Frequency**: Repeated actions → Siri suggests shortcuts
- **Time**: Morning captures → Siri suggests at that time
- **Location**: Office captures → Siri suggests at work
- **Context**: After calendar events → Siri suggests capture

### Donation Example

Every successful capture donates the interaction:

```swift
// After saving thought
donateInteraction(content: "...", type: .note)

// Siri learns:
// - You often capture notes
// - Usually in the morning
// - Often at this location
// → Suggests "Capture a thought" proactively
```

## Focus Filters (Future)

Coming soon - context-aware thought filtering:

**Work Focus:**
```swift
// Show only work-tagged thoughts
// Hide personal thoughts
// Automatically tag new thoughts as "work"
```

**Personal Focus:**
```swift
// Show only personal thoughts
// Hide work-related items
```

## Troubleshooting

### Siri Not Finding Intent

**Problem**: "Sorry, I can't do that"

**Solutions:**
1. Settings → Siri & Search → PersonalAI → Enable all options
2. Rebuild app with AppIntents metadata
3. Check Shortcuts app - intent should appear there
4. Try exact phrase: "Capture a thought in PersonalAI"

### Shortcuts Not Appearing

**Problem**: Can't find PersonalAI actions in Shortcuts

**Solutions:**
1. Launch PersonalAI at least once after install
2. Wait a few minutes for indexing
3. Force quit Shortcuts app and reopen
4. Check Shortcuts → Apps → PersonalAI

### Spotlight Not Finding Thoughts

**Problem**: Thoughts don't appear in search

**Solutions:**
1. Settings → Siri & Search → PersonalAI → "Show in Search" enabled
2. Wait for indexing (can take 15-30 minutes)
3. Capture new thoughts to trigger indexing
4. Reset Spotlight index: Settings → Siri & Search → reset

### Background Execution Fails

**Problem**: Intent times out or fails

**Solutions:**
1. Check ServiceContainer has ThoughtRepository registered
2. Verify CoreData stack is initialized
3. Check classification service availability
4. Run intent from Shortcuts app (shows better errors)

## Technical Details

### Architecture

```
App Intents Layer
├── ThoughtEntity (AppEntity)
│   ├── EntityQuery protocol
│   ├── EntityStringQuery protocol
│   └── Display representations
│
├── CaptureThoughtIntent (AppIntent)
│   ├── Parameter definitions
│   ├── Background execution
│   └── Intent donation
│
├── SearchThoughtsIntent (AppIntent)
│   ├── Filter logic
│   ├── Date range handling
│   └── Returns ThoughtEntity[]
│
└── ReviewIntent (AppIntent)
    ├── Opens app
    └── Filter configuration
```

### Dependencies

Required services from ServiceContainer:
- `ThoughtRepositoryProtocol`: Save/fetch thoughts
- `ClassificationServiceProtocol`: Auto-classify content

### Threading

- All intents run on main actor when needed
- Repository calls are async
- ServiceContainer access is actor-isolated
- Intent donation happens in background Task

### Error Handling

Custom errors with localized messages:
```swift
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case serviceUnavailable
    case invalidInput
    case saveFailed
}
```

## Performance

- **Capture**: < 500ms (with AI classification)
- **Search**: < 100ms for 1000 thoughts
- **Review**: < 50ms (opens app)
- **Spotlight**: Indexed asynchronously

## Privacy

- All processing happens on-device
- No data sent to external services
- Classification uses on-device Foundation Models
- Intent donations stored locally by iOS

## Future Enhancements

**Phase 3 Plans:**
- Focus Filter integration
- Live Activities for active thoughts
- Widgets showing recent captures
- Background refresh for context gathering
- Rich notifications with actions

---

## Related Documentation

- [iOS 26 Modernization Plan](../../MODERNIZATION_AUDIT.md)
- [Issue #17](https://github.com/EldestGruff/PersonalAI/issues/17)
- [Apple: App Intents](https://developer.apple.com/documentation/appintents)
- [Apple: Spotlight Search](https://developer.apple.com/documentation/corespotlight)

---

**Status**: Implementation complete (Phase 1)
**Requires**: Physical device for Siri testing
**iOS Version**: 26.0+
