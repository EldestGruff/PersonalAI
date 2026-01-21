# Testing & Quality Assurance Strategy

**Last Updated:** 2026-01-20

## Overview

This document outlines the testing strategy for PersonalAI, covering unit tests, integration tests, UI tests, beta testing, and quality assurance processes.

---

## Testing Pyramid

```
                  /\
                 /  \
                /    \
               / E2E  \      Manual & Beta Testing
              /--------\
             /          \
            /  UI Tests  \   Automated UI Testing
           /--------------\
          /                \
         / Integration Tests \ Service & API Testing
        /--------------------\
       /                      \
      /      Unit Tests        \ Model, ViewModel, Utilities
     /--------------------------\
```

**Strategy:** Heavy base of unit tests, moderate integration tests, light UI and E2E tests

---

## Unit Testing

### Scope
Test individual components in isolation:
- Models (data validation, computed properties)
- ViewModels (business logic, state management)
- Services (individual methods with mocked dependencies)
- Utilities and helpers

### Coverage Goals
- **Minimum:** 70% code coverage
- **Target:** 80% code coverage
- **Critical paths:** 95%+ coverage (classification, context gathering, data persistence)

### Framework
- XCTest (built-in)
- Quick/Nimble (optional, for BDD-style tests)

### Example Test Cases

```swift
// ThoughtTests.swift
class ThoughtTests: XCTestCase {
    func testThoughtCreationWithValidData() {
        let thought = Thought(
            content: "Test thought",
            classificationType: .note,
            timestamp: Date()
        )
        XCTAssertEqual(thought.content, "Test thought")
        XCTAssertEqual(thought.classificationType, .note)
    }

    func testThoughtValidation() {
        XCTAssertThrowsError(try Thought.validate(content: ""))
        XCTAssertNoThrow(try Thought.validate(content: "Valid"))
    }
}

// ClassificationServiceTests.swift
class ClassificationServiceTests: XCTestCase {
    var service: ClassificationService!
    var mockAPIClient: MockAPIClient!

    override func setUp() {
        mockAPIClient = MockAPIClient()
        service = ClassificationService(apiClient: mockAPIClient)
    }

    func testClassifyThought_ReturnsTask() async throws {
        mockAPIClient.mockResponse = Classification(type: .task, confidence: 0.95)

        let result = await service.classify(content: "Buy groceries")

        XCTAssertEqual(result.type, .task)
        XCTAssertGreaterThan(result.confidence, 0.9)
    }
}
```

---

## Integration Testing

### Scope
Test interaction between components:
- Service layer integration (multiple services working together)
- Data persistence (Core Data stack)
- Context gathering (coordinating multiple data sources)
- API integration (backend communication)

### Key Test Scenarios

1. **Context Gathering Flow**
   - Test ContextService coordinating LocationService, HealthKitService, CalendarService
   - Verify timeout handling
   - Test partial success scenarios (some services fail)

2. **Thought Lifecycle**
   - Create thought → Classify → Gather context → Persist → Sync
   - Verify data integrity through entire pipeline

3. **Permission Handling**
   - Test permission request flows
   - Verify fail-soft behavior when permissions denied
   - Test permission state transitions

4. **Offline/Online Sync**
   - Create thoughts offline
   - Verify queuing
   - Test sync when connectivity restored
   - Verify conflict resolution

### Example

```swift
class ContextIntegrationTests: XCTestCase {
    var contextService: ContextService!
    var locationService: LocationService!
    var healthKitService: HealthKitService!

    override func setUp() {
        locationService = LocationService()
        healthKitService = HealthKitService()
        contextService = ContextService(
            locationService: locationService,
            healthKitService: healthKitService,
            calendarService: CalendarService()
        )
    }

    func testGatherContextIntegration() async throws {
        let context = await contextService.gatherContext()

        // Verify all context components populated (or gracefully nil)
        XCTAssertNotNil(context.timestamp)
        // Location may be nil if permissions not granted
        // Energy may be nil if HealthKit permissions not granted

        // Verify context gathering completed within target time
        // (This would need actual timing instrumentation)
    }
}
```

---

## UI Testing

### Scope
Automated UI tests for critical user flows:
- Thought capture (voice and text)
- Thought browsing and filtering
- Thought detail view and editing
- Permission request flows
- Settings changes

### Framework
- XCUITest (built-in)

### Key Test Scenarios

1. **Happy Path: Capture Thought**
   - Launch app
   - Tap capture button
   - Enter text
   - Tap save
   - Verify thought appears in list

2. **Voice Capture**
   - Tap microphone button
   - Simulate voice input (recorded audio)
   - Verify transcription
   - Verify classification

3. **Edit Thought**
   - Open thought detail
   - Edit content
   - Save changes
   - Verify updates persist

4. **Delete Thought**
   - Swipe to delete
   - Confirm deletion
   - Verify thought removed

### Limitations
- Voice input difficult to test automatically (use mocks)
- HealthKit/Location permissions require manual testing on device
- Some tests require physical device (not simulator)

---

## Manual Testing

### Test Matrix

| Feature | iOS 18 | iOS 19 | iPhone SE | iPhone Pro | iPad |
|---------|--------|--------|-----------|------------|------|
| Thought capture (text) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Voice input | ✓ | ✓ | ✓ | ✓ | ✓ |
| Classification | ✓ | ✓ | ✓ | ✓ | ✓ |
| Context gathering | ✓ | ✓ | ✓ | ✓ | ~ |
| HealthKit integration | ✓ | ✓ | ✓ | ✓ | N/A |
| Location services | ✓ | ✓ | ✓ | ✓ | ~ |
| Calendar/Reminders | ✓ | ✓ | ✓ | ✓ | ✓ |

**Legend:** ✓ = Fully supported, ~ = Partial support, N/A = Not applicable

### Testing Checklist (Per Release)

**Functionality**
- [ ] Thought capture (text input)
- [ ] Voice recording and transcription
- [ ] AI classification accuracy
- [ ] Sentiment analysis
- [ ] Context gathering (all sources)
- [ ] Task/reminder/event creation
- [ ] Thought editing
- [ ] Thought deletion (with confirmation)
- [ ] Tag management
- [ ] User feedback submission
- [ ] Settings persistence

**Permissions**
- [ ] Location permission request
- [ ] HealthKit permission request
- [ ] Calendar/Reminders permission request
- [ ] Microphone permission request
- [ ] Fail-soft behavior when permissions denied

**Performance**
- [ ] App launch time (<2s cold start)
- [ ] Context gathering time (<300ms when cached)
- [ ] Voice transcription responsiveness
- [ ] Smooth scrolling in thought list
- [ ] No UI freezing during AI classification

**Edge Cases**
- [ ] Offline mode (airplane mode)
- [ ] Low battery (background tasks disabled)
- [ ] Low storage
- [ ] Bluetooth off (Apple Watch integration future)
- [ ] Poor network connectivity

**Accessibility**
- [ ] VoiceOver support
- [ ] Dynamic type (font scaling)
- [ ] Contrast ratio compliance
- [ ] Keyboard navigation

---

## Beta Testing Program

### Goals
- Validate core value proposition
- Identify bugs and edge cases
- Gather feature feedback
- Test on diverse devices and iOS versions

### Beta Phases

#### Phase 1: Internal Alpha (5-10 testers)
- **Duration:** 2 weeks
- **Focus:** Core functionality, critical bugs
- **Testers:** Development team, close friends/family
- **Feedback:** Direct Slack/Discord channel

#### Phase 2: Closed Beta (50-100 testers)
- **Duration:** 4-6 weeks
- **Focus:** Feature validation, UX feedback, performance
- **Testers:** Recruited from mailing list, Twitter, ProductHunt
- **Feedback:** TestFlight feedback, in-app feedback form, surveys

#### Phase 3: Open Beta (500-1000 testers)
- **Duration:** 2-4 weeks before launch
- **Focus:** Scale testing, final bug fixes
- **Testers:** Public TestFlight link
- **Feedback:** In-app feedback, analytics

### Beta Tester Recruitment
- Landing page with signup form
- Twitter/social media outreach
- ProductHunt "Coming Soon" page
- Reddit communities (r/productivity, r/PKM)
- Indie Hackers community

### Feedback Collection
- **In-app feedback button:** Quick bug reports and suggestions
- **Weekly surveys:** Structured questions about features
- **User interviews:** 30-min calls with engaged testers (5-10 per phase)
- **Analytics:** Track feature usage, drop-off points, crashes

---

## Regression Testing

### Strategy
- Run full test suite on every commit (CI/CD)
- Manual regression testing before each release
- Automated UI tests for critical paths

### Regression Test Suite
- Core user flows (capture, browse, edit, delete)
- Permission handling
- Data persistence
- Context gathering
- Classification accuracy (benchmark dataset)

---

## Performance Testing

### Metrics to Track
1. **App Launch Time**
   - Cold start: <2 seconds
   - Warm start: <1 second

2. **Context Gathering**
   - Initial gather (permissions granted): <500ms
   - Cached gather: <300ms
   - Partial success (some services unavailable): <300ms

3. **AI Classification**
   - Local model inference: <200ms
   - Network API call: <1000ms

4. **Memory Usage**
   - Idle: <50MB
   - Active use: <100MB
   - Thought list with 1000 items: <150MB

5. **Battery Impact**
   - Background activity: Minimal
   - Location tracking: Low (significant location changes only)

### Tools
- Xcode Instruments (Time Profiler, Allocations, Energy Log)
- MetricKit for production monitoring
- Custom performance logging

---

## Continuous Integration (CI)

### Pipeline (GitHub Actions or similar)

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme PersonalAI \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
            -enableCodeCoverage YES
      - name: Upload coverage
        run: bash <(curl -s https://codecov.io/bash)
```

### Build Checks
- ✓ All unit tests pass
- ✓ All integration tests pass
- ✓ Code coverage ≥70%
- ✓ No SwiftLint warnings (if linting enabled)
- ✓ No compiler warnings

---

## Release Quality Gates

Before each release, verify:
- [ ] All tests passing (unit, integration, UI)
- [ ] Manual testing checklist complete
- [ ] Beta tester feedback addressed
- [ ] Performance metrics within targets
- [ ] No critical or high-priority bugs
- [ ] Crash-free rate >99% in beta
- [ ] App Store screenshots and metadata updated

---

## Test Data Management

### Fixtures
- Create realistic test data sets
- Use factories/builders for test objects
- Seed database with varied scenarios

### Privacy
- Never use real user data in tests
- Anonymize any production data used for debugging

---

## Next Steps

### Immediate (Phase 3A)
- [ ] Write unit tests for core models (Thought, Classification, Context)
- [ ] Write unit tests for ViewModels
- [ ] Set up CI pipeline (GitHub Actions)
- [ ] Achieve 70% code coverage baseline

### Short-term (Phase 4)
- [ ] Add integration tests for context gathering
- [ ] Add UI tests for critical flows
- [ ] Set up TestFlight for alpha testing
- [ ] Create beta tester recruitment page

### Long-term (Phase 5+)
- [ ] Launch closed beta program
- [ ] Set up production monitoring (Sentry, analytics)
- [ ] Implement A/B testing framework
- [ ] Establish automated regression suite
