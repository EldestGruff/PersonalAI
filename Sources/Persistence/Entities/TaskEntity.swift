//
//  TaskEntity.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Core Data entity for Task
//

import Foundation
import CoreData

/// Core Data entity for persisting tasks.
///
/// Tasks are actionable items derived from thoughts.
/// Has one-to-one relationship with ThoughtEntity.
@objc(TaskEntity)
public final class TaskEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged public var id: UUID

    /// User who owns this task
    @NSManaged public var userId: UUID

    /// Source thought ID
    @NSManaged public var sourceThoughtId: UUID

    /// Task title
    @NSManaged public var title: String

    /// Optional description
    @NSManaged public var taskDescription: String?

    /// Priority (enum raw value)
    @NSManaged public var priority: String

    /// Status (enum raw value)
    @NSManaged public var status: String

    /// Optional due date
    @NSManaged public var dueDate: Date?

    /// Estimated effort in minutes
    @NSManaged public var estimatedEffortMinutes: Int32

    /// Creation timestamp
    @NSManaged public var createdAt: Date

    /// Last update timestamp
    @NSManaged public var updatedAt: Date

    /// Completion timestamp
    @NSManaged public var completedAt: Date?

    /// EventKit reminder ID
    @NSManaged public var reminderId: String?

    /// EventKit event ID
    @NSManaged public var eventId: String?

    // MARK: - Relationships

    /// One-to-one inverse relationship to thought
    @NSManaged public var thought: ThoughtEntity?
}
