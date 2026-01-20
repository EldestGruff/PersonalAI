# Feature Roadmap

This document tracks planned features and enhancements for PersonalAI.

## Reminders & Calendar

### High Priority
- [ ] **Smart date/time extraction for calendar events** (Options 2 & 3)
  - Enhance Classification model to extract dates/times from thought content
  - Parse natural language dates like "Thursday at 2pm" → actual calendar date
  - Fall back to date picker if parsing fails or is ambiguous
  - Extract event title separately from date/time info
  - Related: `Sources/Models/Classification.swift`, `Sources/Services/AI/ClassificationService.swift`

- [ ] **Reminder/Event settings**
  - Choose which reminder list to add to (default vs. others)
  - Choose which calendar to add events to
  - Default event duration settings
  - Reminder notification timing preferences
  - Related: `Sources/UI/Screens/SettingsScreen.swift`

### Medium Priority
- [ ] **Event duration intelligence**
  - Parse duration hints from content ("1 hour meeting", "30 minute call")
  - Smart defaults based on event type (meetings = 1hr, calls = 30min, etc.)
  - Learn from user's typical event durations

- [ ] **Reminder due date extraction**
  - Extract due dates for reminders ("remind me tomorrow", "by Friday")
  - Set reminder alerts based on parsed timing

- [ ] **Calendar conflict detection**
  - Warn if creating event conflicts with existing calendar entries
  - Suggest alternative times

## Context & Intelligence

### Medium Priority
- [ ] **Fix context data collection** (Currently pending)
  - Debug step count collection from HealthKit
  - Debug location name extraction
  - Related: Todo item #4

## UI/UX Improvements

### Low Priority
- [ ] **Batch operations**
  - Select multiple thoughts for bulk actions
  - Bulk tagging, archiving, deletion

- [ ] **Search enhancements**
  - Search by date range
  - Search by classification type
  - Search by sentiment
  - Save search filters

## Infrastructure

### Future
- [ ] **Offline mode improvements**
  - Better offline indicator
  - Sync conflict resolution UI
  - Queue status visibility

---

**Last updated:** 2026-01-19
