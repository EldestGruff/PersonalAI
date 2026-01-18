//
//  FineTuningData+CoreData.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Bidirectional conversion between FineTuningData and FineTuningDataEntity
//

import Foundation
import CoreData

extension FineTuningData {
    /// Converts this Swift struct to a Core Data entity.
    ///
    /// - Parameter context: The Core Data managed object context
    /// - Returns: A new `FineTuningDataEntity` instance
    /// - Throws: `ConversionError` if JSON encoding fails
    nonisolated func toEntity(in context: NSManagedObjectContext) throws -> FineTuningDataEntity {
        let entity = FineTuningDataEntity(context: context)
        entity.id = self.id
        entity.thoughtId = self.thoughtId
        entity.classificationId = self.classificationId

        // User actions
        entity.createdReminder = self.createdReminder
        entity.reminderCompleted = self.reminderCompleted.map { NSNumber(value: $0) }
        entity.createdEvent = self.createdEvent
        entity.eventCompleted = self.eventCompleted.map { NSNumber(value: $0) }
        entity.archived = self.archived
        entity.wasDeleted = self.deleted

        // Time metrics
        entity.timeToFirstAction = self.timeToFirstAction.map { NSNumber(value: $0) }
        entity.timeToCompletion = self.timeToCompletion.map { NSNumber(value: $0) }

        // Engagement metrics
        entity.views = Int32(self.views)
        entity.shares = Int32(self.shares)
        entity.edits = Int32(self.edits)

        // User feedback (encode as JSON)
        if let feedback = self.userFeedback {
            do {
                entity.userFeedbackJSON = try JSONEncoder().encode(feedback)
            } catch {
                throw ConversionError.invalidJSONData("userFeedback")
            }
        }

        // Timestamps
        entity.createdAt = self.createdAt
        entity.lastUpdatedAt = self.lastUpdatedAt

        return entity
    }

    /// Creates a Swift struct from a Core Data entity.
    ///
    /// - Parameter entity: The Core Data entity to convert
    /// - Returns: A new `FineTuningData` instance
    /// - Throws: `ConversionError` if JSON decoding fails
    nonisolated static func from(_ entity: FineTuningDataEntity) throws -> FineTuningData {
        // Decode user feedback from JSON
        let userFeedback: UserFeedback?
        if let feedbackJSON = entity.userFeedbackJSON {
            do {
                userFeedback = try JSONDecoder().decode(UserFeedback.self, from: feedbackJSON)
            } catch {
                throw ConversionError.invalidJSONData("userFeedback")
            }
        } else {
            userFeedback = nil
        }

        return FineTuningData(
            id: entity.id,
            thoughtId: entity.thoughtId,
            classificationId: entity.classificationId,
            createdReminder: entity.createdReminder,
            reminderCompleted: entity.reminderCompleted?.boolValue,
            createdEvent: entity.createdEvent,
            eventCompleted: entity.eventCompleted?.boolValue,
            archived: entity.archived,
            deleted: entity.wasDeleted,
            timeToFirstAction: entity.timeToFirstAction?.doubleValue,
            timeToCompletion: entity.timeToCompletion?.doubleValue,
            views: Int(entity.views),
            shares: Int(entity.shares),
            edits: Int(entity.edits),
            userFeedback: userFeedback,
            createdAt: entity.createdAt,
            lastUpdatedAt: entity.lastUpdatedAt
        )
    }
}
