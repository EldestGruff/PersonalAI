# Phase 3A Spec 1: Data Models & Persistence

**Status:** Ready for Code Generation  
**Target:** Claude Sonnet  
**Output:** Swift data models, Core Data models, Observation types, Repositories  
**Complexity:** High (multiple model variants, migrations, relationships)  

---

## Overview

This specification defines all data models for Phase 3A of the Personal AI Assistant iOS app. Models cover:
- **Domain Models:** Swift structs/classes for business logic
- **Core Data Models:** NSManagedObject subclasses
- **Observation Types:** @Observable wrappers for reactive UI
- **Transfer Objects:** Request/response for backend sync

Models must be bidirectional (Swift ↔ Core Data ↔ Backend).

---

## Requirements Analysis

### What We're Solving

**Challenge 1:** Local-first persistence without network  
**Solution:** Core Data as source of truth, models represent local state

**Challenge 2:** Reactive UI updates when data changes  
**Solution:** @Observable wrappers, dependency injection

**Challenge 3:** Rich context and classification data  
**Solution:** Nested structures, JSON storage in Core Data

**Challenge 4:** Fine-tuning data for behavioral learning  
**Solution:** Dedicated FineTuningData model, interaction tracking

**Challenge 5:** Multiple model representations (UI, persistence, backend)  
**Solution:** Clear separation: Domain → CoreData → Transfer

### Edge Cases

- Corrupted Core Data (graceful recovery)
- Model version migrations (add/remove fields)
- Concurrent access to Core Data (use actors)
- Large attachment metadata (efficient storage)
- Offline thought capture + later sync
- Deleted thoughts that user later wants to restore
- Circular relationships (thought → classification → thought)

### Success Criteria

- ✅ All models have comprehensive docstrings
- ✅ Observation wrappers enable reactive UI binding
- ✅ Core Data models properly map to Swift types
- ✅ Migrations work seamlessly
- ✅ No retain cycles (careful with closures)
- ✅ Models are Codable for backend sync
- ✅ Tests cover all model validation

---

## Approach Options

### Option 1: Separate Models Everywhere (Complex, Flexible) ❌
- Domain Model
- Core Data Model  
- Observation Wrapper
- Transfer Model (Backend)

**Pros:** Clean separation  
**Cons:** 4x the code, hard to keep in sync

### Option 2: Single Model with Multiple Representations (Recommended) ✅
- Single domain model (Swift struct)
- Core Data extension for storage
- @Observable wrapper for reactive binding
- Codable for backend

**Pros:** DRY, maintainable, clear responsibility  
**Cons:** Slight complexity in model design

**Decision:** Option 2. Use Swift structs + Core Data extensions + @Observable.

---

## Data Models

### 1. Thought (Core Domain Model)

```swift
struct Thought: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let content: String
    let tags: [String]
    let status: ThoughtStatus
    let context: Context
    let createdAt: Date
    let updatedAt: Date
    let classification: Classification?
    let relatedThoughtIds: [UUID]
    let taskId: UUID?
    
    // Transient (not persisted)
    var isDraft: Bool = false
}

enum ThoughtStatus: String, Codable {
    case active
    case archived
    case completed
}
```

**Field Details:**

| Field | Type | Constraints | Purpose |
|-------|------|-----------|---------|
| `id` | UUID | Primary key | Unique identifier |
| `userId` | UUID | Foreign key | Owner (single user in Phase 3A) |
| `content` | String | 1-5000 chars, required | The thought text |
| `tags` | [String] | Max 5, max 50 chars each | Categories, searchable |
| `status` | Enum | active, archived, completed | Lifecycle |
| `context` | Context | Nested structure | When/where thought captured |
| `createdAt` | Date | UTC, immutable | Creation timestamp |
| `updatedAt` | Date | UTC, auto-update | Last modification |
| `classification` | Classification? | Optional, 1-to-1 | ML classification results |
| `relatedThoughtIds` | [UUID] | Array of IDs | Links to similar thoughts |
| `taskId` | UUID? | Optional FK | If thought became task |
| `isDraft` | Bool | Transient | Not in database |

**Validation Rules:**
- `content`: Non-empty, trimmed, 1-5000 chars
- `tags`: Unique, lowercase alphanumeric + hyphens
- `status`: Must be one of enum cases
- `context`: Required, must have at least time

**Example:**

```swift
let thought = Thought(
    id: UUID(),
    userId: UUID(),
    content: "Should optimize email spam filter",
    tags: ["email", "improvement"],
    status: .active,
    context: Context(
        time: Date(),
        location: Location(
            latitude: 40.7128,
            longitude: -74.0060,
            name: "New York"
        ),
        energy: .high,
        focus: .deep_work
    ),
    createdAt: Date(),
    updatedAt: Date(),
    classification: Classification(
        type: .reminder,
        confidence: 0.95,
        entities: ["email", "filter"]
    ),
    relatedThoughtIds: [UUID(), UUID()],
    taskId: nil
)
```

---

### 2. Context (Situational Information)

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

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let name: String?
    let geofenceId: String?
}

enum TimeOfDay: String, Codable {
    case early_morning   // 5am-9am
    case morning         // 9am-12pm
    case afternoon       // 12pm-5pm
    case evening         // 5pm-9pm
    case night           // 9pm-5am
    
    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<9: return .early_morning
        case 9..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

enum EnergyLevel: String, Codable {
    case low
    case medium
    case high
    case peak
}

enum FocusState: String, Codable {
    case deep_work
    case interrupted
    case scattered
    case flow_state
}

struct CalendarContext: Codable {
    let nextEventMinutes: Int?  // Minutes until next event
    let isFreetime: Bool
    let eventCount: Int         // Events today
}

struct ActivityContext: Codable {
    let stepCount: Int
    let caloriesBurned: Double
    let activeMinutes: Int
}

struct WeatherContext: Codable {
    let condition: String?      // "sunny", "rainy", etc.
    let temperature: Double?
}
```

**Purpose:** Captures the situation when thought was captured. Enables pattern recognition and context-aware suggestions.

**Gathering Strategy:**
- Time: Always available
- Location: From Core Location
- Energy: Inferred from HealthKit + circadian rhythm
- Focus: Inferred from app usage (future) or user manual
- Calendar: From EventKit
- Activity: From Core Motion + HealthKit
- Weather: Optional, from weather API

---

### 3. Classification (ML Results)

```swift
struct Classification: Codable {
    let id: UUID
    let type: ClassificationType
    let confidence: Double      // 0.0-1.0
    let entities: [String]      // "email", "john", "tuesday"
    let suggestedTags: [String]
    let sentiment: Sentiment
    let language: String?       // "en", "es", etc.
    let processingTime: TimeInterval
    let model: String           // Which Foundation Model
    let createdAt: Date
}

enum ClassificationType: String, Codable {
    case reminder      // Action item, no specific time
    case event         // Specific date/time
    case note          // FYI, no action needed
    case question      // Needs answer/research
    case idea          // Brainstorm, creative
}

enum Sentiment: String, Codable {
    case very_negative
    case negative
    case neutral
    case positive
    case very_positive
}
```

**Purpose:** Results of on-device Foundation Models inference. Stored for audit trail and fine-tuning.

**Fields:**
- `type`: What kind of thought (Reminder, Event, Note, Question, Idea)
- `confidence`: How sure the model is (0.95 = very sure, 0.6 = uncertain)
- `entities`: Extracted entities (people, dates, topics)
- `suggestedTags`: AI-suggested tags with confidence
- `sentiment`: Emotional tone
- `processingTime`: Model latency (for performance monitoring)
- `model`: Which Foundation Model generated this

**Validation:**
- `confidence`: 0.0 ≤ x ≤ 1.0
- `type`: Must be valid enum case
- `processingTime`: > 0 milliseconds

---

### 4. FineTuningData (Behavioral Learning)

```swift
struct FineTuningData: Codable {
    let id: UUID
    let thoughtId: UUID
    let classificationId: UUID
    
    // User Actions (Ground Truth)
    let createdReminder: Bool
    let reminderCompleted: Bool?
    let createdEvent: Bool
    let eventCompleted: Bool?
    let archived: Bool
    let deleted: Bool
    
    // Time Taken
    let timeToFirstAction: TimeInterval?  // Seconds to create reminder
    let timeToCompletion: TimeInterval?   // Seconds from create to done
    
    // Engagement
    let views: Int
    let shares: Int
    let edits: Int
    
    // Feedback
    let userFeedback: UserFeedback?
    
    // Timestamps
    let createdAt: Date
    let lastUpdatedAt: Date
}

struct UserFeedback: Codable {
    enum FeedbackType: String, Codable {
        case helpful
        case partially_helpful
        case not_helpful
    }
    
    let type: FeedbackType
    let comment: String?
    let timestamp: Date
}
```

**Purpose:** Tracks user interactions with thoughts and classifications. Used to:
1. Calculate "reward signal" for fine-tuning
2. Identify classification errors
3. Build user behavior model
4. Improve future suggestions
5. Train backend models (during sync)

**Data Collection:**
- Automatic: Capture all user actions (creation, completion, archival)
- Semi-automatic: Time tracking (when reminder completed)
- Manual: User explicit feedback ("This was helpful")

**Fine-Tuning Use Case:**
```
Foundation Models says: "This is a Reminder with 0.95 confidence"
User creates Reminder: ✓ (positive signal - model was right)
User completes Reminder: ✓ (higher positive signal - thought was actionable)

Later:
User created but didn't complete: Neutral signal
User marked as not helpful: Negative signal - retrain
```

---

### 5. Task (Derived from Thought)

```swift
struct Task: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let sourceThoughtId: UUID
    let title: String
    let description: String?
    let priority: Priority
    let status: TaskStatus
    let dueDate: Date?
    let estimatedEffortMinutes: Int?
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?
    let reminderId: UUID?           // EventKit reminder ID
    let eventId: UUID?              // EventKit event ID
}

enum Priority: String, Codable {
    case low
    case medium
    case high
    case critical
}

enum TaskStatus: String, Codable {
    case pending
    case in_progress
    case done
    case cancelled
}
```

**Purpose:** Actionable tasks derived from thoughts. Linked to EventKit for system integration.

**Relationship to Thought:**
- One thought can become zero or one task
- Task always has sourceThoughtId back-reference
- Task can exist without thought (user can create directly)

---

### 6. SyncQueue (Offline-First Sync)

```swift
struct SyncQueueItem: Identifiable, Codable {
    let id: UUID
    let entity: SyncEntity
    let entityId: UUID
    let action: SyncAction
    let payload: Data?        // Serialized entity
    let retries: Int
    let lastError: String?
    let createdAt: Date
    let nextRetryAt: Date
    let backendResponseId: String?
}

enum SyncEntity: String, Codable {
    case thought
    case task
    case fineTuningData
}

enum SyncAction: String, Codable {
    case create
    case update
    case delete
}
```

**Purpose:** Queue for syncing to backend when network is available.

**Flow:**
1. User captures thought (stored immediately in Core Data)
2. Create SyncQueueItem(action: .create, entity: .thought)
3. When network available → Process queue
4. If success → Remove from queue
5. If failure → Retry with exponential backoff

---

## Observation Wrappers

### @Observable View Models

```swift
@Observable
class ThoughtViewModel {
    var thoughts: [Thought] = []
    var selectedThought: Thought?
    var isLoading = false
    var error: AppError?
    
    let thoughtService: ThoughtService
    
    init(thoughtService: ThoughtService = .shared) {
        self.thoughtService = thoughtService
    }
    
    func loadThoughts() async {
        isLoading = true
        do {
            thoughts = try await thoughtService.list()
        } catch {
            self.error = error as? AppError
        }
        isLoading = false
    }
}
```

**Benefits of @Observable:**
- No @Published property boilerplate
- Type-safe binding in SwiftUI
- Fine-grained reactivity
- Automatic thread safety

---

## Core Data Schema

### Mapping to Core Data Entities

| Swift Type | Core Data Entity | Primary Key | Relationships |
|-----------|-----------------|-----------|---------------|
| Thought | ThoughtEntity | id (UUID) | ← Classification, Tasks |
| Context | Embedded JSON | — | Stored in Thought |
| Classification | ClassificationEntity | id (UUID) | ← Thought |
| FineTuningData | FineTuningDataEntity | id (UUID) | ← Thought, Classification |
| Task | TaskEntity | id (UUID) | ← Thought |
| SyncQueueItem | SyncQueueEntity | id (UUID) | — |

### Core Data Model Definition

```swift
// Pseudo-schema (Sonnet will create actual Core Data models)

ThoughtEntity (NSManagedObject)
├─ id: UUID (Primary Key)
├─ userId: UUID
├─ content: String
├─ tags: [String] (stored as JSON)
├─ status: String (enum)
├─ context: Data (stored as JSON)
├─ createdAt: Date
├─ updatedAt: Date
├─ classification: ClassificationEntity (1:1)
├─ relatedThoughts: [ThoughtEntity] (many:many)
├─ task: TaskEntity (1:0..1)
└─ fineTuningData: [FineTuningDataEntity] (1:many)

ClassificationEntity (NSManagedObject)
├─ id: UUID (Primary Key)
├─ thoughtId: UUID (Foreign Key)
├─ type: String (enum)
├─ confidence: Double
├─ entities: [String] (JSON)
├─ suggestedTags: [String] (JSON)
├─ sentiment: String (enum)
├─ processingTime: TimeInterval
├─ model: String
├─ createdAt: Date
└─ thought: ThoughtEntity (1:1 inverse)

TaskEntity (NSManagedObject)
├─ id: UUID (Primary Key)
├─ sourceThoughtId: UUID (Foreign Key)
├─ title: String
├─ description: String?
├─ priority: String (enum)
├─ status: String (enum)
├─ dueDate: Date?
├─ createdAt: Date
├─ updatedAt: Date
├─ completedAt: Date?
├─ reminderId: String? (EventKit ID)
├─ eventId: String? (EventKit ID)
└─ thought: ThoughtEntity (inverse)

FineTuningDataEntity (NSManagedObject)
├─ id: UUID (Primary Key)
├─ thoughtId: UUID (Foreign Key)
├─ classificationId: UUID (Foreign Key)
├─ createdReminder: Bool
├─ reminderCompleted: Bool?
├─ createdEvent: Bool
├─ eventCompleted: Bool?
├─ archived: Bool
├─ deleted: Bool
├─ timeToFirstAction: TimeInterval?
├─ views: Int
├─ edits: Int
├─ userFeedback: Data? (JSON)
├─ createdAt: Date
├─ lastUpdatedAt: Date
├─ thought: ThoughtEntity (inverse)
└─ classification: ClassificationEntity (inverse)

SyncQueueEntity (NSManagedObject)
├─ id: UUID (Primary Key)
├─ entity: String (enum)
├─ entityId: UUID
├─ action: String (enum)
├─ payload: Data?
├─ retries: Int
├─ lastError: String?
├─ createdAt: Date
├─ nextRetryAt: Date
└─ backendResponseId: String?
```

### Indexes

```
ThoughtEntity:
- userId + createdAt DESC    (recent thoughts)
- userId + status            (filter by status)
- id (primary key)

TaskEntity:
- status + dueDate           (active tasks)
- id (primary key)

FineTuningDataEntity:
- thoughtId                  (link to thought)
- createdAt DESC             (recent interactions)

SyncQueueEntity:
- nextRetryAt                (process by time)
- backendResponseId          (track successful syncs)
```

---

## Validation Rules (Comprehensive)

### Thought Validation

```
✓ content: 1-5000 chars, non-empty when trimmed
✓ tags: 0-5 tags, each 1-50 chars, unique, lowercase alphanumeric + hyphens
✓ status: Must be valid ThoughtStatus enum
✓ createdAt ≤ updatedAt
✓ context: Must be non-nil and valid
✓ classification: If present, must have valid type + 0 < confidence ≤ 1.0
```

### Classification Validation

```
✓ confidence: 0.0 ≤ confidence ≤ 1.0
✓ type: Must be valid ClassificationType
✓ processingTime: > 0 milliseconds
✓ entities: Non-empty array of strings
✓ suggestedTags: 0-5 tags per validation rules
```

### Task Validation

```
✓ title: 1-200 chars, non-empty
✓ priority: Valid enum
✓ status: Valid enum
✓ dueDate: If set, must be ≥ today
✓ estimatedEffortMinutes: If set, > 0
✓ completedAt: Only set when status = .done
```

---

## Repositories (Data Access Layer)

Each model has a Repository for CRUD operations:

```swift
actor ThoughtRepository {
    static let shared = ThoughtRepository()
    
    func create(_ input: Thought) async throws -> Thought
    func fetch(_ id: UUID) async throws -> Thought?
    func list(filter: ThoughtFilter) async throws -> [Thought]
    func update(_ thought: Thought) async throws
    func delete(_ id: UUID) async throws
    func search(_ query: String) async throws -> [Thought]
}

actor TaskRepository {
    static let shared = TaskRepository()
    
    func create(_ input: Task) async throws -> Task
    func fetch(_ id: UUID) async throws -> Task?
    func listByStatus(_ status: TaskStatus) async throws -> [Task]
    func update(_ task: Task) async throws
    func delete(_ id: UUID) async throws
}

actor SyncRepository {
    static let shared = SyncRepository()
    
    func enqueue(_ item: SyncQueueItem) async throws
    func dequeue(limit: Int) async throws -> [SyncQueueItem]
    func markProcessed(_ id: UUID, responseId: String) async throws
    func markFailed(_ id: UUID, error: String) async throws
    func retry(_ id: UUID, nextRetryAt: Date) async throws
}
```

---

## Codable Conformance

All models must be Codable for backend sync:

```swift
// Example custom Codable for nested structures
extension Thought: Codable {
    enum CodingKeys: String, CodingKey {
        case id, userId, content, tags, status
        case context, createdAt, updatedAt
        case classification, relatedThoughtIds, taskId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        // ... encode all fields
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        // ... decode all fields
    }
}
```

---

## Migration Strategy

### Version 1.0 (Phase 3A Foundation)

Initial Core Data model with all Phase 3A entities.

Sonnet will generate:
- Core Data model file (.xcdatamodeld)
- Migration empty (no previous version to migrate from)
- Seed data loader

### Future Migrations

When adding new fields:
1. Create new model version (v1.1, v1.2, etc.)
2. Create lightweight migration if possible
3. Create custom migration class if schema change is complex
4. Test migration path

Example future migration:
```swift
// When adding new field "transcript" to Thought
class MigrationV1_0_to_V1_1: NSEntityMigrationPolicy {
    override func createRelationships(...) throws {
        // Handle relationships for new fields
        // Set defaults for existing records
    }
}
```

---

## Testing Strategy

### Unit Tests for Models

```swift
func testThoughtValidation() throws {
    // Valid thought
    let thought = Thought(
        id: UUID(),
        userId: UUID(),
        content: "Valid thought",
        tags: ["tag1"],
        status: .active,
        context: Context(...),
        createdAt: Date(),
        updatedAt: Date(),
        classification: nil,
        relatedThoughtIds: [],
        taskId: nil
    )
    XCTAssertNoThrow(try thought.validate())
    
    // Invalid: empty content
    var invalid = thought
    invalid.content = ""
    XCTAssertThrowsError(try invalid.validate())
    
    // Invalid: too many tags
    invalid = thought
    invalid.tags = ["t1", "t2", "t3", "t4", "t5", "t6"]
    XCTAssertThrowsError(try invalid.validate())
}

func testClassificationValidation() throws {
    let classification = Classification(
        id: UUID(),
        type: .reminder,
        confidence: 0.95,
        entities: ["email"],
        suggestedTags: ["work"],
        sentiment: .positive,
        language: "en",
        processingTime: 125.5,
        model: "foundation-model-v1",
        createdAt: Date()
    )
    
    XCTAssertNoThrow(try classification.validate())
    
    // Invalid: confidence > 1.0
    var invalid = classification
    invalid.confidence = 1.5
    XCTAssertThrowsError(try invalid.validate())
}
```

### Core Data Integration Tests

```swift
func testPersistenceAndRetrieval() async throws {
    let repo = ThoughtRepository.shared
    
    let thought = Thought(...)
    let saved = try await repo.create(thought)
    
    let fetched = try await repo.fetch(saved.id)
    XCTAssertEqual(fetched, saved)
}

func testFilteringAndSearch() async throws {
    // Create multiple thoughts
    // Test filtering by status
    // Test search by content/tags
}
```

---

## Error Handling

### Custom Error Types

```swift
enum PersistenceError: LocalizedError {
    case invalidModel(String)
    case notFound(UUID)
    case corruptedData
    case migrationFailed(String)
    case concurrencyViolation
    
    var errorDescription: String? {
        switch self {
        case .invalidModel(let msg):
            return "Invalid model: \(msg)"
        case .notFound(let id):
            return "Entity with ID \(id) not found"
        case .corruptedData:
            return "Corrupted data detected, attempting recovery"
        case .migrationFailed(let msg):
            return "Migration failed: \(msg)"
        case .concurrencyViolation:
            return "Concurrent access violation"
        }
    }
}
```

---

## Sync Format (Backend Compatibility)

All models are Codable for backend sync:

```json
{
  "id": "a8f4c2b1-9d7e-4e3f-8b6c-1a2d3e4f5g6h",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "content": "Should improve email spam filter",
  "tags": ["email", "improvement"],
  "status": "active",
  "context": {
    "timestamp": "2025-12-10T14:30:00.123456Z",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "name": "New York"
    },
    "timeOfDay": "afternoon",
    "energy": "high",
    "focusState": "deep_work"
  },
  "createdAt": "2025-12-10T14:30:00.123456Z",
  "updatedAt": "2025-12-10T14:30:00.123456Z",
  "classification": {
    "id": "c8e5f6g7...",
    "type": "reminder",
    "confidence": 0.95,
    "entities": ["email", "filter"],
    "suggestedTags": ["email"],
    "sentiment": "neutral",
    "language": "en",
    "processingTime": 125.5,
    "model": "foundation-model-v1",
    "createdAt": "2025-12-10T14:30:00.123456Z"
  },
  "relatedThoughtIds": ["id1", "id2"],
  "taskId": null
}
```

---

## Notes for Sonnet

When generating these models:

1. **Use Swift 6 features:** async/await, Observation, actors
2. **Comprehensive docstrings:** Every type, property, enum case
3. **Validation methods:** Each model has `validate()` method
4. **Core Data integration:** NSManagedObject subclasses with proper relationships
5. **Codable support:** Full encoding/decoding for backend sync
6. **Type safety:** Strong typing, no `Any`, enum for restricted values
7. **Thread safety:** Use actors for repositories
8. **No copy-paste:** Extract common patterns to protocols/extensions
9. **Error handling:** Proper error types, not `fatalError`
10. **Tests included:** Unit tests for validation, integration tests for persistence

Generate production-ready models with comprehensive documentation.

---

## Output Structure

Sonnet will generate:

```
Models/
├─ Thought.swift           # Thought + ThoughtStatus
├─ Context.swift           # Context + enums (TimeOfDay, EnergyLevel, etc.)
├─ Classification.swift    # Classification + ClassificationType + Sentiment
├─ FineTuningData.swift    # FineTuningData + UserFeedback
├─ Task.swift              # Task + Priority + TaskStatus
├─ SyncQueue.swift         # SyncQueueItem + enums
└─ Enums.swift             # Shared enums

Persistence/
├─ CoreDataModels.xcdatamodeld/
│  └─ PersonalAI.xcdatamodel/
│     └─ contents               # Core Data schema
├─ PersistenceController.swift  # Core Data stack
├─ ThoughtRepository.swift      # Thought CRUD
├─ TaskRepository.swift         # Task CRUD
├─ ClassificationRepository.swift
├─ FineTuningRepository.swift
└─ SyncRepository.swift         # Sync queue management

Tests/
├─ Unit/
│  ├─ ThoughtModelTests.swift
│  ├─ ClassificationModelTests.swift
│  ├─ ValidationTests.swift
│  └─ CodableTests.swift
└─ Integration/
   ├─ CoreDataIntegrationTests.swift
   └─ RepositoryTests.swift
```

---

**Version:** 1.0  
**Status:** Ready for code generation  
**Depends On:** None (foundation spec)  
**Used By:** Spec 2 (Services), Spec 3 (ViewModels)  
