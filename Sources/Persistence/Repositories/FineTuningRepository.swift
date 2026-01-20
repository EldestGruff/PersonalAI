//
//  FineTuningRepository.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Repository for FineTuningData CRUD operations
//  Thread-safe actor-based repository
//

import Foundation
import CoreData

/// Thread-safe repository for FineTuningData persistence operations
actor FineTuningRepository {
    static let shared = FineTuningRepository()

    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: - Create

    /// Creates a new fine-tuning data point
    func create(_ data: FineTuningData) async throws -> FineTuningData {
        let context = container.newBackgroundContext()

        return try await context.perform {
            let entity = try data.toEntity(in: context)
            try context.save()
            return try FineTuningData.from(entity)
        }
    }

    // MARK: - Read

    /// Fetches fine-tuning data by thought ID
    func fetch(thoughtId: UUID) async throws -> FineTuningData? {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<FineTuningDataEntity>(entityName: "FineTuningDataEntity")
        fetchRequest.predicate = NSPredicate(format: "thoughtId == %@", thoughtId as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)

        guard let entity = results.first else {
            return nil
        }

        return try FineTuningData.from(entity)
    }

    /// Lists all fine-tuning data points
    func list() async throws -> [FineTuningData] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<FineTuningDataEntity>(entityName: "FineTuningDataEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try context.fetch(fetchRequest)

        return try results.map { try FineTuningData.from($0) }
    }

    // MARK: - Update

    /// Updates an existing fine-tuning data point
    func update(_ data: FineTuningData) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<FineTuningDataEntity>(entityName: "FineTuningDataEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(data.id)
            }

            // Update entity properties
            entity.createdReminder = data.createdReminder
            entity.reminderCompleted = data.reminderCompleted as NSNumber?
            entity.createdEvent = data.createdEvent
            entity.eventCompleted = data.eventCompleted as NSNumber?
            entity.archived = data.archived
            entity.wasDeleted = data.deleted
            entity.timeToFirstAction = data.timeToFirstAction.map { NSNumber(value: $0) }
            entity.timeToCompletion = data.timeToCompletion.map { NSNumber(value: $0) }
            entity.views = Int32(data.views)
            entity.shares = Int32(data.shares)
            entity.edits = Int32(data.edits)
            entity.userFeedbackJSON = try? data.userFeedback.map { try JSONEncoder().encode($0) }
            entity.lastUpdatedAt = data.lastUpdatedAt

            try context.save()
        }
    }
}
