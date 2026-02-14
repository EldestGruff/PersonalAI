//
//  SyncQueueEntity.swift
//  STASH
//
//  Device-local queue for server-side enrichment operations.
//
//  Device-to-device sync is handled automatically by NSPersistentCloudKitContainer.
//  This queue is for a different purpose: dispatching work to the personal server
//  (MicroCenter/Ollama) for enrichment services that go beyond what on-device AI can do:
//
//  - Semantic vector indexing (Qdrant/pgvector for cross-device search)
//  - Heavy AI inference (larger models, insights pipelines)
//  - Fine-tuning feedback (classification corrections → model improvement)
//  - Smart notifications (server-side triggers based on thought patterns)
//  - Third-party integrations (webhooks, Todoist, etc.)
//
//  Items in this queue are device-local — each device manages its own enrichment
//  pipeline independently. They are NOT synced via CloudKit.
//

import Foundation
import CoreData

/// Core Data entity for the server enrichment queue.
///
/// Each item represents a pending operation to send to the personal server.
/// The queue persists across app restarts and retries failed operations with
/// exponential backoff.
@objc(SyncQueueEntity)
public final class SyncQueueEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged public var id: UUID

    /// Entity type being enriched (e.g. "thought", "classification")
    @NSManaged public var entityType: String

    /// ID of the entity to enrich
    @NSManaged public var entityId: UUID

    /// Operation to perform (e.g. "index", "infer", "feedback")
    @NSManaged public var action: String

    /// Serialized request payload (JSON)
    @NSManaged public var payload: Data?

    /// Retry count
    @NSManaged public var retries: Int32

    /// Last error message from the server
    @NSManaged public var lastError: String?

    /// When this item was enqueued
    @NSManaged public var createdAt: Date

    /// When to next attempt delivery (supports exponential backoff)
    @NSManaged public var nextRetryAt: Date

    /// Server response ID after successful delivery (for deduplication)
    @NSManaged public var backendResponseId: String?
}
