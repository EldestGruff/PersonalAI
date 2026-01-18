# Phase 3A Spec 2: Service Layer & Framework Integration

**Status:** Ready for Code Generation  
**Target:** Claude Sonnet  
**Output:** Service classes, protocol definitions, framework wrappers  
**Complexity:** Very High (10+ services, all framework integrations)  

---

## Overview

This specification defines the **Service Layer** - the business logic and framework integration backbone for Phase 3A. Services orchestrate:
- Local thought management (CRUD, search)
- Context gathering from multiple frameworks
- On-device intelligence (Foundation Models, NLP, classification)
- System integration (EventKit, HealthKit, Location, Contacts)
- Fine-tuning data collection
- Sync queue management
- Background task coordination

Services are *thread-safe actors* called by ViewModels. ViewModels never call Core Data directly—only services.

---

## Requirements Analysis

### What We're Solving

**Challenge 1:** Coordinating multiple frameworks (HealthKit, Location, etc.)  
**Solution:** Service protocol + concrete implementations per framework

**Challenge 2:** Context gathering from 7 sources in parallel without blocking UI  
**Solution:** async/await, Task groups, parallel execution

**Challenge 3:** Running Foundation Models on-device without latency  
**Solution:** Background tasks, prefetching, caching

**Challenge 4:** Fine-tuning without manual labels  
**Solution:** Implicit reward signals from user behavior

**Challenge 5:** Offline sync queue with retry logic  
**Solution:** SyncService with exponential backoff, network monitoring

### Success Criteria

- ✅ Context gathering <300ms (all 7 sources)
- ✅ Classification <200ms (Foundation Models)
- ✅ Search <100ms (100+ thoughts)
- ✅ Never blocks main thread (all async)
- ✅ Permission handling (request gracefully)
- ✅ Error handling (fail soft, recovery)
- ✅ 80%+ test coverage
- ✅ Full offline operation

---

## Approach Options

### Option 1: Monolithic Service (Bad, Unmaintainable) ❌
Single service doing everything. Hard to test, hard to modify.

### Option 2: Microservices (Over-engineered for iOS App) ❌
Too many independent services, difficult coordination.

### Option 3: Layered Service Architecture (Recommended) ✅
- **Domain Services:** ThoughtService, TaskService (business logic)
- **Intelligence Services:** ClassificationService, NLPService (on-device AI)
- **Integration Services:** HealthKitService, LocationService, etc. (framework wrappers)
- **Coordination Services:** ContextService, FineTuningService, SyncService (orchestration)

**Decision:** Option 3. Clear separation of concerns, testable, maintainable.

---

## Service Architecture

### Service Protocol Hierarchy

```swift
// Base protocol all services implement
protocol Service {
    static var shared: Self { get }
    var isAvailable: Bool { get }           // Framework available on device
    var permissions: PermissionStatus { get } // Current permission state
    func requestPermissions() async -> Bool   // Ask for permissions
}

enum PermissionStatus: Equatable {
    case notDetermined
    case restricted
    case denied
    case authorized
}

// Domain services interface with repositories
protocol RepositoryBackedService: Service {
    associatedtype Repository: Actor
    var repository: Repository { get }
}

// Framework integration services wrap frameworks
protocol FrameworkIntegrationService: Service {
    var frameworkName: String { get }
    func checkAvailability() async -> Bool
}
```

### Threading Model

All services are **actors** for thread safety:

```swift
actor ThoughtService: RepositoryBackedService {
    static let shared = ThoughtService()
    
    let repository: ThoughtRepository = .shared
    var isAvailable: Bool { true }  // Always available locally
    var permissions: PermissionStatus { .authorized }
    
    // Isolated actor methods - thread-safe by compiler
    func create(_ input: Thought) async throws -> Thought
    func fetch(_ id: UUID) async throws -> Thought?
}

actor HealthKitService: FrameworkIntegrationService {
    static let shared = HealthKitService()
    
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var permissions: PermissionStatus { _permissions }
    
    private var _permissions: PermissionStatus = .notDetermined
    
    func requestPermissions() async -> Bool
    func getEnergyLevel() async throws -> EnergyLevel
}
```

---

## Service Specifications

### 1. ThoughtService (Domain Logic)

**Responsibility:** CRUD operations for thoughts, business logic validation.

```swift
actor ThoughtService: RepositoryBackedService {
    static let shared = ThoughtService()
    let repository = ThoughtRepository.shared
    
    var isAvailable: Bool { true }
    var permissions: PermissionStatus { .authorized }
    
    // CRUD
    func create(_ input: Thought) async throws -> Thought
    func fetch(_ id: UUID) async throws -> Thought?
    func list(filter: ThoughtFilter) async throws -> [Thought]
    func update(_ thought: Thought) async throws -> Thought
    func delete(_ id: UUID) async throws
    
    // Search
    func search(query: String) async throws -> [Thought]
    func searchByTags(_ tags: [String]) async throws -> [Thought]
    
    // Filtering
    func listRecent(limit: Int) async throws -> [Thought]
    func listArchived() async throws -> [Thought]
    func listCompleted() async throws -> [Thought]
    
    // Bulk operations
    func archive(_ ids: [UUID]) async throws
    func unarchive(_ ids: [UUID]) async throws
    func delete(_ ids: [UUID]) async throws
}
```

**Validation Logic:**
- Content length: 1-5000 chars
- Tags: 0-5, unique, lowercase alphanumeric
- Status: Valid enum case
- Timestamp: Created ≤ Updated

**Error Handling:**
```swift
enum ThoughtServiceError: LocalizedError {
    case validationFailed(String)  // Content too long, etc.
    case notFound(UUID)
    case persistenceFailed(String)
    case concurrencyError
}
```

---

### 2. ContextService (Orchestration)

**Responsibility:** Gather context from all sources in parallel.

**Flow:**
```
User taps "Capture"
    ↓
ContextService.gatherContext()
    ├─ LocationService.getCurrentLocation()    [Async]
    ├─ HealthKitService.getEnergyLevel()       [Async]
    ├─ MotionService.getActivityLevel()        [Async]
    ├─ EventKitService.getAvailability()       [Async]
    ├─ TimeService.getTimeOfDay()              [Sync]
    └─ CalendarService.getCalendarContext()    [Async]
    ↓
All results combined → Context returned (target: <300ms)
```

```swift
actor ContextService: Service {
    static let shared = ContextService()
    
    let locationService = LocationService.shared
    let healthKitService = HealthKitService.shared
    let motionService = MotionService.shared
    let eventKitService = EventKitService.shared
    let calendarService = CalendarService.shared
    
    var isAvailable: Bool { true }
    var permissions: PermissionStatus {
        // Aggregate from all services
        let allServices = [locationService, healthKitService, motionService, eventKitService]
        let allAuthorized = allServices.allSatisfy { $0.permissions == .authorized }
        return allAuthorized ? .authorized : .notDetermined
    }
    
    func gatherContext() async -> Context {
        // Use TaskGroup for parallel execution
        async let location = locationService.getCurrentLocation()
        async let energy = healthKitService.getEnergyLevel()
        async let activity = motionService.getActivityLevel()
        async let availability = eventKitService.getAvailability()
        async let calendar = calendarService.getCalendarContext()
        
        return Context(
            timestamp: Date(),
            location: try await location,
            timeOfDay: TimeOfDay.from(date: Date()),
            energy: try await energy,
            focusState: .scattered,  // Set by fine-tuning later
            calendar: try await availability,
            activity: try await activity,
            weather: nil  // Future: Weather API
        )
    }
    
    func requestAllPermissions() async -> PermissionStatus {
        // Request permissions from all services
        _ = await locationService.requestPermissions()
        _ = await healthKitService.requestPermissions()
        _ = await motionService.requestPermissions()
        _ = await eventKitService.requestPermissions()
        
        return permissions
    }
}
```

**Timeout Strategy:**
If individual service takes >100ms, return default value and continue.

---

### 3. ClassificationService (Foundation Models)

**Responsibility:** Run Foundation Models on-device for classification and tagging.

```swift
actor ClassificationService: FrameworkIntegrationService {
    static let shared = ClassificationService()
    
    let frameworkName = "Foundation Models"
    let nliService = NLPService.shared
    
    var isAvailable: Bool { #available(iOS 18.0, *) }
    var permissions: PermissionStatus { .authorized }  // No permission needed
    
    func requestPermissions() async -> Bool { true }
    
    // Main classification
    func classify(_ content: String) async throws -> Classification {
        let startTime = Date()
        
        // Run Foundation Models inference
        let type = try await classifyType(content)
        let sentiment = try await classifySentiment(content)
        let entities = try await extractEntities(content)
        let tags = try await generateTags(content, entities: entities)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return Classification(
            id: UUID(),
            type: type,
            confidence: await getConfidence(type: type),
            entities: entities,
            suggestedTags: tags,
            sentiment: sentiment,
            language: try await detectLanguage(content),
            processingTime: processingTime,
            model: "foundation-models-ios18",
            createdAt: Date()
        )
    }
    
    private func classifyType(_ content: String) async throws -> ClassificationType {
        // Use Foundation Models
        // Determine: Reminder, Event, Note, Question, Idea
        // Returns enum based on content analysis
    }
    
    private func classifySentiment(_ content: String) async throws -> Sentiment {
        // Sentiment analysis: positive, negative, neutral
    }
    
    private func extractEntities(_ content: String) async throws -> [String] {
        // Named entity recognition: names, dates, topics
        // Use NLPService for NLP operations
        let tagger = try await nliService.tagger()
        return try await nliService.extractEntities(content, tagger: tagger)
    }
    
    private func generateTags(_ content: String, entities: [String]) async throws -> [String] {
        // Generate suggested tags with confidence scores
        // Combine entities with thematic analysis
        let thematicTags = try await classifyThemes(content)
        return (entities + thematicTags).uniqued().prefix(5).map { $0.lowercased() }
    }
    
    private func getConfidence(type: ClassificationType) async -> Double {
        // Return confidence based on type
        // Reminders/Events: typically high (0.85+)
        // Notes: lower (0.6-0.8)
    }
}
```

**Error Handling:**
```swift
enum ClassificationError: LocalizedError {
    case modelUnavailable
    case inferenceTimeout
    case invalidInput
    case processingFailed(String)
}
```

**Performance Targets:**
- Classification inference: <200ms
- Parallel operations for type + sentiment + entities
- Cache results for identical inputs

---

### 4. NLPService (Natural Language Processing)

**Responsibility:** Wrap Natural Language framework for NLP tasks.

```swift
actor NLPService: FrameworkIntegrationService {
    static let shared = NLPService()
    
    let frameworkName = "Natural Language"
    
    var isAvailable: Bool { true }  // Always available
    var permissions: PermissionStatus { .authorized }
    
    func requestPermissions() async -> Bool { true }
    
    // Sentiment analysis
    func analyzeSentiment(_ text: String) async throws -> Sentiment {
        // Use NLTagger for sentiment
        let tagger = NLTagger(tagSchemes: [.sentiment])
        tagger.string = text
        
        let range = text.startIndex..<text.endIndex
        guard let sentiment = tagger.dominantTag(in: range, scheme: .sentiment) else {
            return .neutral
        }
        
        return mapSentiment(sentiment)
    }
    
    // Language detection
    func detectLanguage(_ text: String) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return "en"  // Default to English
        }
        
        return language.rawValue
    }
    
    // Entity extraction
    func extractEntities(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag, tag != .other {
                let entity = String(text[tokenRange])
                entities.append(entity)
            }
            return true
        }
        
        return entities
    }
    
    // Lemmatization (normalize words)
    func lemmatize(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        
        var lemmas: [String] = []
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma) { tag, tokenRange in
            if let tag = tag {
                lemmas.append(tag.rawValue)
            } else {
                lemmas.append(String(text[tokenRange]))
            }
            return true
        }
        
        return lemmas
    }
    
    private func mapSentiment(_ tag: NLTag) -> Sentiment {
        switch tag {
        case .sentimentPositive: return .very_positive
        case .sentimentNegative: return .very_negative
        default: return .neutral
        }
    }
}
```

---

### 5. HealthKitService (Activity & Energy)

**Responsibility:** Read health data without storing (privacy-first).

```swift
actor HealthKitService: FrameworkIntegrationService {
    static let shared = HealthKitService()
    
    let frameworkName = "HealthKit"
    let store = HKHealthStore()
    
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var permissions: PermissionStatus { _permissions }
    private var _permissions: PermissionStatus = .notDetermined
    
    func requestPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            _permissions = .authorized
            return true
        } catch {
            _permissions = .denied
            return false
        }
    }
    
    // Energy level inference
    func getEnergyLevel() async throws -> EnergyLevel {
        let sleepQuality = try await getSleepQuality()
        let activityLevel = try await getActivityLevel()
        let heartRateVariability = try await getHeartRateVariability()
        
        // Simple heuristic: sleep + activity + HRV
        let energyScore = (sleepQuality * 0.5) + (activityLevel * 0.3) + (heartRateVariability * 0.2)
        
        return EnergyLevel.from(score: energyScore)
    }
    
    // Activity for context
    func getActivityLevel() async throws -> ActivityContext {
        let steps = try await getStepCount(today: true)
        let calories = try await getActiveEnergy(today: true)
        let activeMinutes = try await getActiveMinutes(today: true)
        
        return ActivityContext(
            stepCount: Int(steps),
            caloriesBurned: calories,
            activeMinutes: Int(activeMinutes)
        )
    }
    
    private func getStepCount(today: Bool) async throws -> Double {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: today ? createTodayPredicate() : nil,
            options: .cumulativeSum
        ) { _, statistics, _ in
            statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            store.execute(query)
        }
    }
    
    private func getSleepQuality() async throws -> Double {
        // 0.0 - 1.0 based on hours slept last night
        // <6 hours: 0.3, 6-7: 0.7, 7-9: 1.0, >9: 0.8
    }
    
    private func getHeartRateVariability() async throws -> Double {
        // 0.0 - 1.0 based on HRV
        // Higher HRV = better recovery = higher score
    }
    
    private func createTodayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: [.strictStartDate, .strictEndDate]
        )
    }
}

extension EnergyLevel {
    static func from(score: Double) -> EnergyLevel {
        switch score {
        case 0..<0.33: return .low
        case 0.33..<0.66: return .medium
        case 0.66..<0.85: return .high
        default: return .peak
        }
    }
}
```

---

### 6. LocationService (Context)

**Responsibility:** Get current location and geofence status.

```swift
actor LocationService: FrameworkIntegrationService {
    static let shared = LocationService()
    
    let frameworkName = "Core Location"
    let manager = CLLocationManager()
    
    var isAvailable: Bool { CLLocationManager.locationServicesEnabled() }
    var permissions: PermissionStatus { 
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        @unknown default: return .notDetermined
        }
    }
    
    func requestPermissions() async -> Bool {
        manager.requestWhenInUseAuthorization()
        // Returns true immediately (actual permission determined by OS)
        return true
    }
    
    // Get current location
    func getCurrentLocation() async throws -> Location? {
        guard permissions == .authorized else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = LocationDelegate { location in
                continuation.resume(returning: Location(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: "Current"
                ))
            }
            
            manager.delegate = delegate
            manager.startUpdatingLocation()
        }
    }
    
    // Reverse geocode to get location name
    func getLocationName(latitude: Double, longitude: Double) async throws -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first?.name
    }
}

// Helper delegate for location updates
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onLocation: (CLLocation) -> Void
    
    init(onLocation: @escaping (CLLocation) -> Void) {
        self.onLocation = onLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocation(location)
            manager.stopUpdatingLocation()
        }
    }
}
```

---

### 7. EventKitService (Reminders & Calendar)

**Responsibility:** Create system reminders, read calendar availability.

```swift
actor EventKitService: FrameworkIntegrationService {
    static let shared = EventKitService()
    
    let frameworkName = "EventKit"
    let store = EKEventStore()
    
    var isAvailable: Bool { true }
    var permissions: PermissionStatus {
        switch store.authorizationStatus(for: .event) {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .fullAccess, .writeOnly: return .authorized
        @unknown default: return .notDetermined
        }
    }
    
    func requestPermissions() async -> Bool {
        do {
            let granted = try await store.requestWriteOnlyAccessToEvents()
            return granted
        } catch {
            return false
        }
    }
    
    // Create a system reminder
    func createReminder(title: String, description: String, dueDate: Date? = nil) async throws -> String {
        guard permissions == .authorized else {
            throw EventKitError.permissionDenied
        }
        
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = description
        
        if let dueDate = dueDate {
            let alarm = EKAlarm(relativeOffset: -300)  // 5 minutes before
            reminder.addAlarm(alarm)
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            reminder.dueDateComponents = dateComponents
        }
        
        let calendar = store.defaultCalendarForNewReminders()!
        reminder.calendar = calendar
        
        try store.save(reminder, commit: true)
        
        return reminder.eventIdentifier
    }
    
    // Create a calendar event
    func createEvent(title: String, description: String, startDate: Date, endDate: Date) async throws -> String {
        guard permissions == .authorized else {
            throw EventKitError.permissionDenied
        }
        
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = description
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = store.defaultCalendarForNewEvents
        
        try store.save(event, span: .thisEvent, commit: true)
        
        return event.eventIdentifier
    }
    
    // Get calendar availability (free/busy)
    func getAvailability() async throws -> CalendarContext {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        
        let predicate = store.predicateForEvents(
            withStart: now,
            end: tomorrow,
            calendars: store.calendars(for: .event)
        )
        
        let events = store.events(matching: predicate)
        
        // Find next event
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        if let nextEvent = sortedEvents.first {
            let minutes = Int(nextEvent.startDate.timeIntervalSince(now) / 60)
            
            return CalendarContext(
                nextEventMinutes: minutes,
                isFreetime: minutes > 30,
                eventCount: events.count
            )
        }
        
        return CalendarContext(
            nextEventMinutes: nil,
            isFreetime: true,
            eventCount: 0
        )
    }
}

enum EventKitError: LocalizedError {
    case permissionDenied
    case saveFailed
    case calendarNotFound
}
```

---

### 8. ContactsService (Entity Linking)

**Responsibility:** Link person mentions to Contacts.

```swift
actor ContactsService: FrameworkIntegrationService {
    static let shared = ContactsService()
    
    let frameworkName = "Contacts"
    
    var isAvailable: Bool { true }
    var permissions: PermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    func requestPermissions() async -> Bool {
        let store = CNContactStore()
        do {
            try await store.requestAccess(for: .contacts)
            return true
        } catch {
            return false
        }
    }
    
    // Find contact by name
    func findContact(byName: String) async throws -> CNContact? {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        
        let predicate = CNContact.predicateForContacts(matchingName: byName)
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as [CNKeyDescriptor])
            return contacts.first
        } catch {
            return nil
        }
    }
    
    // List all contacts (for entity matching)
    func getAllContacts() async throws -> [CNContact] {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        
        var contacts: [CNContact] = []
        try store.enumerateContacts(with: request) { contact in
            contacts.append(contact)
        }
        
        return contacts
    }
}
```

---

### 9. FineTuningService (Behavioral Learning)

**Responsibility:** Track user interactions, calculate reward signals, build behavior model.

```swift
actor FineTuningService: RepositoryBackedService {
    static let shared = FineTuningService()
    let repository = FineTuningRepository.shared
    
    var isAvailable: Bool { true }
    var permissions: PermissionStatus { .authorized }
    
    // Track thought creation (ground truth)
    func trackThoughtCreated(_ thought: Thought, classification: Classification) async throws {
        var data = FineTuningData(
            id: UUID(),
            thoughtId: thought.id,
            classificationId: classification.id,
            createdReminder: false,
            reminderCompleted: nil,
            createdEvent: false,
            eventCompleted: nil,
            archived: false,
            deleted: false,
            timeToFirstAction: nil,
            timeToCompletion: nil,
            views: 0,
            shares: 0,
            edits: 0,
            userFeedback: nil,
            createdAt: Date(),
            lastUpdatedAt: Date()
        )
        
        try await repository.create(data)
    }
    
    // Track reminder creation (positive signal for classification)
    func trackReminderCreated(_ thoughtId: UUID) async throws {
        var data = try await repository.fetch(thoughtId: thoughtId)
        data?.createdReminder = true
        data?.timeToFirstAction = 0  // Created immediately
        
        if let updated = data {
            try await repository.update(updated)
        }
    }
    
    // Track reminder completion (strong positive signal)
    func trackReminderCompleted(_ thoughtId: UUID) async throws {
        var data = try await repository.fetch(thoughtId: thoughtId)
        data?.reminderCompleted = true
        data?.timeToCompletion = calculateTime(since: data?.createdAt ?? Date())
        
        if let updated = data {
            try await repository.update(updated)
        }
    }
    
    // Calculate reward signal (0.0 - 1.0)
    func calculateReward(_ data: FineTuningData) -> Double {
        var reward = 0.0
        
        if data.createdReminder {
            reward += 0.5  // User agreed with classification
        }
        
        if data.reminderCompleted == true {
            reward += 0.35  // User completed the task
        }
        
        if data.reminderCompleted == false && data.createdReminder {
            reward -= 0.1   // User created but didn't complete
        }
        
        if data.archived || data.deleted {
            reward -= 0.25  // User discarded it
        }
        
        return max(0.0, min(1.0, reward))
    }
    
    // Build user behavior profile
    func getUserBehaviorProfile() async throws -> BehaviorProfile {
        let allData = try await repository.list()
        
        let completionRate = allData.filter { $0.reminderCompleted == true }.count / max(1, allData.filter { $0.createdReminder }.count)
        let archivalRate = Double(allData.filter { $0.archived }.count) / Double(allData.count)
        let avgConfidence = allData.compactMap { try? $0.classification?.confidence }.reduce(0, +) / Double(allData.count)
        
        return BehaviorProfile(
            totalThoughts: allData.count,
            completionRate: completionRate,
            archivalRate: archivalRate,
            avgClassificationConfidence: avgConfidence,
            preferredTimeOfDay: inferPreferredTime(allData),
            preferredLocation: inferPreferredLocation(allData)
        )
    }
    
    private func calculateTime(since date: Date) -> TimeInterval {
        Date().timeIntervalSince(date)
    }
    
    private func inferPreferredTime(_ data: [FineTuningData]) -> TimeOfDay? {
        // Analyze when user creates most thoughts
        return .afternoon  // Placeholder
    }
    
    private func inferPreferredLocation(_ data: [FineTuningData]) -> String? {
        // Analyze location when creating thoughts
        return nil  // Placeholder
    }
}

struct BehaviorProfile: Codable {
    let totalThoughts: Int
    let completionRate: Double
    let archivalRate: Double
    let avgClassificationConfidence: Double
    let preferredTimeOfDay: TimeOfDay?
    let preferredLocation: String?
}
```

---

### 10. SyncService (Offline-First Sync)

**Responsibility:** Queue sync items, process when online, handle retries.

```swift
actor SyncService: RepositoryBackedService {
    static let shared = SyncService()
    let repository = SyncRepository.shared
    let networkMonitor = NetworkMonitor.shared
    
    var isAvailable: Bool { true }
    var permissions: PermissionStatus { .authorized }
    
    // Enqueue item for syncing
    func enqueue(_ entity: SyncEntity, _ entityId: UUID, action: SyncAction, payload: Data? = nil) async throws {
        let item = SyncQueueItem(
            id: UUID(),
            entity: entity,
            entityId: entityId,
            action: action,
            payload: payload,
            retries: 0,
            lastError: nil,
            createdAt: Date(),
            nextRetryAt: Date(),
            backendResponseId: nil
        )
        
        try await repository.enqueue(item)
    }
    
    // Process sync queue
    func processQueue() async throws {
        guard networkMonitor.isConnected else {
            return  // Wait for network
        }
        
        let items = try await repository.dequeue(limit: 10)
        
        for item in items {
            do {
                // Attempt sync (would call backend here)
                // For Phase 3A, backend is mocked
                let responseId = try await mockBackendSync(item)
                try await repository.markProcessed(item.id, responseId: responseId)
            } catch {
                try await repository.markFailed(
                    item.id,
                    error: error.localizedDescription
                )
                
                // Exponential backoff
                let nextRetry = calculateNextRetry(item.retries)
                try await repository.retry(item.id, nextRetryAt: nextRetry)
            }
        }
    }
    
    private func calculateNextRetry(_ retries: Int) -> Date {
        let baseDelay = TimeInterval(pow(2.0, Double(min(retries, 5))))  // 1s, 2s, 4s, 8s, 16s, 32s max
        let jitter = Double.random(in: 0..<0.1 * baseDelay)
        
        return Date(timeIntervalSinceNow: baseDelay + jitter)
    }
    
    private func mockBackendSync(_ item: SyncQueueItem) async throws -> String {
        // Phase 3A: Simulated backend response
        // Phase 4+: Real API calls to Claude, Gemini, etc.
        return UUID().uuidString
    }
}
```

---

### 11. MotionService (Activity)

**Responsibility:** Read step count and motion data.

```swift
actor MotionService: FrameworkIntegrationService {
    static let shared = MotionService()
    
    let frameworkName = "Core Motion"
    let pedometer = CMPedometer()
    
    var isAvailable: Bool { CMPedometer.isPedometerEventTrackingAvailable() }
    var permissions: PermissionStatus { .authorized }  // No permission needed
    
    func requestPermissions() async -> Bool { true }
    
    // Get step count for today
    func getStepCount() async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: Int(data.numberOfSteps))
                } else {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    // Get activity level (inferred from steps)
    func getActivityLevel() async throws -> Double {
        let steps = try await getStepCount()
        
        // Simple heuristic: 0 steps = 0.0, 10000+ = 1.0
        let normalized = Double(steps) / 10000.0
        return min(1.0, normalized)
    }
}
```

---

### 12. SpeechService (Voice Input)

**Responsibility:** Speech-to-text for alternative capture method.

```swift
actor SpeechService: FrameworkIntegrationService {
    static let shared = SpeechService()
    
    let frameworkName = "Speech"
    private var recognizer: SFSpeechRecognizer?
    
    var isAvailable: Bool { SFSpeechRecognizer.authorizationStatus() == .authorized }
    var permissions: PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    func requestPermissions() async -> Bool {
        var granted = false
        
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                granted = (status == .authorized)
                continuation.resume()
            }
        }
        
        return granted
    }
    
    // Transcribe audio (for speech-to-text capture)
    func transcribeAudio(_ audioURL: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    if result.isFinal {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                }
            }
        }
    }
}
```

---

## Background Task Management

### Background Processing

```swift
@MainActor
class BackgroundTaskManager: NSObject, UIApplicationDelegate {
    static let shared = BackgroundTaskManager()
    
    func scheduleBackgroundTasks() {
        // Sync queue processing every 15 minutes
        let syncRequest = BGProcessingTaskRequest(identifier: "com.personalai.sync")
        syncRequest.requiresNetworkConnectivity = true
        syncRequest.requiresExternalPower = false
        
        try? BGTaskScheduler.shared.submit(syncRequest)
        
        // Fine-tuning data aggregation every hour
        let finetuningRequest = BGProcessingTaskRequest(identifier: "com.personalai.finetuning")
        finetuningRequest.requiresNetworkConnectivity = false
        finetuningRequest.requiresExternalPower = false
        
        try? BGTaskScheduler.shared.submit(finetuningRequest)
    }
}
```

---

## Error Handling Strategy

### Cascading Error Recovery

```swift
enum ServiceError: LocalizedError {
    case permissionDenied(String)
    case networkUnavailable
    case frameworkUnavailable(String)
    case timeoutError
    case invalidData
    case syncError(String)
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied(let framework):
            return "Enable \(framework) in Settings → Personal AI"
        case .networkUnavailable:
            return "Enable WiFi or cellular, items will sync when connected"
        case .frameworkUnavailable(let framework):
            return "\(framework) is not available on this device"
        case .timeoutError:
            return "Operation took too long, try again"
        default:
            return nil
        }
    }
}
```

---

## Notes for Sonnet

When generating these services:

1. **All services are actors** for thread safety
2. **All I/O is async/await** - never block
3. **Error handling is graceful** - fail soft, suggest recovery
4. **Permissions are requested** - use appropriate iOS patterns
5. **Framework integration** follows Apple docs exactly
6. **No hardcoded secrets** - use environment vars for Phase 3D
7. **Comprehensive docstrings** on all public methods
8. **Test-friendly** - injectable dependencies where possible
9. **Memory efficient** - no circular references, proper cleanup
10. **Performance targets** respected - context <300ms, classification <200ms

Generate production-ready services with full framework integration.

---

**Version:** 1.0  
**Status:** Ready for code generation  
**Depends On:** Spec 1 (Data Models)  
**Used By:** Spec 3 (ViewModels), Background tasks  
