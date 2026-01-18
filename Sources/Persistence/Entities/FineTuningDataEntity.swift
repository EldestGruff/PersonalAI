//
//  FineTuningDataEntity.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Core Data entity for FineTuningData
//

import Foundation
import CoreData

/// Core Data entity for persisting fine-tuning data.
///
/// Tracks user interactions for behavioral learning and model improvement.
/// Has many-to-one relationships with both ThoughtEntity and ClassificationEntity.
@objc(FineTuningDataEntity)
public final class FineTuningDataEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged public var id: UUID

    /// Reference to thought
    @NSManaged public var thoughtId: UUID

    /// Reference to classification
    @NSManaged public var classificationId: UUID

    // MARK: - User Actions

    @NSManaged public var createdReminder: Bool
    @NSManaged public var reminderCompleted: NSNumber? // Bool? stored as NSNumber
    @NSManaged public var createdEvent: Bool
    @NSManaged public var eventCompleted: NSNumber? // Bool? stored as NSNumber
    @NSManaged public var archived: Bool
    @NSManaged public var wasDeleted: Bool

    // MARK: - Time Metrics

    @NSManaged public var timeToFirstAction: NSNumber? // TimeInterval? stored as NSNumber
    @NSManaged public var timeToCompletion: NSNumber? // TimeInterval? stored as NSNumber

    // MARK: - Engagement Metrics

    @NSManaged public var views: Int32
    @NSManaged public var shares: Int32
    @NSManaged public var edits: Int32

    // MARK: - Feedback

    /// User feedback stored as JSON
    @NSManaged public var userFeedbackJSON: Data?

    // MARK: - Timestamps

    @NSManaged public var createdAt: Date
    @NSManaged public var lastUpdatedAt: Date

    // MARK: - Relationships

    /// Many-to-one inverse relationship to thought
    @NSManaged public var thought: ThoughtEntity

    /// Many-to-one inverse relationship to classification
    @NSManaged public var classification: ClassificationEntity
}
