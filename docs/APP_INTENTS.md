# App Intents - Siri & Shortcuts Integration

PersonalAI App Intents enable Siri voice control, Shortcuts automation, and Spotlight search integration.

## Overview

App Intents make PersonalAI a first-class citizen in the iOS ecosystem:

- **Siri**: Hands-free voice capture and search
- **Shortcuts**: Powerful automation workflows
- **Spotlight**: System-wide thought search
- **Focus Filters**: Context-aware filtering (future)

## Implementation Files

Located in `Sources/AppIntents/`:

- **ThoughtAppEntity.swift** - App Entity for Shortcuts/Siri (renamed to avoid CoreData conflict)
- **CaptureThoughtIntent.swift** - Voice capture intent
- **SearchThoughtsIntent.swift** - Search with filters
- **ReviewIntent.swift** - Filtered review intent

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

Quick capture with voice or text input.

**Siri Phrases:**
- "Capture a thought"
- "Save a note in PersonalAI"
- "Remember this"

**Parameters:**
- `content` (String): What to capture
- `type` (ThoughtTypeEnum?): Optional classification override
- `autoClassify` (Bool): Use AI classification (default: true)

**Shortcuts Use Cases:**
- Voice dictation capture
- Location-triggered capture
- Time-based capture (daily journal)
- Batch import from other apps

### 2. Search Thoughts Intent

Find thoughts with advanced filters.

**Siri Phrases:**
- "Find thoughts about [query]"
- "Search my ideas"
- "Show me recent questions"

**Parameters:**
- `query` (String?): Search keywords
- `typeFilter` (ThoughtTypeEnum?): Filter by type
- `dateRange` (DateRangeEnum?): Time period
- `maxResults` (Int): Result limit (1-100, default: 20)

**Date Ranges:**
- Today, Yesterday
- This Week, Last Week
- This Month, Last Month

**Shortcuts Use Cases:**
- Morning standup preparation
- Weekly review automation
- Export thoughts
- Generate summaries

### 3. Review Intent

Open app with filtered view.

**Siri Phrases:**
- "Review my thoughts"
- "Show my reminders"
- "What ideas did I have this week?"

**Parameters:**
- `typeFilter` (ThoughtTypeEnum?): Show only specific type
- `dateRange` (DateRangeEnum?): Time period
- `showCompleted` (Bool): Include completed items

**Shortcuts Use Cases:**
- Morning review routine
- Evening reflection
- Weekly planning
- GTD-style reviews

## Shortcuts Examples

### Daily Review Routine

```
Morning Review:
1. Review Intent (reminders, today, hide completed)
2. If count > 0: Show notification
3. Open PersonalAI
```

### Voice Journal

```
Evening Journal:
1. Ask for input: "How was your day?"
2. Capture Thought (content = input, type = note)
3. Show notification: "Journal entry saved"
```

### Weekly Summary

```
Weekly Summary:
1. Search Intent (dateRange = thisWeek)
2. Get count by type
3. Create summary text
4. Share via Messages/Email
```

## Troubleshooting

### Siri Not Finding Intent

1. Settings → Siri & Search → PersonalAI → Enable all
2. Rebuild app with AppIntents metadata
3. Try exact phrase: "Capture a thought in PersonalAI"

### Shortcuts Not Appearing

1. Launch PersonalAI at least once
2. Wait a few minutes for indexing
3. Force quit Shortcuts app and reopen
4. Check Shortcuts → Apps → PersonalAI

### Spotlight Not Finding Thoughts

1. Settings → Siri & Search → "Show in Search" enabled
2. Wait for indexing (15-30 minutes)
3. Capture new thoughts to trigger indexing

## Technical Details

### Architecture

```
ThoughtAppEntity (renamed from ThoughtEntity)
├── EntityQuery protocol
├── EntityStringQuery protocol
└── Display representations with SF Symbols

CaptureThoughtIntent
├── Background execution
├── AI classification integration
└── Intent donation for Siri suggestions

SearchThoughtsIntent
├── Natural language query
├── Date range filtering
└── Returns ThoughtAppEntity[]

ReviewIntent
├── Opens app with filters
└── Dialog summary
```

### Dependencies

- `ThoughtRepositoryProtocol` - Save/fetch thoughts
- `ClassificationServiceProtocol` - Auto-classify content

### Performance

- **Capture**: < 500ms (with AI)
- **Search**: < 100ms for 1000 thoughts
- **Review**: < 50ms (opens app)

## Future Enhancements

- Focus Filter integration
- Live Activities
- Widgets showing recent captures
- Rich notifications with actions

---

**Related:**
- [iOS 26 Modernization Plan](../MODERNIZATION_AUDIT.md)
- [Issue #17](https://github.com/EldestGruff/PersonalAI/issues/17)
- Sources: `Sources/AppIntents/`

**Status**: Implementation complete, awaiting device testing
**Requires**: Physical iOS device for Siri
**iOS Version**: 26.0+
