# Phase 3A: Comprehensive iOS Architecture & Specifications

**Status:** Ready for Code Generation  
**Target:** Swift 6.0+ / SwiftUI / iOS 18+  
**Architecture:** MVVM with Service Layer  
**Data Persistence:** Core Data + UserDefaults  
**Testing:** XCTest + async/await patterns  

---

## Table of Contents

1. [Vision & Core Principles](#vision--core-principles)
2. [Phase 3A Scope & Boundaries](#phase-3a-scope--boundaries)
3. [Complete Technology Stack](#complete-technology-stack)
4. [Architectural Patterns](#architectural-patterns)
5. [Framework Integration Map](#framework-integration-map)
6. [Data Flow Architecture](#data-flow-architecture)
7. [Service Layer Design](#service-layer-design)
8. [Code Organization](#code-organization)
9. [Success Criteria](#success-criteria)

---

## Vision & Core Principles

### The Problem We're Solving

**User Need:** Capture thoughts instantly without friction, even offline. Thoughts are enriched with context immediately and never lost.

**Technical Challenge:** Traditional cloud-first approach requires network, introduces latency, and offers no offline capability. We're inverting the model.

### Core Principles (Non-Negotiable)

| Principle | What It Means | How We Achieve It |
|-----------|---------------|-------------------|
| **Offline-First** | Works perfectly without network | All core functionality in Core Data, sync optional |
| **Local Intelligence** | Smart features without remote calls | Foundation Models, NLP, Core ML on-device |
| **Low Friction** | Thought capture <5 seconds | Minimal UI, async operations, smart defaults |
| **Privacy by Default** | Data stays local until user chooses sync | No cloud storage until explicit action |
| **Responsive Always** | UI never blocks | async/await for all I/O, background processing |
| **ADHD-Friendly** | Thoughts never disappear, no shame | Quick capture, no mandatory time-boxing, bulk actions |

Users can operate entirely in the inner circle and have a complete, functional app.

---

## Phase 3A Scope & Boundaries

### What Phase 3A Includes ✅

**Foundation & Persistence:**
- Core Data schema (Thought, Task, Context, Classification)
- Observation pattern for reactive updates
- Migration infrastructure

**Local Services:**
- ContextService (gathers time, location, activity context)
- ClassificationService (Foundation Models, NLP, tag suggestions)
- ThoughtService (CRUD, search, filtering)
- Fine-tuning tracking (user interactions for behavioral learning)

**System Integration (Phase 3A Level):**
- HealthKit (read-only: energy, sleep, activity)
- Core Location (current location + geofence status)
- Core Motion (step count, activity)
- EventKit (read calendar availability, create reminders)
- Contacts (entity linking)
- Speech (speech-to-text for capture)

**UI & Interaction:**
- Capture screen (text + speech input)
- Browse/list screen (recent thoughts, filtering)
- Search screen (full-text and tag-based)
- Settings screen (permissions, backend config)
- Detail screen (view enriched thought)

**Fine-Tuning & Learning:**
- Track user interactions (reminder creation, completion, dismissal)
- Build profile of user behavior
- Score suggestions for future improvement
- Queue interaction data for sync

**Background Processing:**
- Background task for periodic sync queue processing
- Network state monitoring
- Graceful handling of network loss mid-operation

### Phase Transitions

**Phase 3A → 3B:**
- Add more system integrations
- Enhance classification with Vision
- Add activity tracking and behavioral learning UI

**Phase 3B → 3C:**
- Deep calendar integration
- Scheduled reminders
- Time-based task surfacing

---

## Technology Stack Summary

- **SwiftUI** for all UI
- **Observation** for reactive state (@Observable)
- **Core Data** for local persistence
- **async/await** for all I/O (no callbacks)
- **Actors** for thread-safe services
- **Foundation Models** for on-device AI
- **Natural Language** for NLP
- **HealthKit, Location, Motion, EventKit, Contacts, Speech** for system integration

---

## Architecture Highlights

### MVVM Pattern
```
View (SwiftUI) → ViewModel (@Observable) → Services (Async/Await) → Repositories → Core Data
```

### Threading Model
- All services are **actors** (thread-safe)
- All I/O is **async/await** (no blocking)
- ViewModels use **@MainActor** for UI updates
- Context gathering uses **Task groups** for parallelism

### Performance Targets
- Capture: <5 seconds
- Context gathering: <300ms (7 parallel sources)
- Classification: <200ms (Foundation Models)
- Search: <100ms
- Memory peak: <200MB

---

## Success Criteria

- ✅ Instant thought capture (offline)
- ✅ Full offline operation
- ✅ Rich context from 7+ sources
- ✅ Smart classification (>85% accuracy)
- ✅ System integration (Reminders, Calendar)
- ✅ Fine-tuning data collection
- ✅ Graceful network handling
- ✅ Accessible UI (VoiceOver)

---

**Version:** 1.0  
**Status:** Ready for detailed specifications  
**Next:** Spec 1 (Data Models), Spec 2 (Services), Spec 3 (UI/ViewModels)
