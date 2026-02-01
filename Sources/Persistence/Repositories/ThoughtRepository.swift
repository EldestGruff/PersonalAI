//
//  ThoughtRepository.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Repository for Thought CRUD operations
//  Thread-safe actor-based repository
//

import Foundation
import CoreData

/// Thread-safe repository for Thought persistence operations
actor ThoughtRepository {
    static let shared = ThoughtRepository()

    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: - Create

    /// Creates a new thought in the persistent store
    func create(_ thought: Thought) async throws -> Thought {
        // Note: Validation handled by ThoughtService - repository only persists
        let context = container.newBackgroundContext()

        return try await context.perform {
            let entity = try thought.toEntity(in: context)
            try context.save()
            return try Thought.from(entity)
        }
    }

    // MARK: - Read

    /// Fetches a thought by ID
    func fetch(_ id: UUID) async throws -> Thought? {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)

        guard let entity = results.first else {
            return nil
        }

        return try Thought.from(entity)
    }

    /// Lists all thoughts with optional filtering
    func list(filter: ThoughtFilter? = nil) async throws -> [Thought] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")

        if let filter = filter {
            fetchRequest.predicate = filter.predicate
        }

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try context.fetch(fetchRequest)

        return try results.map { try Thought.from($0) }
    }

    /// Searches thoughts by content
    func search(_ query: String) async throws -> [Thought] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        fetchRequest.predicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try context.fetch(fetchRequest)

        return try results.map { try Thought.from($0) }
    }

    // MARK: - Update

    /// Updates an existing thought
    func update(_ thought: Thought) async throws {
        try thought.validate()

        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", thought.id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(thought.id)
            }

            // Update entity properties
            entity.content = thought.content
            entity.tagsJSON = try JSONEncoder().encode(thought.tags)
            entity.status = thought.status.rawValue
            entity.contextJSON = try JSONEncoder().encode(thought.context)
            entity.updatedAt = thought.updatedAt

            try context.save()
        }
    }

    // MARK: - Delete

    /// Deletes a thought by ID
    func delete(_ id: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(id)
            }

            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Many-to-Many Relationships

    /// Adds a related thought relationship
    func addRelatedThought(_ relatedId: UUID, toThought thoughtId: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id IN %@", [thoughtId, relatedId])

            let results = try context.fetch(fetchRequest)

            guard let thought = results.first(where: { $0.id == thoughtId }),
                  let related = results.first(where: { $0.id == relatedId }) else {
                throw PersistenceError.notFound(thoughtId)
            }

            thought.addToRelatedThoughts(related)
            related.addToRelatedThoughts(thought)

            try context.save()
        }
    }

    /// Removes a related thought relationship
    func removeRelatedThought(_ relatedId: UUID, fromThought thoughtId: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id IN %@", [thoughtId, relatedId])

            let results = try context.fetch(fetchRequest)

            guard let thought = results.first(where: { $0.id == thoughtId }),
                  let related = results.first(where: { $0.id == relatedId }) else {
                throw PersistenceError.notFound(thoughtId)
            }

            thought.removeFromRelatedThoughts(related)
            related.removeFromRelatedThoughts(thought)

            try context.save()
        }
    }

    /// Gets all related thoughts for a given thought
    func getRelatedThoughts(for thoughtId: UUID) async throws -> [Thought] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", thoughtId as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let entity = try context.fetch(fetchRequest).first else {
            throw PersistenceError.notFound(thoughtId)
        }

        if let relatedSet = entity.relatedThoughts as? Set<ThoughtEntity> {
            return try relatedSet.map { try Thought.from($0) }
        }

        return []
    }
}

/// Filter options for thought queries
enum ThoughtFilter: Sendable {
    case active
    case archived
    case byUserId(UUID)
    case byStatus(ThoughtStatus)
    case byTag(String)

    nonisolated var predicate: NSPredicate {
        switch self {
        case .active:
            return NSPredicate(format: "status == %@", ThoughtStatus.active.rawValue)
        case .archived:
            return NSPredicate(format: "status == %@", ThoughtStatus.archived.rawValue)
        case .byUserId(let userId):
            return NSPredicate(format: "userId == %@", userId as CVarArg)
        case .byStatus(let status):
            return NSPredicate(format: "status == %@", status.rawValue)
        case .byTag(let tag):
            return NSPredicate(format: "tagsJSON CONTAINS %@", tag)
        }
    }
}
