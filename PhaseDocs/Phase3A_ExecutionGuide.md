# Phase 3A: Comprehensive Execution Guide

**Status:** Ready to Execute  
**Target Generation:** Claude Sonnet  
**Expected Outcomes:** Complete Phase 3A iOS app foundation  
**Timeline:** 3-4 hours (Sonnet generation + review + integration)

---

## Overview

This guide walks you through generating Phase 3A code using Claude Sonnet, reviewing quality, testing locally, and integrating into your iOS project.

**What You'll Generate:**

| Spec | Deliverables | Files | Complexity |
|------|--------------|-------|-----------|
| **Spec 1** | Models, Repositories, Core Data schema | 15-20 files | Medium |
| **Spec 2** | 12 Service classes, Background tasks | 20-25 files | Very High |
| **Spec 3** | 5 Screens, 5 ViewModels, 10+ Components | 30-35 files | Very High |
| **Total** | Complete Phase 3A foundation | 65-80 files | **HUGE** |

---

## Pre-Generation Setup

### 1. Prepare Xcode Project

```bash
# Create new iOS app project
mkdir -p ~/Dev/personal-ai-ios
cd ~/Dev/personal-ai-ios

# Initialize git
git init
git config user.name "Andy"
git config user.email "andy@fennerfam.com"

# Create initial structure
mkdir -p Sources/Models
mkdir -p Sources/Services
mkdir -p Sources/ViewModels
mkdir -p Sources/UI
mkdir -p Sources/Persistence
mkdir -p Tests/Unit
mkdir -p Tests/Integration

# Create initial files
touch .gitignore
touch README.md

# Create .gitignore
cat > .gitignore << 'EOF'
# Xcode
build/
*.pbxuser
*.xcworkspace/xcuserdata/
xcuserdata/
*.xcodeproj/xcuserdata/

# iOS
*.ipa
DerivedData/

# Swift
.swiftpm/

# Build
**/Frameworks/
*.framework

# Test
.xcoverage

# OS
.DS_Store

# IDE
.vscode/
.idea/
*.swp

# Dependencies (CocoaPods if used)
Pods/
Podfile.lock
EOF

git add .
git commit -m "Initial project structure"
```

### 2. Verify Sonnet Access

You'll be using Claude Sonnet for code generation. Ensure you have:
- Access to Claude Sonnet (via claude.ai or API)
- Ability to copy/paste code
- A text editor for reviewing generated files

---

## Phase 3A Generation Sequence

### STEP 1: Generate Data Models (Spec 1)

**Time:** 5-10 minutes generation + 10 minutes review

**Run this prompt through Sonnet:**

```
You are generating Phase 3A data models for a native iOS app (Personal AI Assistant).

Here is the COMPLETE specification document you must follow exactly:

[PASTE ENTIRE CONTENT OF: Phase3A_Spec1_DataModels.md]

---

CRITICAL INSTRUCTIONS:

This is production code. Follow these standards EXACTLY:

CODE STANDARDS:
- Swift 6.0+, iOS 18+ target
- Comprehensive docstrings on every type and method
- Full type hints everywhere
- Conform to Codable for backend sync
- Use @Observable for reactive types
- Use actors for thread-safe repositories
- Error types with LocalizedError protocol
- No copy-paste code - extract patterns

WHAT TO GENERATE:

1. Models/ directory:
   - Thought.swift (Thought struct + helpers)
   - Context.swift (Context + TimeOfDay + EnergyLevel + etc enums)
   - Classification.swift (Classification + ClassificationType + Sentiment)
   - FineTuningData.swift (FineTuningData + UserFeedback)
   - Task.swift (Task + Priority + TaskStatus)
   - SyncQueue.swift (SyncQueueItem + SyncEntity + SyncAction)
   - Enums.swift (Shared enums)

2. Persistence/ directory:
   - PersistenceController.swift (Core Data stack setup)
   - ThoughtRepository.swift (actor ThoughtRepository with CRUD)
   - TaskRepository.swift
   - ClassificationRepository.swift
   - FineTuningRepository.swift
   - SyncRepository.swift

3. Tests/ directory:
   - Unit/ThoughtModelTests.swift
   - Unit/ClassificationModelTests.swift
   - Unit/ValidationTests.swift
   - Unit/CodableTests.swift
   - Integration/CoreDataIntegrationTests.swift
   - Integration/RepositoryTests.swift

4. Miscellaneous:
   - CoreData model file (PersonalAI.xcdatamodeld/PersonalAI.xcdatamodel/contents)

OUTPUT FORMAT:

Organize your response as:

## FILE: [filename]
\`\`\`swift
[complete file content]
\`\`\`

## TEST GUIDANCE:
[Notes on testing this file]

DO NOT:
- Skip files
- Use placeholders
- Leave TODOs
- Include Lorem ipsum
- Abbreviate or simplify
- Cut corners on quality

This is THE foundation. Quality here prevents rework later.

Generate production-ready code.
```

**Review Checklist:**

- ✅ All models have docstrings
- ✅ Validation methods present
- ✅ Core Data models match Swift models
- ✅ Tests cover edge cases
- ✅ No TODO comments
- ✅ Codable implementation complete
- ✅ Error types defined

**If Issues Found:**

Ask Sonnet specifically:
```
The generated models have [specific issue]. 
Please regenerate [filename] with [specific fix].
```

---

### STEP 2: Generate Service Layer (Spec 2)

**Time:** 10-15 minutes generation + 15 minutes review

**Run this prompt through Sonnet:**

```
You are generating the Service Layer for Phase 3A iOS app.

PREREQUISITE: You have just generated the data models from Phase 3A Spec 1.
Refer to those models in your service implementations.

Here is the COMPLETE specification:

[PASTE ENTIRE CONTENT OF: Phase3A_Spec2_ServiceLayer.md]

---

CRITICAL INSTRUCTIONS:

This layer orchestrates all framework integrations. Quality is critical.

CODE STANDARDS:
- All services are actor-based (thread-safe)
- All I/O is async/await (no callbacks)
- Graceful error handling (fail soft, recovery suggestions)
- Comprehensive docstrings
- Protocol-based design (Service, RepositoryBackedService, FrameworkIntegrationService)
- No blocking operations on main thread

FRAMEWORK INTEGRATION CHECKLIST:
- HealthKit: Permissions, energy level, sleep, activity
- Core Location: Location, reverse geocoding
- Core Motion: Step count, activity
- EventKit: Reminders, calendar, availability
- Contacts: Contact lookup, entity linking
- Natural Language: Sentiment, entity extraction, language detection
- Speech: Speech-to-text
- Background Tasks: Sync scheduling

WHAT TO GENERATE:

Services/ directory structure:
├─ Local/
│  ├─ ThoughtService.swift
│  └─ SearchService.swift
├─ Intelligence/
│  ├─ ClassificationService.swift
│  ├─ NLPService.swift
│  └─ FineTuningService.swift
├─ Integration/
│  ├─ HealthKitService.swift
│  ├─ LocationService.swift
│  ├─ EventKitService.swift
│  ├─ ContactsService.swift
│  ├─ MotionService.swift
│  └─ SpeechService.swift
├─ Sync/
│  ├─ SyncService.swift
│  ├─ NetworkMonitor.swift
│  └─ SyncRetryPolicy.swift
└─ Context/
   └─ ContextService.swift

Plus:
- Utilities/ - Extensions, error types, logger
- BackgroundTaskManager.swift - Scheduling background work

PERFORMANCE TARGETS (CRITICAL):
- Context gathering: <300ms
- Classification: <200ms
- Search: <100ms
- Never block main thread

OUTPUT FORMAT:

## FILE: [filename]
\`\`\`swift
[complete implementation]
\`\`\`

## INTEGRATION NOTES:
[How this service integrates with others]

DO NOT:
- Skip services
- Use mocked framework calls (real implementations)
- Miss framework integrations
- Create memory leaks (circular references)
- Block main thread

Generate production-ready services with full framework integration.
```

**Review Checklist:**

- ✅ All 12+ services implemented
- ✅ All framework integrations complete
- ✅ Error handling comprehensive
- ✅ Async/await throughout
- ✅ Actor-based for thread safety
- ✅ Permission handling correct
- ✅ Performance targets met
- ✅ No blocking operations

---

### STEP 3: Generate UI & ViewModels (Spec 3)

**Time:** 15-20 minutes generation + 20 minutes review

**Run this prompt through Sonnet:**

```
You are generating the SwiftUI UI Layer for Phase 3A iOS app.

PREREQUISITES:
- You have generated data models (Spec 1)
- You have generated services (Spec 2)
Use those in your ViewModels and Views.

Here is the COMPLETE specification:

[PASTE ENTIRE CONTENT OF: Phase3A_Spec3_UIAndViewModels.md]

---

CRITICAL INSTRUCTIONS:

This is the user-facing layer. Quality directly impacts user experience.

CODE STANDARDS:
- SwiftUI only (no UIKit in Phase 3A)
- @Observable for all ViewModels
- Comprehensive docstrings
- Accessible (VoiceOver support)
- Responsive (all iPhone sizes)
- Offline-first (works without network)
- Never blocks main thread

VIEWMODEL REQUIREMENTS:
- CaptureViewModel: Full thought capture flow
- BrowseViewModel: List, filter, sort, select
- SearchViewModel: Full-text search + pagination
- DetailViewModel: View thought, provide feedback
- SettingsViewModel: Permissions, preferences, stats

SCREEN REQUIREMENTS:
- CaptureScreen: Text + voice input, context, classification, tags
- BrowseScreen: List, filter bar, sort, swipe actions
- SearchScreen: Search bar, results, pagination
- DetailScreen: Full thought display, feedback buttons
- SettingsScreen: Permissions, features, sync, stats

REUSABLE COMPONENTS:
- TagInputView: Add/remove tags
- ClassificationBadge: Show classification
- ThoughtRowView: List item
- ContextDisplay: Show context info
- PermissionRow: Permission toggle
- FlowLayout: Custom layout for tags
- VoiceInputView: Speech capture
- (and others from spec)

NAVIGATION:
- TabView: Main navigation (Browse, Search, Settings)
- NavigationStack: Detail navigation
- Sheet: Capture modal

OUTPUT FORMAT:

## FILE: [filename]
\`\`\`swift
[complete implementation]
\`\`\`

## UX NOTES:
[Key user experience decisions]

DIRECTORY STRUCTURE GENERATED:
ViewModels/
├─ CaptureViewModel.swift
├─ BrowseViewModel.swift
├─ SearchViewModel.swift
├─ DetailViewModel.swift
└─ SettingsViewModel.swift

UI/
├─ Screens/
│  ├─ CaptureScreen.swift
│  ├─ BrowseScreen.swift
│  ├─ SearchScreen.swift
│  ├─ DetailScreen.swift
│  └─ SettingsScreen.swift
├─ Components/
│  ├─ TagInputView.swift
│  ├─ ClassificationBadge.swift
│  ├─ ThoughtRowView.swift
│  ├─ ContextDisplay.swift
│  ├─ PermissionRow.swift
│  ├─ FlowLayout.swift
│  ├─ VoiceInputView.swift
│  └─ (others)
└─ PersonalAIApp.swift (App entry point)

Utilities/
├─ AppError.swift (Error types)
└─ Extensions.swift

DO NOT:
- Use UIKit
- Miss any screen
- Leave stubs
- Incomplete bindings
- Memory issues
- Accessibility gaps

Generate production-ready SwiftUI with MVVM state management.
```

**Review Checklist:**

- ✅ All 5 ViewModels implemented
- ✅ All 5 Screens implemented
- ✅ All reusable components included
- ✅ Navigation wired correctly
- ✅ Error handling user-friendly
- ✅ Accessibility considered (VoiceOver)
- ✅ Responsive on all iPhone sizes
- ✅ No memory leaks
- ✅ Performance appropriate

---

## Post-Generation Integration

### 1. Create Xcode Project File

```bash
# In ~/Dev/personal-ai-ios, create an Xcode project manually:
# File → New → Project → iOS → App
# Name: PersonalAI
# Language: Swift
# Use SwiftUI: Yes

# OR via command line (requires xcode-select):
# This creates the necessary project structure
```

### 2. Integrate Generated Files

```bash
cd ~/Dev/personal-ai-ios

# Copy all generated files into the correct directories
# Models → Sources/Models/
# Services → Sources/Services/
# ViewModels → Sources/ViewModels/
# UI → Sources/UI/
# Persistence → Sources/Persistence/
# Tests → Tests/

# Git add everything
git add -A
git commit -m "feat: add Phase 3A complete foundation

- Data models (Thought, Task, Context, Classification, etc.)
- Core Data persistence with repositories
- Service layer (12+ services for framework integration)
- SwiftUI screens (Capture, Browse, Search, Detail, Settings)
- ViewModels with @Observable for reactive state
- Comprehensive error handling and permissions

Generated from Phase 3A specifications."
```

### 3. Verify Compilation

```bash
# Open in Xcode
open PersonalAI.xcodeproj

# Or build from command line
xcodebuild build -scheme PersonalAI
```

**Fix Any Compilation Errors:**

If Xcode shows errors:
1. Check missing imports (usually framework imports like EventKit, HealthKit, etc.)
2. Verify Swift version (must be Swift 6.0+)
3. Check deployment target (iOS 18+)
4. Look for typos in class/struct names

**Branch conversation if needed:** If compilation takes >15 minutes to fix, branch this conversation and focus on fixing errors methodically.

### 4. Run Tests

```bash
xcodebuild test -scheme PersonalAI

# Or in Xcode:
# Product → Test (Cmd+U)
```

**Expected Results:**
- 80%+ code coverage
- All tests pass
- No memory leaks (Address Sanitizer)
- No undefined behavior

If tests fail, review test output and fix methodically.

---

## Quality Gates (Before Declaring Phase 3A "Done")

### Code Quality

- [ ] 80%+ test coverage
- [ ] All public APIs have docstrings
- [ ] No TODO comments
- [ ] No print statements (use Logger)
- [ ] No force unwraps (except in tests)
- [ ] Type-safe everywhere
- [ ] Error handling complete

### Functionality

- [ ] App launches without crashes
- [ ] Can capture thought offline
- [ ] Thought persists to Core Data
- [ ] Search works locally
- [ ] Browse/filter works
- [ ] Settings screen accessible
- [ ] All permissions requested appropriately

### Performance

- [ ] Capture <5 seconds
- [ ] Context gathering <300ms
- [ ] Classification <200ms
- [ ] Search <100ms
- [ ] Memory peak <200MB
- [ ] No main thread blocking
- [ ] Smooth 60fps interactions

### Accessibility

- [ ] VoiceOver works on all screens
- [ ] Dynamic Type supported
- [ ] Color not only differentiator
- [ ] Button sizes min 44pt

### Offline-First

- [ ] Works completely offline
- [ ] Graceful degradation when context unavailable
- [ ] Sync queue works (Phase 3D, but architecture ready)

---

## Troubleshooting Common Issues

### Issue: Framework Not Found (HealthKit, EventKit, etc.)

**Solution:**
```swift
// Make sure you're importing at the top of each service:
import HealthKit
import EventKit
import CoreLocation
import Contacts
import Speech
import CoreMotion
import NaturalLanguage
```

Check your target settings:
- Project → Target → Build Phases → Link Binary With Libraries
- Ensure frameworks are added

---

### Issue: Core Data Crash on App Launch

**Solution:**

1. Check `PersistenceController.swift` initialization
2. Verify `.xcdatamodeld` file exists in project
3. Try deleting app from simulator and rebuilding:
```bash
xcrun simctl erase booted  # Erase all simulator data
xcodebuild build  # Rebuild
```

---

### Issue: @Observable Not Working (Xcode 16 vs 17 diff)

**Solution:**

Ensure deployment target is iOS 18.0+:
- Project → Target → General → Minimum Deployments: iOS 18.0

---

### Issue: Memory Leaks in Services

**Solution:**

Review all service implementations for:
- Circular references (ServiceA → ServiceB → ServiceA)
- Retained closures holding self
- Delegate references not being nil'd

Use Instruments (Xcode → Product → Profile → Memory) to verify.

---

## What's NOT in Phase 3A (Intentionally)

These will be added in later phases:

- ❌ Backend sync (Phase 4 - ClaudeService, GeminiService, OllamaService)
- ❌ iCloud sync
- ❌ Widgets
- ❌ Watch app
- ❌ Siri voice commands (App Intents)
- ❌ Advanced Vision (screen analysis)
- ❌ Machine Learning training
- ❌ Mail app integration
- ❌ HomeKit integration
- ❌ Advanced Core ML models

---

## Next Steps After Phase 3A

### Phase 3B (System Integration)
- Deeper EventKit integration (scheduling)
- HomeKit automation
- Mail app context
- Advanced Vision features
- Activity tracking UI
- Behavioral learning dashboard

### Phase 3C (Backend Integration)
- Claude API integration
- Gemini API integration
- Ollama local LLM support
- Consciousness checks
- Long-term pattern analysis
- Backend sync UI

### Phase 3D (Polish & Release)
- App Store submission
- Analytics
- Crash reporting
- Feature flags
- A/B testing
- Public beta testing

---

## Documentation

After Phase 3A generation:

Create a **Project README.md**:

```markdown
# Personal AI Assistant iOS App

Phase 3A Foundation - Offline-First Thought Capture

## Overview

Native iOS app for capturing thoughts with local intelligence enrichment.
Built with SwiftUI, Core Data, and modern Swift concurrency.

## Features (Phase 3A)

- ✅ Instant thought capture (text + speech)
- ✅ Local context enrichment (HealthKit, Location, Calendar, etc.)
- ✅ On-device classification (Foundation Models, NLP)
- ✅ Full offline operation
- ✅ System reminder/calendar integration
- ✅ Fine-tuning data collection (behavioral learning)
- ✅ Tag suggestions (AI-powered)

## Architecture

- **MVVM** with @Observable for reactive UI
- **Actor-based services** for thread safety
- **Async/await** throughout (no callbacks)
- **Core Data** for offline-first persistence
- **SwiftUI** for modern, responsive UI

## Requirements

- Xcode 16+
- iOS 18.0+
- Swift 6.0+

## Running Locally

\`\`\`bash
open PersonalAI.xcodeproj
# Cmd+R to run
\`\`\`

## Testing

\`\`\`bash
xcodebuild test -scheme PersonalAI
\`\`\`

## Project Structure

\`\`\`
PersonalAI/
├─ Sources/
│  ├─ Models/              # Data structures
│  ├─ Services/            # Business logic
│  ├─ ViewModels/          # State management
│  ├─ UI/                  # SwiftUI screens
│  └─ Persistence/         # Core Data
└─ Tests/                  # Unit + integration tests
\`\`\`

## Next Phase

Phase 3B: Enhanced System Integration & Backend Connection
```

---

## Final Checklist

After completing Phase 3A:

- [ ] All specs read and understood
- [ ] Sonnet code generation complete
- [ ] Code reviewed for quality
- [ ] Project compiles without errors
- [ ] All tests pass (80%+ coverage)
- [ ] App launches and works offline
- [ ] Git committed with clear messages
- [ ] README documentation complete
- [ ] Memory profiling done (no leaks)
- [ ] Performance targets met

---

## Questions or Issues?

If stuck:

1. **For code generation issues:**
   - Share the specific error message with Sonnet
   - Ask for a focused regeneration of just that file

2. **For integration issues:**
   - Check Xcode build settings
   - Verify all files are added to target
   - Check git status (`git status`)

3. **For architecture questions:**
   - Refer back to PHASE3A_Overview.md
   - Check the relevant spec (1, 2, or 3)

---

**Version:** 1.0  
**Status:** Ready to Execute  
**Timeline:** 3-4 hours total  
**Outcome:** Complete Phase 3A iOS foundation ready for Phase 3B  

🎯 **You've got this.** The specs are comprehensive, Sonnet is powerful, and the architecture is solid. This is the foundation your app needs.
