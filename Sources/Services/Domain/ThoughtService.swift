//
//  ThoughtService.swift
//  STASH
//
//  Phase 3A Spec 2: Thought Domain Service
//  Business logic for thought management
//

import Foundation

// MARK: - Thought Service Protocol

/// Protocol for thought services.
///
/// Enables mocking in tests.
protocol ThoughtServiceProtocol: DomainServiceProtocol {
    // MARK: CRUD
    func create(_ thought: Thought) async throws -> Thought
    func fetch(_ id: UUID) async throws -> Thought?
    func list(filter: ThoughtFilter?) async throws -> [Thought]
    func update(_ thought: Thought) async throws -> Thought
    func delete(_ id: UUID) async throws

    // MARK: Search
    func search(query: String) async throws -> [Thought]
    func searchByTags(_ tags: [String]) async throws -> [Thought]

    // MARK: Batch Operations
    func archive(_ ids: [UUID]) async throws
    func unarchive(_ ids: [UUID]) async throws
    func bulkDelete(_ ids: [UUID]) async throws

    // MARK: Convenience
    func listRecent(limit: Int) async throws -> [Thought]
    func listArchived() async throws -> [Thought]
}

// MARK: - Thought Service

/// Domain service for thought management.
///
/// Handles CRUD operations, validation, and orchestrates side effects
/// like classification, fine-tuning tracking, and sync queue management.
///
/// ## Error Handling
///
/// All operations throw `ServiceError` on failure:
/// - `.validation` for invalid input
/// - `.notFound` for missing thoughts
/// - `.persistence` for Core Data errors
///
/// ## Side Effects
///
/// When creating a thought:
/// 1. Validate input
/// 2. Persist to Core Data
/// 3. Optionally classify (if enabled)
/// 4. Track for fine-tuning (if enabled)
/// 5. Queue for sync (if enabled)
actor ThoughtService: ThoughtServiceProtocol {
    // MARK: - Dependencies

    private let repository: ThoughtRepository
    private let classificationService: ClassificationServiceProtocol?
    private let syncService: SyncServiceProtocol?
    private let fineTuningService: FineTuningServiceProtocol?
    private let configuration: ServiceConfiguration

    // MARK: - Initialization

    init(
        repository: ThoughtRepository = .shared,
        classificationService: ClassificationServiceProtocol? = nil,
        syncService: SyncServiceProtocol? = nil,
        fineTuningService: FineTuningServiceProtocol? = nil,
        configuration: ServiceConfiguration = .shared
    ) {
        self.repository = repository
        self.classificationService = classificationService
        self.syncService = syncService
        self.fineTuningService = fineTuningService
        self.configuration = configuration
    }

    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Create

    /// Creates a new thought.
    ///
    /// Validates the thought, persists it, and triggers side effects
    /// (classification, fine-tuning, sync) based on configuration.
    ///
    /// - Parameter thought: The thought to create
    /// - Returns: The created thought (may include classification)
    /// - Throws: `ServiceError` on validation or persistence failure
    func create(_ thought: Thought) async throws -> Thought {
        // Normalize tags (convert spaces to hyphens, lowercase)
        let normalizedTags = thought.tags.map { tag in
            tag.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .trimmingCharacters(in: .whitespaces)
        }

        // Create thought with normalized tags
        let normalizedThought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            attributedContent: thought.attributedContent,
            tags: normalizedTags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        // Validate
        try validateThought(normalizedThought)

        // Persist
        let created: Thought
        do {
            created = try await repository.create(normalizedThought)
        } catch {
            throw ServiceError.persistence(operation: "create thought", underlying: error)
        }

        // Side effects (fire and forget, don't block)
        if configuration.features.enableClassification, let classificationService {
            _Concurrency.Task {
                await self.classifyAndUpdate(created, classificationService: classificationService)
            }
        }

        if configuration.features.enableSync, let syncService {
            _Concurrency.Task {
                try? await syncService.enqueue(entity: .thought, entityId: created.id, action: .create, payload: nil)
            }
        }

        return created
    }

    private func classifyAndUpdate(_ thought: Thought, classificationService: ClassificationServiceProtocol) async {
        do {
            let classification = try await classificationService.classify(thought.content)

            // Create updated thought with classification
            let updated = Thought(
                id: thought.id,
                userId: thought.userId,
                content: thought.content,
                attributedContent: thought.attributedContent,
                tags: thought.tags.isEmpty ? classification.suggestedTags : thought.tags,
                status: thought.status,
                context: thought.context,
                createdAt: thought.createdAt,
                updatedAt: Date(),
                classification: classification,
                relatedThoughtIds: thought.relatedThoughtIds,
                taskId: thought.taskId
            )

            try await repository.update(updated)

            // Track for fine-tuning
            if configuration.features.enableFineTuningTracking, let fineTuningService {
                try? await fineTuningService.trackThoughtCreated(updated, classification: classification)
            }
        } catch {
            // Classification failure is not fatal - log and continue
            AppLogger.warning("Classification failed for thought", category: .classification)
        }
    }

    // MARK: - Read

    /// Fetches a thought by ID.
    ///
    /// - Parameter id: The thought ID
    /// - Returns: The thought, or nil if not found
    /// - Throws: `ServiceError.persistence` on Core Data error
    func fetch(_ id: UUID) async throws -> Thought? {
        do {
            return try await repository.fetch(id)
        } catch {
            throw ServiceError.persistence(operation: "fetch thought", underlying: error)
        }
    }

    /// Lists thoughts with optional filtering.
    ///
    /// - Parameter filter: Optional filter criteria
    /// - Returns: Array of matching thoughts
    /// - Throws: `ServiceError.persistence` on Core Data error
    func list(filter: ThoughtFilter?) async throws -> [Thought] {
        do {
            return try await repository.list(filter: filter)
        } catch {
            throw ServiceError.persistence(operation: "list thoughts", underlying: error)
        }
    }

    /// Lists recent thoughts.
    ///
    /// - Parameter limit: Maximum number to return
    /// - Returns: Array of recent thoughts, newest first
    func listRecent(limit: Int) async throws -> [Thought] {
        try await repository.list(filter: .active, limit: limit)
    }

    /// Lists archived thoughts.
    func listArchived() async throws -> [Thought] {
        try await list(filter: .archived)
    }

    // MARK: - Update

    /// Updates an existing thought.
    ///
    /// - Parameter thought: The updated thought
    /// - Returns: The updated thought
    /// - Throws: `ServiceError` on validation, not found, or persistence error
    func update(_ thought: Thought) async throws -> Thought {
        // Normalize tags (convert spaces to hyphens, lowercase)
        let normalizedTags = thought.tags.map { tag in
            tag.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .trimmingCharacters(in: .whitespaces)
        }

        // Create normalized thought for validation
        let normalizedThought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            attributedContent: thought.attributedContent,
            tags: normalizedTags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId,
            isShiny: thought.isShiny  // Issue #40: Preserve shiny status during updates
        )

        // Validate
        try validateThought(normalizedThought)

        // Check exists
        guard try await repository.fetch(normalizedThought.id) != nil else {
            throw ServiceError.notFound(entity: "Thought", id: normalizedThought.id)
        }

        // Update with new timestamp
        let updated = Thought(
            id: normalizedThought.id,
            userId: normalizedThought.userId,
            content: normalizedThought.content,
            attributedContent: normalizedThought.attributedContent,
            tags: normalizedTags,
            status: normalizedThought.status,
            context: normalizedThought.context,
            createdAt: normalizedThought.createdAt,
            updatedAt: Date(),
            classification: normalizedThought.classification,
            relatedThoughtIds: normalizedThought.relatedThoughtIds,
            taskId: normalizedThought.taskId,
            isShiny: normalizedThought.isShiny  // Issue #40: Preserve shiny status
        )

        do {
            try await repository.update(updated)
        } catch {
            throw ServiceError.persistence(operation: "update thought", underlying: error)
        }

        // Queue for sync
        if configuration.features.enableSync, let syncService {
            _Concurrency.Task {
                try? await syncService.enqueue(entity: .thought, entityId: updated.id, action: .update, payload: nil)
            }
        }

        return updated
    }

    // MARK: - Delete

    /// Deletes a thought by ID.
    ///
    /// - Parameter id: The thought ID
    /// - Throws: `ServiceError.notFound` or `ServiceError.persistence`
    func delete(_ id: UUID) async throws {
        // Check exists
        guard try await repository.fetch(id) != nil else {
            throw ServiceError.notFound(entity: "Thought", id: id)
        }

        do {
            try await repository.delete(id)
        } catch {
            throw ServiceError.persistence(operation: "delete thought", underlying: error)
        }

        // Queue for sync
        if configuration.features.enableSync, let syncService {
            _Concurrency.Task {
                try? await syncService.enqueue(entity: .thought, entityId: id, action: .delete, payload: nil)
            }
        }

        // Track deletion for fine-tuning
        if configuration.features.enableFineTuningTracking, let fineTuningService {
            _Concurrency.Task {
                try? await fineTuningService.trackDeleted(id)
            }
        }
    }

    // MARK: - Search

    /// Searches thoughts by content.
    ///
    /// - Parameter query: Search query string
    /// - Returns: Matching thoughts
    func search(query: String) async throws -> [Thought] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        do {
            return try await repository.search(query)
        } catch {
            throw ServiceError.persistence(operation: "search thoughts", underlying: error)
        }
    }

    /// Searches thoughts by tags.
    ///
    /// - Parameter tags: Tags to search for
    /// - Returns: Thoughts containing any of the specified tags
    func searchByTags(_ tags: [String]) async throws -> [Thought] {
        guard !tags.isEmpty else { return [] }

        // Search for each tag and combine results
        var results: Set<UUID> = []
        var thoughts: [Thought] = []

        for tag in tags {
            let matching = try await list(filter: .byTag(tag))
            for thought in matching {
                if !results.contains(thought.id) {
                    results.insert(thought.id)
                    thoughts.append(thought)
                }
            }
        }

        return thoughts
    }

    // MARK: - Batch Operations

    /// Archives multiple thoughts.
    ///
    /// - Parameter ids: IDs of thoughts to archive
    func archive(_ ids: [UUID]) async throws {
        for id in ids {
            if let thought = try await fetch(id) {
                let archived = Thought(
                    id: thought.id,
                    userId: thought.userId,
                    content: thought.content,
                    attributedContent: thought.attributedContent,
                    tags: thought.tags,
                    status: .archived,
                    context: thought.context,
                    createdAt: thought.createdAt,
                    updatedAt: Date(),
                    classification: thought.classification,
                    relatedThoughtIds: thought.relatedThoughtIds,
                    taskId: thought.taskId
                )
                _ = try await update(archived)

                // Track for fine-tuning
                if configuration.features.enableFineTuningTracking, let fineTuningService {
                    try? await fineTuningService.trackArchived(id)
                }
            }
        }
    }

    /// Unarchives multiple thoughts.
    ///
    /// - Parameter ids: IDs of thoughts to unarchive
    func unarchive(_ ids: [UUID]) async throws {
        for id in ids {
            if let thought = try await fetch(id) {
                let unarchived = Thought(
                    id: thought.id,
                    userId: thought.userId,
                    content: thought.content,
                    attributedContent: thought.attributedContent,
                    tags: thought.tags,
                    status: .active,
                    context: thought.context,
                    createdAt: thought.createdAt,
                    updatedAt: Date(),
                    classification: thought.classification,
                    relatedThoughtIds: thought.relatedThoughtIds,
                    taskId: thought.taskId
                )
                _ = try await update(unarchived)
            }
        }
    }

    /// Deletes multiple thoughts.
    ///
    /// - Parameter ids: IDs of thoughts to delete
    func bulkDelete(_ ids: [UUID]) async throws {
        for id in ids {
            try await delete(id)
        }
    }

    // MARK: - Validation

    private func validateThought(_ thought: Thought) throws {
        // Content validation
        let trimmedContent = thought.content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContent.isEmpty {
            throw ServiceError.validation(.emptyField(fieldName: "content"))
        }

        let maxLength = configuration.limits.maxContentLength
        if thought.content.count > maxLength {
            throw ServiceError.validation(.fieldTooLong(
                fieldName: "content",
                maxLength: maxLength,
                actualLength: thought.content.count
            ))
        }

        // Tags validation
        let maxTags = configuration.limits.maxTagsPerThought
        if thought.tags.count > maxTags {
            throw ServiceError.validation(.tooManyElements(
                fieldName: "tags",
                maxCount: maxTags,
                actualCount: thought.tags.count
            ))
        }

        for tag in thought.tags {
            if tag.count > 50 {
                throw ServiceError.validation(.fieldTooLong(
                    fieldName: "tag",
                    maxLength: 50,
                    actualLength: tag.count
                ))
            }

            let validCharacters = CharacterSet.lowercaseLetters
                .union(.decimalDigits)
                .union(CharacterSet(charactersIn: "-"))

            if !tag.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) {
                throw ServiceError.validation(.invalidFormat(
                    fieldName: "tag",
                    expected: "lowercase letters, numbers, and hyphens only"
                ))
            }
        }

        // Timestamp validation
        if thought.createdAt > thought.updatedAt {
            throw ServiceError.validation(.invalidTimestamp(
                message: "createdAt cannot be after updatedAt"
            ))
        }
    }
}

// MARK: - Mock Thought Service

/// Mock thought service for testing and previews.
actor MockThoughtService: ThoughtServiceProtocol {
    nonisolated var isAvailable: Bool { true }

    var thoughts: [UUID: Thought] = [:]
    var createCallCount = 0
    var deleteCallCount = 0

    func create(_ thought: Thought) async throws -> Thought {
        createCallCount += 1
        thoughts[thought.id] = thought
        return thought
    }

    func fetch(_ id: UUID) async throws -> Thought? {
        thoughts[id]
    }

    func list(filter: ThoughtFilter?) async throws -> [Thought] {
        Array(thoughts.values)
    }

    func update(_ thought: Thought) async throws -> Thought {
        thoughts[thought.id] = thought
        return thought
    }

    func delete(_ id: UUID) async throws {
        deleteCallCount += 1
        thoughts.removeValue(forKey: id)
    }

    func search(query: String) async throws -> [Thought] {
        thoughts.values.filter { $0.content.contains(query) }
    }

    func searchByTags(_ tags: [String]) async throws -> [Thought] {
        thoughts.values.filter { thought in
            tags.contains { thought.tags.contains($0) }
        }
    }

    func archive(_ ids: [UUID]) async throws {
        for id in ids {
            if let thought = thoughts[id] {
                thoughts[id] = Thought(
                    id: thought.id,
                    userId: thought.userId,
                    content: thought.content,
                    attributedContent: thought.attributedContent,
                    tags: thought.tags,
                    status: .archived,
                    context: thought.context,
                    createdAt: thought.createdAt,
                    updatedAt: Date(),
                    classification: thought.classification,
                    relatedThoughtIds: thought.relatedThoughtIds,
                    taskId: thought.taskId
                )
            }
        }
    }

    func unarchive(_ ids: [UUID]) async throws {
        for id in ids {
            if let thought = thoughts[id] {
                thoughts[id] = Thought(
                    id: thought.id,
                    userId: thought.userId,
                    content: thought.content,
                    attributedContent: thought.attributedContent,
                    tags: thought.tags,
                    status: .active,
                    context: thought.context,
                    createdAt: thought.createdAt,
                    updatedAt: Date(),
                    classification: thought.classification,
                    relatedThoughtIds: thought.relatedThoughtIds,
                    taskId: thought.taskId
                )
            }
        }
    }

    func bulkDelete(_ ids: [UUID]) async throws {
        for id in ids {
            thoughts.removeValue(forKey: id)
        }
    }

    func listRecent(limit: Int) async throws -> [Thought] {
        Array(thoughts.values.prefix(limit))
    }

    func listArchived() async throws -> [Thought] {
        thoughts.values.filter { $0.status == .archived }
    }
}
