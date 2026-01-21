# PersonalAI

A context-aware thought capture and intelligent organization system for iOS.

## Overview

PersonalAI helps you capture thoughts, ideas, tasks, and reminders while automatically gathering context from your device to provide intelligent classification and organization. The app learns from your feedback to continuously improve its understanding of your workflow.

## Current Status: Phase 3A Complete ✅

### Working Features
- **Thought Capture:** Voice and text input with real-time transcription
- **AI Classification:** Automatic categorization (task, note, idea, reminder, event)
- **Sentiment Analysis:** Emotional tone detection
- **Context Awareness:**
  - Location tracking with reverse geocoding (10m precision)
  - HealthKit integration (sleep, activity/steps, HRV)
  - Calendar availability checking
  - Energy level calculation (4-component algorithm)
  - Time of day tracking
- **Smart Actions:** Create tasks, reminders, and events from thoughts
- **Full CRUD:** Create, read, update, delete thoughts
- **Tag Management:** Organize with custom tags
- **Feedback System:** Correct classifications to improve AI accuracy
- **Debug Views:** Energy breakdown showing raw HealthKit values

### Technical Highlights
- SwiftUI + Swift concurrency (async/await)
- Core Data persistence
- Parallel context gathering (<300ms target)
- Fail-soft permission handling
- iOS 18+ with backwards compatibility patterns

## Documentation

### 📖 [Complete Documentation Index](./docs/DOCUMENTATION_INDEX.md)
**Start here for full documentation navigation**

### 🏗️ Planning & Strategy
**[/docs/planning/](./docs/planning/)** - Product roadmap, backend strategy, customer requests, testing

- **[ROADMAP.md](./docs/planning/ROADMAP.md)** - Product vision and phased development plan
- **[BACKEND_STRATEGY.md](./docs/planning/BACKEND_STRATEGY.md)** - Backend architecture and implementation plan
- **[CUSTOMER_REQUESTS.md](./docs/planning/CUSTOMER_REQUESTS.md)** - Feature requests and bug tracking
- **[TESTING_STRATEGY.md](./docs/planning/TESTING_STRATEGY.md)** - QA approach and beta testing plan
- **[TECHNICAL_DEBT.md](./docs/planning/TECHNICAL_DEBT.md)** - Code quality and refactoring tracking

### ⚙️ Operations & Maintenance
**[/docs/operations/](./docs/operations/)** - Running the software business (NEW!)

- **[OPERATIONS_OVERVIEW.md](./docs/operations/OPERATIONS_OVERVIEW.md)** - Big picture of running a software company
- **[GITHUB_ISSUES_SETUP.md](./docs/operations/GITHUB_ISSUES_SETUP.md)** - Bug and feature tracking setup
- **[SUPPORT_WORKFLOW.md](./docs/operations/SUPPORT_WORKFLOW.md)** - Customer support process
- **[RELEASE_PROCESS.md](./docs/operations/RELEASE_PROCESS.md)** - App Store release checklist
- **[MONITORING_SETUP.md](./docs/operations/MONITORING_SETUP.md)** - Crash reporting and analytics
- **[CI_CD_SETUP.md](./docs/operations/CI_CD_SETUP.md)** - Automated testing and builds

### 🎯 Feature Tracking
**[FEATURES.md](./FEATURES.md)** - Detailed feature specifications and priorities

### 🛠️ Development
**[/docs/development/](./docs/development/)** - Architecture principles and patterns

- **[ARCHITECTURE_AS_PROTOCOL.md](./docs/development/ARCHITECTURE_AS_PROTOCOL.md)** - Core architecture principles
- **[ORCHESTRATION_STRATEGY.md](./docs/development/ORCHESTRATION_STRATEGY.md)** - Service coordination patterns
- **[STANDARDS_INTEGRATION.md](./docs/development/STANDARDS_INTEGRATION.md)** - iOS integration standards

### 📖 Phase Specifications
**[/PhaseDocs/](./PhaseDocs/)** - Phase 3A implementation specifications (data models, services, UI)

## Project Structure

```
PersonalAI/
├── Sources/
│   ├── Models/              # Data models (Thought, Classification, Context, etc.)
│   ├── Services/            # Business logic layer
│   │   ├── AI/              # Classification and sentiment analysis
│   │   ├── Context/         # Location, HealthKit, Calendar services
│   │   ├── Speech/          # Voice transcription
│   │   └── Task/            # Reminder/event creation
│   ├── UI/
│   │   ├── Screens/         # Main app screens
│   │   ├── Components/      # Reusable UI components
│   │   └── ViewModels/      # Screen view models
│   └── PersonalAIApp.swift  # App entry point
├── Tests/                   # Unit and integration tests
├── docs/                    # Documentation
│   ├── planning/            # Product planning and strategy
│   └── development/         # Architecture and dev docs
├── PhaseDocs/               # Phase implementation specs
└── FEATURES.md              # Feature tracking
```

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 18.0+ device or simulator
- Apple Developer account (for device testing with HealthKit)

### Setup
1. Clone the repository
2. Open `PersonalAI.xcodeproj` in Xcode
3. Select a simulator or connected device
4. Build and run (⌘R)

### Permissions
The app will request permissions for:
- **Microphone:** Voice input for thought capture
- **Speech Recognition:** Transcribe voice to text
- **Location:** Context gathering (when in use)
- **HealthKit:** Sleep, activity, and HRV data
- **Calendars/Reminders:** Read availability and create entries

All features gracefully degrade if permissions are denied.

## Development Workflow

### Adding Features
1. Check **[ROADMAP.md](./docs/planning/ROADMAP.md)** for planned features
2. Review **[FEATURES.md](./FEATURES.md)** for specifications
3. Log progress in **[CUSTOMER_REQUESTS.md](./docs/planning/CUSTOMER_REQUESTS.md)**
4. Follow patterns in **[/docs/development/](./docs/development/)**
5. Add tests per **[TESTING_STRATEGY.md](./docs/planning/TESTING_STRATEGY.md)**

### Reporting Bugs
1. Check **[CUSTOMER_REQUESTS.md](./docs/planning/CUSTOMER_REQUESTS.md)** for existing reports
2. Add new bug report using the template
3. Include steps to reproduce and expected behavior
4. Link to relevant code files

## Next Steps (Phase 4)

- Smart date/time extraction from natural language
- Reminder/event settings (calendar selection, defaults)
- Event duration intelligence
- Calendar conflict detection
- Backend infrastructure setup (see [BACKEND_STRATEGY.md](./docs/planning/BACKEND_STRATEGY.md))

## Architecture Highlights

### Data Flow
```
User Input → Transcription → Classification → Context Gathering → Persistence
                                    ↓
                              Sentiment Analysis
                                    ↓
                              Smart Actions (Tasks/Events)
```

### Service Architecture
- **Dependency Injection:** Constructor-based DI for testability
- **Protocol-Oriented:** All services defined by protocols
- **Async/Await:** Modern Swift concurrency throughout
- **Fail-Soft:** Graceful degradation when services unavailable
- **Parallel Execution:** Context gathering uses TaskGroup for speed

## Contributing

This is a personal project, but feedback and suggestions are welcome! Please:
1. Review existing documentation before proposing changes
2. Follow the architecture patterns in `/docs/development/`
3. Add tests for new features
4. Update relevant documentation

## License

[To be determined]

## Contact

[Your contact information]

---

**Last Updated:** 2026-01-20
