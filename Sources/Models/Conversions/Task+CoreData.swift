//
//  Task+CoreData.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Bidirectional conversion between Task and TaskEntity
//

import Foundation
import CoreData

extension Task {
    /// Converts this Swift struct to a Core Data entity.
    ///
    /// - Parameter context: The Core Data managed object context
    /// - Returns: A new `TaskEntity` instance
    /// - Throws: `ConversionError` if conversion fails
    nonisolated func toEntity(in context: NSManagedObjectContext) throws -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = self.id
        entity.userId = self.userId
        entity.sourceThoughtId = self.sourceThoughtId
        entity.title = self.title
        entity.taskDescription = self.description
        entity.priority = self.priority.rawValue
        entity.status = self.status.rawValue
        entity.dueDate = self.dueDate
        entity.estimatedEffortMinutes = self.estimatedEffortMinutes.map { Int32($0) } ?? 0
        entity.createdAt = self.createdAt
        entity.updatedAt = self.updatedAt
        entity.completedAt = self.completedAt
        entity.reminderId = self.reminderId
        entity.eventId = self.eventId

        return entity
    }

    /// Creates a Swift struct from a Core Data entity.
    ///
    /// - Parameter entity: The Core Data entity to convert
    /// - Returns: A new `Task` instance
    /// - Throws: `ConversionError` if conversion fails
    nonisolated static func from(_ entity: TaskEntity) throws -> Task {
        // Parse enums
        guard let priority = Priority(rawValue: entity.priority) else {
            throw ConversionError.typeMismatch("Invalid Priority: \(entity.priority)")
        }
        guard let status = TaskStatus(rawValue: entity.status) else {
            throw ConversionError.typeMismatch("Invalid TaskStatus: \(entity.status)")
        }

        let estimatedEffortMinutes = entity.estimatedEffortMinutes > 0 ? Int(entity.estimatedEffortMinutes) : nil

        return Task(
            id: entity.id,
            userId: entity.userId,
            sourceThoughtId: entity.sourceThoughtId,
            title: entity.title,
            description: entity.taskDescription,
            priority: priority,
            status: status,
            dueDate: entity.dueDate,
            estimatedEffortMinutes: estimatedEffortMinutes,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            completedAt: entity.completedAt,
            reminderId: entity.reminderId,
            eventId: entity.eventId
        )
    }
}
