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

## [0.5] - Crash Fixes & Streak Overhaul - 2026-02-23 (Build 1)

### Fixed

- **CoreData threading crashes (critical)** — All repository read operations were accessing `viewContext` from background actor threads, causing `EXC_BAD_ACCESS` memory corruption crashes. All reads now use `newBackgroundContext()` with proper `context.perform {}` wrapping.
- **Voice capture transcript wipe** — Transcribed text was being cleared every 1–2 seconds due to aggressive on-device silence detection. Switched to server-based recognition (longer silence tolerance) with automatic session restart across OS-managed boundaries. Voice now captures continuously without interruption.
- **Voice captures not counting toward streak or acorns** — Thoughts saved via voice capture were never calling the gamification hooks, so streaks, acorns, badges, and companion progress were all silently skipped for voice captures.
- **Streak showing stale value after lapse** — Current streak was loaded from UserDefaults at launch without checking if it had lapsed overnight. Streak now validates on init and every time the app returns to foreground.
- **Streak inconsistency across screens** — Insights, Achievements, and Browse were each reading from different sources (ChartDataService vs StreakTracker), causing different numbers on every screen. All screens now use StreakTracker as the single source of truth.
- **Longest streak lower than current streak** — ChartDataService computed streaks without grace day logic, so a grace-day-bridged streak would appear shorter in Insights than in Achievements. StreakTracker now reconciles all three stats (current streak, longest streak, total capture days) from authoritative thought history on every Achievements load.

### Changed

- **Siri shortcut renamed** — "Capture a Thought" → "Stash a Thought". Try: *"Hey Siri, stash a thought in STASH"*
- **Free tier limit** — Reduced from 50 to 30 thoughts/month ("a thought a day"). Easily adjustable via `freeMonthlyThoughtLimit` constant as we watch beta analytics.

---

## [0.4] - Shinies Live & Onboarding Polish - 2026-02-21 (Build 6)

### Fixed

- **Shinies persistence (#40)** — `isShiny` flag was not being written to CoreData on updates, so promoted thoughts reverted to non-shiny after restarting the app. Fixed in both `ThoughtService.update()` (two `Thought` initializers that dropped the flag during tag normalization and timestamp updates) and `ThoughtRepository.update()` (missing field write).
- **Growth tree labels** — Companion card life stage labels now use plant-themed names: Sprout → Curious → Seasoned → Elder → Legendary, matching the acorn-to-oak metaphor.

### Changed

- **Onboarding — Shinies step** — Updated copy from "coming soon" placeholder to explain how Shinies actually work: thoughts are scored on sentiment intensity, task linkage, connection count, capture energy, age, and length; high-scoring thoughts (≥ 1.5 pts) are promoted daily and surfaced in the "Today's Shiny" card on Browse.
- **Onboarding — acorn step** — Updated copy to mention the Acorn Shop.

### Added

- Back button on onboarding tutorial screens.

---

## [0.3] - Gamification & Polish - 2026-02-17

### Added

**Squirrelsona Tamagotchi Layer (#44)**
- Life stages: Sprout → Curious → Seasoned → Elder → Legendary (lifetime capture milestones)
- Emotional states: Thriving, Curious, Napping, Waiting, Celebrating — derived from streak data
- Adventure mode: 3+ day gaps send squirrel on adventure; 5 rotating illustrated variants (base, chef, painter, pilot, professor)
- Accessories & Acorn Shop: 8 purchasable + 2 milestone-unlock accessories; equip/unequip from shop sheet
- All illustrated portraits wired to asset catalog — transparent background PNGs, portrait layout

**Squirrelsona Emotional Gauge (#39)**
- SquirrelStateEngine: instant, offline, deterministic state from StreakTracker
- Per-persona × per-state commentary tables for all 5 built-in personas

**Squirrel-Sona Personalization System (#13)**
- Persona portraits on cards and detail sheets — randomized squirrel header on screen appear
- PersonalizationScreen persona grid with set-default, edit, delete

**Search Improvements**
- Semantic search threshold lowered (0.3 → 0.2) for better recall
- Keyword fallback tokenized — individual word matching instead of exact phrase
- Tags included in both semantic and keyword search paths
- Search now filters to active thoughts only

**UX Polish**
- Thought row timestamps: replaced second-ticker with minute-granularity relative labels ("Just now", "X min ago", etc.) using TimelineView
- About screen now shows live version and build number from Bundle.main
- Insights: AI generation fires as background task — charts load instantly

### Changed

**Major UX Overhaul — Mood/Growth Separation & Compact Layout**
- Companion card redesigned: left = mood squirrel (emotional state), right = growth tree (lifecycle stage)
- Tree emoji progression: 🌰 Sprout → 🌱 Curious → 🪴 Seasoned → 🌳 Elder/Legendary (acorn to oak metaphor)
- Removed persona name, greeting text, life stage badge from card — pure visual split
- Card height reduced ~40% via tighter padding and removed spacers
- Shop button moved from card to toolbar (next to acorn balance bubble)
- BrowseScreen: search removed from main view (now only in Search tab for cleaner layout)
- Navigation bar switched to inline mode — reclaims ~52px below toolbar
- Companion card + filter banner moved OUT of List into pinned header — eliminates 3 section gaps (~105px)
- Total vertical space recovered on main screen: ~200px
- All persona emoji replaced with actual squirrel portrait images in chat screens (ThoughtConversationScreen, ConversationScreen)
- Search screen: "Dig through the hoard..." placeholder, squirrel image in empty state

**Theme Rendering Fixes**
- Fixed minimalist theme dark card rendering — replaced iOS 26 `.glassEffect` (dark frosted glass on light backgrounds) with themed surface fills
- Updated InsightsScreen (5 cards), BrowseScreen (filter chips), chat bubbles (ConversationScreen, ThoughtConversationScreen), AIInsightsView (2 panels)
- Added `OutlinedToggleStyle` for themes with low contrast toggle off-state (minimalist theme)
- Added `usesOutlinedToggles` protocol property to `ThemeVariant` — minimalist theme enables bordered off-state

### Fixed
- Insights screen hang on open (FoundationModels cold start was blocking UI)
- Portrait squirrel images no longer cropped by circle clip — scaledToFit in portrait frame
- Build warnings: removed deprecated ALWAYS_SEARCH_USER_PATHS and ENABLE_STRICT_OBJC_MSGSEND
- Removed stale WatershipDown placeholder asset references
- Minimalist theme toggle visibility — off-state now has clear border instead of near-transparent fill
- BrowseViewModel `hasActiveFilters` no longer checks `searchText` (search removed from Browse)

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
