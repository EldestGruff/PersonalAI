# STASH

A context-aware thought capture and intelligent organization system for iOS.

**Free and open source under the MIT license.**

[![TestFlight](https://img.shields.io/badge/TestFlight-Join%20Beta-blue)](https://testflight.apple.com/join/7MGscBJX)
[![Ko-Fi](https://img.shields.io/badge/Ko--Fi-Support%20Development-ff5e5b)](https://ko-fi.com/eldestgruff)

## Overview

STASH helps you capture thoughts, ideas, tasks, and reminders while automatically gathering context from your device — location, time of day, energy levels, calendar availability — to provide intelligent classification and organization. The app learns from your feedback to continuously improve its understanding of your workflow.

## Features

- **Thought Capture:** Voice and text input with real-time transcription
- **AI Classification:** Automatic categorization (task, note, idea, reminder, event)
- **Sentiment Analysis:** Emotional tone detection
- **Context Awareness:** Location, HealthKit (sleep/activity/HRV), calendar availability, energy level
- **Smart Actions:** Create tasks, reminders, and calendar events directly from thoughts
- **Squirrelsona Companions:** AI personas (Supportive Listener, Brainstorm Partner, Socratic Questioner, Journal Guide, Devil's Advocate)
- **Apple Watch:** Complications, quick capture, haptic feedback
- **Offline-first:** Full functionality without network access

## Getting Started

### Prerequisites

- Xcode 26.0+
- iOS 26.0+ device or simulator
- Apple Developer account (for device testing with HealthKit/Contacts)

### Setup

1. Clone the repository
2. Open `PersonalAI.xcodeproj` in Xcode
3. Select a simulator or connected device
4. Build and run (⌘R)

You'll need a Claude API key to use the AI features. Add it in Settings after first launch.

### Permissions

The app requests permissions for:
- **Microphone / Speech Recognition:** Voice input
- **Location:** Context gathering (when in use)
- **HealthKit:** Sleep, activity, and HRV data
- **Contacts:** Mention detection in thoughts
- **Calendars / Reminders:** Read availability and create entries

All features degrade gracefully if permissions are denied.

## Project Structure

```
STASH/
├── Sources/
│   ├── Models/              # Data models (Thought, Classification, Context, etc.)
│   ├── Services/            # Business logic
│   │   ├── AI/              # Claude API integration, classification, sentiment
│   │   ├── Context/         # Location, HealthKit, Calendar, Contacts services
│   │   ├── Intelligence/    # Smart resurfacing, pattern learning
│   │   ├── Monetization/    # (removed — app is free)
│   │   ├── Orchestration/   # Service coordination
│   │   ├── Speech/          # Voice transcription
│   │   └── Theme/           # ThemeEngine
│   ├── UI/
│   │   ├── Screens/         # Main app screens
│   │   ├── Components/      # Reusable UI components
│   │   └── ViewModels/      # Screen view models
│   └── STASHApp.swift       # App entry point
├── STASH Watch App/         # watchOS companion
├── STASH Watch Complications/ # WidgetKit complications
├── Tests/                   # Unit tests
├── docs/                    # Architecture and development docs
└── web/                     # Privacy policy and terms of service
```

## Documentation

- [`docs/development/`](./docs/development/) — Architecture principles and patterns
- [`docs/planning/TECHNICAL_DEBT.md`](./docs/planning/TECHNICAL_DEBT.md) — Known issues and refactoring notes
- [`docs/planning/TESTING_STRATEGY.md`](./docs/planning/TESTING_STRATEGY.md) — Testing approach
- [`docs/DECISIONS.md`](./docs/DECISIONS.md) — Architectural decision log

## Contributing

Contributions are welcome. A few guidelines:

1. Follow existing architecture patterns (see `docs/development/`)
2. New Swift files for the main iOS target require manual `project.pbxproj` entries — see `CLAUDE.md` for details
3. Keep UI theme-aware via `ThemeEngine.shared.getCurrentTheme()`
4. Test with VoiceOver enabled — accessibility is not optional

Bug reports and feature requests via GitHub Issues are appreciated.

## Support Development

STASH is free and open source. If it's useful to you, consider [buying me a coffee](https://ko-fi.com/eldestgruff).

## License

MIT License — see [LICENSE](./LICENSE).
