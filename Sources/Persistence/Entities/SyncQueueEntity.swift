//
//  SyncQueueEntity.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Core Data entity for SyncQueue
//

import Foundation
import CoreData

/// Core Data entity for persisting sync queue items.
///
/// Stores pending synchronization operations for offline-first architecture.
/// No relationships to other entities.
@objc(SyncQueueEntity)
public final class SyncQueueEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged public var id: UUID

    /// Entity type (enum raw value)
    @NSManaged public var entityType: String

    /// Entity ID to sync
    @NSManaged public var entityId: UUID

    /// Action to perform (enum raw value)
    @NSManaged public var action: String

    /// Serialized payload (JSON)
    @NSManaged public var payload: Data?

    /// Retry count
    @NSManaged public var retries: Int32

    /// Last error message
    @NSManaged public var lastError: String?

    /// Creation timestamp
    @NSManaged public var createdAt: Date

    /// Next retry timestamp
    @NSManaged public var nextRetryAt: Date

    /// Backend response ID (after successful sync)
    @NSManaged public var backendResponseId: String?
}
