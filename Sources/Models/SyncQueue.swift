//
//  SyncQueue.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Offline-first synchronization queue
//

import Foundation

/// A queued operation for synchronizing data to the backend.
///
/// The sync queue implements offline-first architecture:
/// 1. User captures thought (stored immediately in Core Data)
/// 2. Create SyncQueueItem(action: .create, entity: .thought)
/// 3. When network available → Process queue in order
/// 4. If success → Remove from queue
/// 5. If failure → Retry with exponential backoff
///
/// ## Retry Strategy
///
/// - First failure: Retry after 5 seconds
/// - Second failure: Retry after 30 seconds
/// - Third failure: Retry after 5 minutes
/// - Fourth failure: Retry after 30 minutes
/// - Fifth+ failure: Retry after 2 hours
///
/// Maximum retry count: 10 (then requires manual intervention)
///
/// ## Example Flow
///
/// ```swift
/// // User creates thought offline
/// let thought = Thought(...)
/// try await thoughtRepository.create(thought)
///
/// // Queue for sync
/// let syncItem = SyncQueueItem(
///     id: UUID(),
///     entity: .thought,
///     entityId: thought.id,
///     action: .create,
///     payload: try JSONEncoder().encode(thought),
///     retries: 0,
///     lastError: nil,
///     createdAt: Date(),
///     nextRetryAt: Date(),
///     backendResponseId: nil
/// )
/// try await syncRepository.enqueue(syncItem)
///
/// // Later, when network returns...
/// let pending = try await syncRepository.dequeue(limit: 10)
/// for item in pending {
///     // Process each item
///     // If success: markProcessed(item.id, responseId)
///     // If failure: retry(item.id, calculateNextRetry())
/// }
/// ```
struct SyncQueueItem: Identifiable, Codable, Equatable, Sendable {
    /// Unique identifier for this queue item
    let id: UUID

    /// Type of entity being synchronized
    let entity: SyncEntity

    /// ID of the specific entity instance
    let entityId: UUID

    /// Action to perform on the backend
    let action: SyncAction

    /// Serialized entity data (JSON)
    ///
    /// Contains the full entity in JSON format, ready to send to backend API.
    /// Nil for delete operations (only ID is needed).
    let payload: Data?

    /// Number of retry attempts so far
    ///
    /// Incremented each time sync fails. Used to calculate exponential backoff.
    let retries: Int

    /// Error message from last failed attempt (nil if never failed)
    let lastError: String?

    /// When this item was first queued
    let createdAt: Date

    /// When to attempt next sync
    ///
    /// For new items, equals createdAt (immediate sync).
    /// For failed items, calculated using exponential backoff.
    let nextRetryAt: Date

    /// ID returned by backend on successful sync (nil if not yet synced)
    ///
    /// Used to track which items have been successfully processed.
    /// After successful sync, the item is removed from the queue.
    let backendResponseId: String?
}
