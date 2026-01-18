# Claude Sonnet Prompt: Phase 3A Spec 1 - Data Models & Persistence

## Context

You are generating Phase 3A Spec 1 for a native iOS app (Personal AI Assistant). This is the **foundation specification** - all other phases depend on these models being correct.

Your job: Generate production-ready Swift data models, Core Data persistence layer, repositories, and comprehensive tests.

---

## Critical Design Decisions (Non-Negotiable)

### 1. Dual Model Pattern (Apple's Modern Best Practice)

**DO NOT** use NSManagedObject directly as domain models.

**Pattern:**
- **Swift struct** = domain model (immutable, Codable)
- **NSManagedObject subclass** = persistence model (Core Data)
- **Conversion extensions** = bidirectional conversion (struct ↔ NSManagedObject)
- **Repository** = hides persistence details behind async/await interface

**Example:**
```swift
// Domain Model (Swift struct)
struct Thought: Identifiable, Codable {
    let id: UUID
    let content: String
    let relatedThoughtIds: [UUID]  // IDs only
    // ... other fields
}

// Persistence Model (NSManagedObject)
@objc(ThoughtEntity)
final class ThoughtEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var content: String
    @NSManaged var relatedThoughts: NSSet  // Full objects
    // ... other fields
}

// Conversion Extension
extension Thought {
    // Swift struct → NSManagedObject
    func toEntity(in context: NSManagedObjectContext) throws -> ThoughtEntity {
        let entity = ThoughtEntity(context: context)
        entity.id = self.id
        entity.content = self.content
        // ... set other fields
        
        // Handle many-to-many relationship
        let relatedEntities = try context.fetch(
            NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        ).filter { self.relatedThoughtIds.contains($0.id) }
        entity.relatedThoughts = NSSet(array: relatedEntities)
        
        return entity
    }
    
    // NSManagedObject → Swift struct
    static func from(_ entity: ThoughtEntity) -> Thought {
        let relatedIds = (entity.relatedThoughts as? Set<ThoughtEntity>)?
            .map { $0.id }
            .sorted() ?? []
        
        return Thought(
            id: entity.id,
            content: entity.content,
            relatedThoughtIds: relatedIds,
            // ... other fields
        )
    }
}

// Repository (Hides Core Data)
actor ThoughtRepository {
    func create(_ thought: Thought) async throws -> Thought {
        let entity = try thought.toEntity(in: container.viewContext)
        try container.viewContext.save()
        return Thought.from(entity)
    }
}
```

### 2. Many-to-Many Relationships (Proper, Queryable)

**DO NOT** store related IDs as JSON.

**Pattern:**
- In Core Data: `relatedThoughts: NSSet<ThoughtEntity>` (many-to-many)
- In Swift struct: `relatedThoughtIds: [UUID]` (for Codable)
- In repository: Handle bidirectional linking

**Core Data Schema:**
```
ThoughtEntity:
  - All fields
  - relatedThoughts: NSSet (relationship to ThoughtEntity, many-to-many, bidirectional)

// Bidirectional means:
// If A.relatedThoughts contains B, then B.relatedThoughts contains A automatically
```

**Repository Methods (You'll Generate These):**
```swift
actor ThoughtRepository {
    func addRelatedThought(_ relatedId: UUID, toThought thoughtId: UUID) async throws
    func removeRelatedThought(_ relatedId: UUID, fromThought thoughtId: UUID) async throws
    func getRelatedThoughts(for thoughtId: UUID) async throws -> [Thought]
}
```

### 3. Async/Await Throughout (No Callbacks)

All I/O operations use async/await:
```swift
actor ThoughtRepository {
    func create(_ thought: Thought) async throws -> Thought
    func fetch(_ id: UUID) async throws -> Thought?
    func list(filter: ThoughtFilter) async throws -> [Thought]
    func update(_ thought: Thought) async throws
    func delete(_ id: UUID) async throws
    func search(_ query: String) async throws -> [Thought]
}
```

### 4. Thread Safety via Actors

Repositories are actors (thread-safe, can await):
```swift
actor ThoughtRepository {
    // Automatically actor-isolated
    // Can be called from any thread
    // Internal state is thread-safe
}
```

---

## Complete Specification to Follow

Here is the complete Phase 3A Spec 1 document you must follow exactly:

[INSERT ENTIRE CONTENT OF Phase3A_Spec1_DataModels.md]

---

## Important Modifications to Spec

Based on design review, apply these changes to the spec:

### Modification 1: Remove isDraft
The spec mentions `isDraft` as a transient property. **DO NOT GENERATE IT.**
- Phase 3A assumes auto-save to Core Data
- isDraft complexity is not needed yet
- Remove from Thought model entirely

### Modification 2: Many-to-Many Implementation
The spec says `relatedThoughtIds: [UUID]`. Implement as:
- **Swift struct:** `relatedThoughtIds: [UUID]` (for Codable/sync)
- **Core Data:** `relatedThoughts: NSSet` (many-to-many relationship)
- **Conversion:** Extract IDs from entity when converting ThoughtEntity → Thought
- **Repository:** Provide methods to add/remove related thoughts with proper bidirectional linking

### Modification 3: Context Struct Only
Generate **only the Context struct definition**, not the gathering logic:
```swift
struct Context: Codable {
    let timestamp: Date
    let location: Location?
    let timeOfDay: TimeOfDay
    let energy: EnergyLevel
    let focusState: FocusState
    let calendar: CalendarContext?
    let activity: ActivityContext?
    let weather: WeatherContext?
}

// Enums:
enum TimeOfDay: String, Codable { ... }
enum EnergyLevel: String, Codable { ... }
enum FocusState: String, Codable { ... }
// ... etc
```

**Do NOT generate:**
- Context gathering logic (that's Spec 2 - ContextService)
- Initialization helpers for Context

Context is just a data structure here.

---

## What To Generate

### Directory Structure

```
Models/
├─ Thought.swift           # Thought struct + validation
├─ Context.swift           # Context struct + TimeOfDay, EnergyLevel, etc enums
├─ Classification.swift    # Classification struct + ClassificationType, Sentiment
├─ FineTuningData.swift    # FineTuningData struct + UserFeedback
├─ Task.swift              # Task struct + Priority, TaskStatus
├─ SyncQueue.swift         # SyncQueueItem struct + SyncEntity, SyncAction
├─ Enums.swift             # Shared enums
├─ ModelError.swift        # Error types (ValidationError, ConversionError, etc)
└─ Conversions/
   ├─ Thought+CoreData.swift      # Thought ↔ ThoughtEntity conversion
   ├─ Task+CoreData.swift         # Task ↔ TaskEntity conversion
   ├─ Classification+CoreData.swift
   ├─ FineTuningData+CoreData.swift
   └─ SyncQueue+CoreData.swift

Persistence/
├─ CoreDataStack/
│  ├─ PersistenceController.swift   # Core Data stack setup
│  └─ PersonalAI.xcdatamodeld/
│     └─ PersonalAI.xcdatamodel/
│        └─ contents                # Core Data schema (XML)
├─ Repositories/
│  ├─ ThoughtRepository.swift       # Thought CRUD + relationships
│  ├─ TaskRepository.swift          # Task CRUD
│  ├─ ClassificationRepository.swift
│  ├─ FineTuningRepository.swift
│  └─ SyncRepository.swift          # Sync queue management
└─ Filters/
   └─ ThoughtFilter.swift           # Filter struct for list queries

Tests/
├─ Unit/
│  ├─ ThoughtModelTests.swift       # Thought struct validation
│  ├─ ClassificationModelTests.swift
│  ├─ TaskModelTests.swift
│  ├─ ContextModelTests.swift
│  ├─ FineTuningDataModelTests.swift
│  ├─ ValidationTests.swift         # Comprehensive validation tests
│  ├─ CodableTests.swift            # Serialization/deserialization
│  └─ ConversionTests.swift         # Swift struct ↔ Core Data conversion
└─ Integration/
   ├─ CoreDataStackTests.swift      # Core Data initialization
   ├─ ThoughtRepositoryTests.swift  # CRUD operations
   ├─ TaskRepositoryTests.swift
   ├─ ManyToManyRelationshipTests.swift  # Many-to-many linking
   ├─ SyncQueueRepositoryTests.swift
   └─ PersistenceTests.swift        # Full integration
```

---

## Code Generation Standards

### 1. Docstrings (Comprehensive)

**Every type, property, method must have docstrings:**

```swift
/// A thought captured by the user.
///
/// Thoughts are the atomic unit of the Personal AI Assistant. They capture
/// a single idea or observation at a specific moment. Each thought is enriched
/// with context (time, location, energy) and classified by type (reminder,
/// event, note, question, idea).
///
/// Thoughts are stored locally in Core Data and synced to the backend when
/// network is available.
///
/// - Important: Thoughts are immutable (value type). Modifications create new instances.
struct Thought: Identifiable, Codable {
    /// Unique identifier (UUID v4)
    let id: UUID
    
    /// Content of the thought (1-5000 characters)
    let content: String
    
    /// Example:
    /// ```swift
    /// let thought = Thought(
    ///     id: UUID(),
    ///     userId: UUID(),
    ///     content: "Should optimize email filter",
    ///     // ... other fields
    /// )
    /// ```
}
```

### 2. Validation Methods

Every model must have a `validate()` method:

```swift
extension Thought {
    /// Validates the thought against all business rules.
    ///
    /// - Throws: `ValidationError` if any field is invalid
    /// - Returns: Void (throws on error)
    func validate() throws {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyContent
        }
        guard content.count <= 5000 else {
            throw ValidationError.contentTooLong(content.count)
        }
        guard tags.count <= 5 else {
            throw ValidationError.tooManyTags(tags.count)
        }
        // ... validate other fields
    }
}

enum ValidationError: LocalizedError {
    case emptyContent
    case contentTooLong(Int)
    case tooManyTags(Int)
    case invalidTimestamp
    // ... etc
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Thought content cannot be empty"
        case .contentTooLong(let length):
            return "Content is too long (\(length) chars, max 5000)"
        case .tooManyTags(let count):
            return "Too many tags (\(count), max 5)"
        // ... etc
        }
    }
}
```

### 3. Codable Implementation

All models must be Codable (for backend sync):

```swift
extension Thought: Codable {
    enum CodingKeys: String, CodingKey {
        case id, userId, content, tags, status
        case context, createdAt, updatedAt
        case classification, relatedThoughtIds, taskId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(content, forKey: .content)
        // ... encode all fields
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.content = try container.decode(String.self, forKey: .content)
        // ... decode all fields
    }
}
```

### 4. Core Data Models (NSManagedObject)

Each entity must be properly defined:

```swift
@objc(ThoughtEntity)
final class ThoughtEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged var id: UUID
    
    /// User who owns this thought
    @NSManaged var userId: UUID
    
    /// Thought content
    @NSManaged var content: String
    
    /// Many-to-many relationship to related thoughts
    @NSManaged var relatedThoughts: NSSet
    
    /// One-to-one relationship to classification
    @NSManaged var classification: ClassificationEntity?
    
    /// One-to-many relationship to fine-tuning data
    @NSManaged var fineTuningDataPoints: NSSet
    
    /// ... other properties
}

extension ThoughtEntity {
    @NSManaged func addToRelatedThoughts(_ value: ThoughtEntity)
    @NSManaged func removeFromRelatedThoughts(_ value: ThoughtEntity)
    @NSManaged func addRelatedThoughts(_ values: NSSet)
    @NSManaged func removeRelatedThoughts(_ values: NSSet)
}
```

### 5. Repositories (Thread-Safe Actors)

```swift
actor ThoughtRepository {
    static let shared = ThoughtRepository()
    
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }
    
    /// Creates a new thought and persists to Core Data.
    ///
    /// - Parameter thought: The thought to create
    /// - Returns: The saved thought (may have updated timestamps)
    /// - Throws: `PersistenceError` if save fails
    func create(_ thought: Thought) async throws -> Thought {
        try thought.validate()
        
        let entity = try thought.toEntity(in: container.viewContext)
        try container.viewContext.save()
        
        return Thought.from(entity)
    }
    
    /// Fetches a single thought by ID.
    ///
    /// - Parameter id: UUID of the thought
    /// - Returns: The thought if found, nil if not found
    /// - Throws: `PersistenceError` if fetch fails
    func fetch(_ id: UUID) async throws -> Thought? {
        let request = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let entities = try container.viewContext.fetch(request)
        return entities.first.map { Thought.from($0) }
    }
    
    /// Lists thoughts with optional filtering.
    ///
    /// - Parameter filter: Optional ThoughtFilter
    /// - Returns: Array of thoughts
    /// - Throws: `PersistenceError` if fetch fails
    func list(filter: ThoughtFilter = .none) async throws -> [Thought] {
        let request = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        
        // Apply filters
        var predicates: [NSPredicate] = []
        if let statusFilter = filter.status {
            predicates.append(NSPredicate(format: "status == %@", statusFilter.rawValue))
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Sort by recent
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ThoughtEntity.createdAt, ascending: false)]
        
        let entities = try container.viewContext.fetch(request)
        return entities.map { Thought.from($0) }
    }
    
    /// Adds a related thought (bidirectional).
    ///
    /// - Parameters:
    ///   - relatedId: UUID of the related thought
    ///   - thoughtId: UUID of the thought to add the relationship to
    /// - Throws: `PersistenceError` if operation fails
    func addRelatedThought(_ relatedId: UUID, toThought thoughtId: UUID) async throws {
        let request = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        request.predicate = NSPredicate(format: "id IN %@", [thoughtId, relatedId])
        
        let entities = try container.viewContext.fetch(request)
        guard let thought = entities.first(where: { $0.id == thoughtId }),
              let related = entities.first(where: { $0.id == relatedId }) else {
            throw PersistenceError.notFound(thoughtId)
        }
        
        // Add bidirectionally
        thought.addToRelatedThoughts(related)
        related.addToRelatedThoughts(thought)
        
        try container.viewContext.save()
    }
    
    // ... more methods (update, delete, search, etc)
}

enum PersistenceError: LocalizedError {
    case invalidModel(String)
    case notFound(UUID)
    case corruptedData
    case saveFailed(Error)
    case concurrencyViolation
    
    var errorDescription: String? {
        switch self {
        case .invalidModel(let msg):
            return "Invalid model: \(msg)"
        case .notFound(let id):
            return "Entity with ID \(id) not found"
        case .corruptedData:
            return "Corrupted data detected"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .concurrencyViolation:
            return "Concurrent access detected"
        }
    }
}
```

### 6. Core Data Schema File

Generate a proper `PersonalAI.xcdatamodeld` file with:

**ThoughtEntity:**
- Attributes: id (UUID), userId (UUID), content (String), tags (String/JSON), status (String), createdAt (Date), updatedAt (Date), isDraft (removed!)
- Relationships: relatedThoughts (to ThoughtEntity, many-to-many, bidirectional!), classification (to ClassificationEntity, one-to-one), fineTuningData (to FineTuningDataEntity, one-to-many)
- Indexes: userId + createdAt, userId + status, id

**ClassificationEntity:**
- Attributes: id (UUID), type (String), confidence (Double), entities (String/JSON), suggestedTags (String/JSON), sentiment (String), language (String), processingTime (Double), model (String), createdAt (Date)
- Relationships: thought (to ThoughtEntity, one-to-one inverse)

**TaskEntity:**
- Attributes: id (UUID), sourceThoughtId (UUID), title (String), description (String), priority (String), status (String), dueDate (Date), estimatedEffortMinutes (Integer), createdAt (Date), updatedAt (Date), completedAt (Date), reminderId (String), eventId (String)
- Relationships: thought (to ThoughtEntity, one-to-one inverse)

**FineTuningDataEntity:**
- Attributes: id (UUID), thoughtId (UUID), classificationId (UUID), createdReminder (Bool), reminderCompleted (Bool), createdEvent (Bool), eventCompleted (Bool), archived (Bool), deleted (Bool), timeToFirstAction (Double), timeToCompletion (Double), views (Integer), shares (Integer), edits (Integer), userFeedback (String/JSON), createdAt (Date), lastUpdatedAt (Date)
- Relationships: thought (to ThoughtEntity, many-to-one inverse), classification (to ClassificationEntity, many-to-one inverse)

**SyncQueueEntity:**
- Attributes: id (UUID), entity (String), entityId (UUID), action (String), payload (Binary), retries (Integer), lastError (String), createdAt (Date), nextRetryAt (Date), backendResponseId (String)
- No relationships

### 7. Tests (Comprehensive)

Each test file should follow this pattern:

```swift
import XCTest
@testable import PersonalAI

final class ThoughtModelTests: XCTestCase {
    
    // MARK: - Happy Path
    
    func testValidThoughtCreation() throws {
        let thought = Thought(
            id: UUID(),
            userId: UUID(),
            content: "Valid thought content",
            tags: ["tag1"],
            status: .active,
            context: Context(
                timestamp: Date(),
                location: nil,
                timeOfDay: .afternoon,
                energy: .high,
                focusState: .deep_work,
                calendar: nil,
                activity: nil,
                weather: nil
            ),
            createdAt: Date(),
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )
        
        XCTAssertNoThrow(try thought.validate())
    }
    
    // MARK: - Validation
    
    func testEmptyContentInvalid() throws {
        var thought = createValidThought()
        thought.content = ""
        
        XCTAssertThrowsError(try thought.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyContent)
        }
    }
    
    func testContentTooLongInvalid() throws {
        var thought = createValidThought()
        thought.content = String(repeating: "a", count: 5001)
        
        XCTAssertThrowsError(try thought.validate()) { error in
            if case .contentTooLong(let length) = error as? ValidationError {
                XCTAssertEqual(length, 5001)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testTooManyTagsInvalid() throws {
        var thought = createValidThought()
        thought.tags = ["t1", "t2", "t3", "t4", "t5", "t6"]
        
        XCTAssertThrowsError(try thought.validate()) { error in
            if case .tooManyTags(let count) = error as? ValidationError {
                XCTAssertEqual(count, 6)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - Helpers
    
    func createValidThought() -> Thought {
        Thought(
            id: UUID(),
            userId: UUID(),
            content: "Valid thought",
            tags: ["tag"],
            status: .active,
            context: Context(...),
            createdAt: Date(),
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )
    }
}

final class ThoughtRepositoryTests: XCTestCase {
    
    var repository: ThoughtRepository!
    var container: NSPersistentContainer!
    
    override func setUpWithError() throws {
        // Create in-memory Core Data store for testing
        container = NSPersistentContainer(name: "PersonalAI")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        try container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        
        repository = ThoughtRepository(container: container)
    }
    
    func testCreateAndFetch() async throws {
        let thought = createValidThought()
        let saved = try await repository.create(thought)
        
        let fetched = try await repository.fetch(saved.id)
        XCTAssertEqual(fetched, saved)
    }
    
    func testAddRelatedThought() async throws {
        let thought1 = try await repository.create(createValidThought())
        let thought2 = try await repository.create(createValidThought())
        
        try await repository.addRelatedThought(thought2.id, toThought: thought1.id)
        
        // Verify bidirectional
        let updated1 = try await repository.fetch(thought1.id)!
        let updated2 = try await repository.fetch(thought2.id)!
        
        XCTAssertTrue(updated1.relatedThoughtIds.contains(thought2.id))
        XCTAssertTrue(updated2.relatedThoughtIds.contains(thought1.id))
    }
}
```

---

## Critical Requirements (Code Quality)

- ✅ Swift 6.0+, iOS 18.0+ target
- ✅ All public APIs have comprehensive docstrings
- ✅ Type-safe (no Any, String-based types, or force unwraps except in tests)
- ✅ Thread-safe (actors for repositories, proper Core Data access)
- ✅ No copy-paste code (extract patterns to protocols/extensions)
- ✅ Error handling explicit (LocalizedError protocol, clear error messages)
- ✅ Tests comprehensive (80%+ coverage)
- ✅ No TODO comments or stubs
- ✅ No sensitive data in logs
- ✅ Memory efficient (no retain cycles, proper cleanup)

---

## What NOT to Generate

❌ ViewModel wrappers (those are Spec 3 - UI layer)
❌ Context gathering logic (that's Spec 2 - ContextService)
❌ SwiftUI views
❌ isDraft property
❌ JSON storage for relationships (use Core Data relationships)
❌ Comments that just repeat code ("increment counter")
❌ Force unwraps outside of tests
❌ Placeholder TODOs

---

## File Output Format

When you generate code, format each file like this:

```
## FILE: Models/Thought.swift

(complete file content here)

---

## FILE: Persistence/Repositories/ThoughtRepository.swift

(complete file content here)

---

## FILE: Tests/Unit/ThoughtModelTests.swift

(complete file content here)
```

---

## Success Criteria

You'll know you've succeeded when:

- ✅ All files compile with zero warnings
- ✅ All tests pass (run: `xcodebuild test -scheme PersonalAI`)
- ✅ 80%+ code coverage
- ✅ No force unwraps (except in tests)
- ✅ All public APIs documented
- ✅ Core Data schema properly defined with relationships
- ✅ Many-to-many relationships are bidirectional and queryable
- ✅ Conversion between Swift struct and NSManagedObject works both ways
- ✅ Repository methods use async/await throughout
- ✅ Validation catches all edge cases
- ✅ Codable implementation handles all fields

---

## Questions?

If any part of this is unclear, **ask for clarification** rather than making assumptions.

This is the foundation. Getting it right prevents rework in Specs 2 and 3.

Generate production-ready code.

---

**END OF PROMPT**
