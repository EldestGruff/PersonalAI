//
//  SyncRepository.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Repository for SyncQueueItem CRUD operations
//  Thread-safe actor-based repository
//

import Foundation
import CoreData

/// Thread-safe repository for SyncQueueItem persistence operations
actor SyncRepository {
    nonisolated(unsafe) static let shared = SyncRepository()

    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: - Create

    /// Enqueues a new sync item
    func enqueue(_ item: SyncQueueItem) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            _ = try item.toEntity(in: context)
            try context.save()
        }
    }

    // MARK: - Read

    /// Dequeues items ready for processing
    func dequeue(limit: Int) async throws -> [SyncQueueItem] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<SyncQueueEntity>(entityName: "SyncQueueEntity")
        fetchRequest.predicate = NSPredicate(format: "nextRetryAt <= %@", Date() as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        fetchRequest.fetchLimit = limit

        let results = try context.fetch(fetchRequest)

        return try results.map { try SyncQueueItem.from($0) }
    }

    // MARK: - Update

    /// Marks an item as processed
    func markProcessed(_ id: UUID, responseId: String) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<SyncQueueEntity>(entityName: "SyncQueueEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(id)
            }

            entity.backendResponseId = responseId
            context.delete(entity)  // Remove from queue after successful sync
            try context.save()
        }
    }

    /// Marks an item as failed and schedules retry
    func markFailed(_ id: UUID, error: String) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<SyncQueueEntity>(entityName: "SyncQueueEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(id)
            }

            entity.lastError = error
            entity.retries += 1

            try context.save()
        }
    }

    /// Updates retry schedule
    func retry(_ id: UUID, nextRetryAt: Date) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<SyncQueueEntity>(entityName: "SyncQueueEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(id)
            }

            entity.nextRetryAt = nextRetryAt

            try context.save()
        }
    }
}
