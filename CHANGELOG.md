# Changelog

All notable changes to STASH will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### In Development
- Smart date/time parsing from natural language (Phase 4)
- Calendar selection in settings (Phase 4)
- Event duration intelligence (Phase 4)

### Known Issues
- HealthKit step count sometimes not collecting properly (#TBD)
- Location name occasionally blank despite having coordinates (#TBD)

---

## [0.1.0] - Phase 3A Complete - 2026-01-20

### Current Status
Development version - Phase 3A implementation complete. Not yet released to TestFlight or App Store.

### Added - Core Features

**Thought Capture**
- Text input for capturing thoughts
- Voice input with real-time transcription (Speech Recognition framework)
- Quick capture from main screen

**AI Classification**
- Automatic classification into 5 types: Task, Note, Idea, Reminder, Event
- Confidence scoring for classifications
- Sentiment analysis (6 emotions: happy, sad, angry, fearful, surprised, neutral)
- User feedback system to correct misclassifications (for future model fine-tuning)

**Context Gathering**
- Location tracking with reverse geocoding (10m precision)
- Manual location refresh button
- HealthKit integration:
  - Sleep data collection
  - Step count / activity data
  - Heart Rate Variability (HRV)
- Calendar availability checking (are you free right now?)
- Time of day tracking (morning, afternoon, evening, night)
- Energy level calculation (4-component algorithm):
  - Sleep quality: 40% weight
  - Activity/steps: 25% weight
  - HRV: 20% weight
  - Time of day: 15% weight
- Energy breakdown debug view with raw HealthKit values

**Smart Actions**
- Create iOS Reminders from thoughts classified as "reminder"
- Create Calendar Events from thoughts classified as "event"
- Create Reminders from thoughts classified as "task"
- Manual and automatic modes for creation

**Data Management**
- Full CRUD operations on thoughts:
  - Create new thoughts
  - Read/browse thought list
  - Edit existing thoughts
  - Delete thoughts (with confirmation dialog)
- Tag system:
  - Create custom tags
  - Apply multiple tags to thoughts
  - Filter by tags
- Thought detail view with all context information
- Swipe-to-delete on thought list

**User Interface**
- Main thought list (browse all captured thoughts)
- Capture screen (text and voice input)
- Detail screen (view/edit individual thoughts)
- Settings screen
- Energy breakdown debug screen
- Dark mode support (system-based)

### Technical Implementation

**Architecture**
- SwiftUI for all UI components
- Swift Concurrency (async/await) throughout
- Protocol-oriented architecture with dependency injection
- Core Data for local persistence
- Fail-soft permission handling (graceful degradation)

**Services Layer**
- ClassificationService (AI classification and sentiment)
- ContextService (orchestrates all context gathering)
- LocationService (CoreLocation integration)
- HealthKitService (HealthKit data collection)
- CalendarService (EventKit integration)
- SpeechService (voice transcription)
- TaskService (Reminder/Event creation)
- PersistenceService (Core Data management)

**Performance**
- Parallel context gathering using TaskGroup (<300ms target when cached)
- Efficient Core Data queries
- Lazy loading where appropriate

**Compatibility**
- iOS 18.0+ (deployment target)
- iPhone support (SE through Pro Max)
- iPad support (UI adapts)

### Permissions & Privacy
- Location: "When in Use" for context gathering
- HealthKit: Sleep, Steps, HRV (read-only)
- Calendar/Reminders: Read calendar, write reminders/events
- Microphone: Voice input
- Speech Recognition: Transcription

All permissions are optional with fail-soft behavior:
- App works without any permissions granted
- Features gracefully degrade (e.g., energy calculation from time of day only if HealthKit denied)

### Development Tools & Process
- Xcode 15.2+
- Swift Package Manager for dependencies (currently none)
- Git version control
- Comprehensive documentation:
  - Architecture docs in `/docs/development/`
  - Planning docs in `/docs/planning/`
  - Operations docs in `/docs/operations/`

### Documentation Created
- Complete operations guide (issue tracking, support, releases, monitoring, CI/CD)
- Product roadmap through Phase 6
- Backend strategy (Supabase + Custom AI hybrid recommended)
- Testing strategy with 3-phase beta program
- Technical debt tracking
- 17 markdown documentation files total

---

## Release Note Templates

### For TestFlight Beta

```
Thanks for testing STASH!

**What's New:**
- [Feature highlights]

**What to Test:**
- [Specific areas for feedback]

**Known Issues:**
- [Any current bugs]

**Feedback:**
Use the in-app feedback button or email support@yourapp.com
```

### For App Store Release

```
✨ What's New in [VERSION]

NEW FEATURES
• [Feature 1 with benefit]
• [Feature 2 with benefit]

BUG FIXES
• Fixed [issue] ([GitHub issue #] if public)
• Improved [area]

IMPROVEMENTS
• [Performance or UX enhancement]

Questions? Tap Help & Feedback in Settings.
```

---

## Version History Format

```markdown
## [VERSION] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Deprecated
- Features being phased out

### Removed
- Features removed

### Security
- Security fixes
```

---

## Notes

- Version 0.1.0 is the Phase 3A development milestone
- First public release will be 1.0.0 after Phase 4 features and backend setup
- Beta releases will use version format: 0.x.0-betaX (e.g., 0.9.0-beta1)
- This changelog will be updated with each release
- GitHub releases will reference this changelog
- App Store release notes will be derived from relevant changelog sections

---

**Last Updated:** 2026-01-20
