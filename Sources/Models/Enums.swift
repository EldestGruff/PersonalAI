//
//  Enums.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Shared enumerations used across multiple models
//

import Foundation

/// Status of a thought in its lifecycle.
///
/// Thoughts progress through different states as users interact with them:
/// - `active`: Default state for new thoughts, visible in main lists
/// - `archived`: Hidden from main view but preserved for future reference
/// - `completed`: Marked as done, typically after associated task completion
enum ThoughtStatus: String, Codable, CaseIterable, Sendable {
    case active
    case archived
    case completed
}

/// Priority level for tasks.
///
/// Used to rank tasks by urgency and importance.
/// - `low`: Nice to have, no immediate deadline
/// - `medium`: Normal priority, should be completed soon
/// - `high`: Important, needs attention in next few days
/// - `critical`: Urgent, requires immediate action
enum Priority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Status of a task in its workflow.
///
/// - `pending`: Not yet started
/// - `in_progress`: Currently being worked on
/// - `done`: Successfully completed
/// - `cancelled`: No longer needed or was abandoned
enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case in_progress
    case done
    case cancelled
}

/// Type of entity being synchronized to the backend.
///
/// Used by the sync queue to identify which repository should handle
/// the synchronization operation.
enum SyncEntity: String, Codable, CaseIterable, Sendable {
    case thought
    case task
    case fineTuningData
}

/// Action to perform during synchronization.
///
/// - `create`: Insert new entity on backend
/// - `update`: Modify existing entity on backend
/// - `delete`: Remove entity from backend
enum SyncAction: String, Codable, CaseIterable, Sendable {
    case create
    case update
    case delete
}
