//
//  Task.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Task model derived from thoughts
//

import Foundation

/// An actionable task derived from a thought.
///
/// Tasks represent concrete action items that the user needs to complete.
/// They can be created in two ways:
/// 1. Automatically suggested when a thought is classified as a reminder/event
/// 2. Manually created by the user
///
/// ## Relationship to Thought
///
/// - One thought can spawn zero or one task
/// - Tasks always have a `sourceThoughtId` back-reference
/// - Tasks can exist independently (user creates task directly)
///
/// ## Integration with EventKit
///
/// Tasks can be synced to system Reminders or Calendar:
/// - `reminderId`: Links to EKReminder in EventKit
/// - `eventId`: Links to EKEvent in EventKit
///
/// This enables tasks to appear in native iOS apps (Reminders, Calendar).
///
/// ## Example
///
/// ```swift
/// let task = Task(
///     id: UUID(),
///     userId: UUID(),
///     sourceThoughtId: thoughtId,
///     title: "Optimize email filter",
///     description: "Review spam patterns and update rules",
///     priority: .high,
///     status: .pending,
///     dueDate: Date().addingTimeInterval(86400 * 3), // 3 days
///     estimatedEffortMinutes: 60,
///     createdAt: Date(),
///     updatedAt: Date(),
///     completedAt: nil,
///     reminderId: nil,
///     eventId: nil
/// )
/// ```
struct Task: Identifiable, Codable, Equatable, Sendable {
    /// Unique identifier
    let id: UUID

    /// User who owns this task
    let userId: UUID

    /// ID of the thought that spawned this task
    ///
    /// Links back to the original thought for context.
    /// If task was created manually, this points to a generated thought.
    let sourceThoughtId: UUID

    /// Short task description (1-200 characters)
    ///
    /// Brief, actionable title. Examples:
    /// - "Call dentist"
    /// - "Review Q4 budget proposal"
    /// - "Buy groceries for dinner"
    let title: String

    /// Optional detailed description
    ///
    /// Longer explanation, notes, or context.
    /// Can include subtasks or implementation details.
    let description: String?

    /// Urgency and importance level
    let priority: Priority

    /// Current state in the task workflow
    let status: TaskStatus

    /// Optional deadline (nil if no specific due date)
    ///
    /// Must be >= current date when set.
    let dueDate: Date?

    /// Estimated time to complete (in minutes)
    ///
    /// Used for scheduling and workload planning.
    /// Nil if user hasn't estimated.
    let estimatedEffortMinutes: Int?

    /// When this task was created
    let createdAt: Date

    /// When this task was last modified
    let updatedAt: Date

    /// When this task was completed
    ///
    /// Only set when status == .done
    let completedAt: Date?

    /// EventKit reminder identifier (UUID string)
    ///
    /// Links to EKReminder for system Reminders app integration.
    /// Nil if task not synced to Reminders.
    let reminderId: String?

    /// EventKit event identifier (UUID string)
    ///
    /// Links to EKEvent for system Calendar app integration.
    /// Nil if task not synced to Calendar.
    let eventId: String?
}

// MARK: - Validation

extension Task {
    /// Validates the task against all business rules.
    ///
    /// Checks:
    /// - Title is non-empty and within length limits
    /// - Due date is not in the past
    /// - Estimated effort is positive
    /// - Completed timestamp is only set when status is done
    ///
    /// - Throws: `ValidationError` if any field is invalid
    nonisolated func validate() throws {
        // Title validation
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ValidationError.emptyTitle
        }
        guard title.count <= 200 else {
            throw ValidationError.titleTooLong(title.count)
        }

        // Due date validation
        if let dueDate = dueDate {
            let now = Date()
            guard dueDate >= now.addingTimeInterval(-86400) else { // Allow 1 day grace period
                throw ValidationError.invalidDueDate
            }
        }

        // Effort validation
        if let effort = estimatedEffortMinutes {
            guard effort > 0 else {
                throw ValidationError.invalidEffort(effort)
            }
        }

        // Completed timestamp validation
        if completedAt != nil && status != .done {
            throw ValidationError.invalidCompletedAt
        }

        // Timestamp consistency
        guard createdAt <= updatedAt else {
            throw ValidationError.invalidTimestamp
        }
    }
}
