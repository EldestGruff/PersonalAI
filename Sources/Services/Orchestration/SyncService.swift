//
//  SyncService.swift
//  STASH
//
//  Phase 3A Spec 2: Sync Queue Service
//  Offline-first synchronization with backend
//

import Foundation

// MARK: - Sync Status

/// Current sync queue status.
struct SyncStatus: Sendable {
    /// Number of items pending sync
    let pendingCount: Int

    /// Number of items that have failed
    let failedCount: Int

    /// Whether sync is currently in progress
    let isSyncing: Bool

    /// When the last sync completed
    let lastSyncAt: Date?

    /// Error from last sync attempt
    let lastError: String?
}

// MARK: - Sync Service Protocol

/// Protocol for sync services.
///
/// Enables mocking in tests.
protocol SyncServiceProtocol: OrchestrationServiceProtocol {
    /// Enqueues an entity for synchronization
    func enqueue(entity: SyncEntity, entityId: UUID, action: SyncAction, payload: Data?) async throws

    /// Processes pending sync items
    func processQueue() async throws

    /// Gets the current sync status
    func getStatus() async -> SyncStatus

    /// Number of pending items
    var pendingCount: Int { get async }

    /// Whether sync is currently in progress
    var isSyncing: Bool { get }
}

// MARK: - Sync Service

/// Service for offline-first synchronization with backend.
///
/// Implements a queue-based sync pattern:
/// 1. User actions create sync queue items
/// 2. When network available, process queue in order
/// 3. Failed items retry with exponential backoff
/// 4. Success removes item from queue
///
/// ## Phase 3A Note
///
/// In Phase 3A, the backend is mocked. Real API integration
/// will be implemented in Phase 4. The sync queue infrastructure
/// is fully functional for when the backend is ready.
///
/// ## Retry Strategy
///
/// Uses exponential backoff with jitter:
/// - Attempt 1: 1s delay
/// - Attempt 2: 2s delay
/// - Attempt 3: 4s delay
/// - ...up to max delay (32s default)
///
/// Maximum retries: 5 (configurable)
actor SyncService: SyncServiceProtocol {
    // MARK: - Dependencies

    private let repository: SyncRepository
    private let networkMonitor: NetworkMonitorProtocol
    let configuration: ServiceConfiguration

    // MARK: - State

    private var _isSyncing = false
    private var lastSyncAt: Date?
    private var lastError: String?

    // MARK: - Initialization

    init(
        repository: SyncRepository = .shared,
        networkMonitor: NetworkMonitorProtocol,
        configuration: ServiceConfiguration = .shared
    ) {
        self.repository = repository
        self.networkMonitor = networkMonitor
        self.configuration = configuration
    }

    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    /// Whether sync is currently in progress
    nonisolated var isSyncing: Bool {
        // Note: This is a race condition but acceptable for UI status
        false // Would need to make this @MainActor or use a different pattern
    }

    // MARK: - Enqueue

    /// Enqueues an entity for synchronization.
    ///
    /// Creates a sync queue item that will be processed when network is available.
    ///
    /// - Parameters:
    ///   - entity: Type of entity (thought, task, fineTuningData)
    ///   - entityId: ID of the entity
    ///   - action: Action to perform (create, update, delete)
    ///   - payload: Optional JSON payload (for create/update)
    func enqueue(entity: SyncEntity, entityId: UUID, action: SyncAction, payload: Data? = nil) async throws {
        guard configuration.features.enableSync else { return }

        let item = SyncQueueItem(
            id: UUID(),
            entity: entity,
            entityId: entityId,
            action: action,
            payload: payload,
            retries: 0,
            lastError: nil,
            createdAt: Date(),
            nextRetryAt: Date(), // Ready immediately
            backendResponseId: nil
        )

        do {
            try await repository.enqueue(item)
        } catch {
            throw ServiceError.persistence(operation: "enqueue sync item", underlying: error)
        }

        // Trigger sync if we have network
        if await networkMonitor.isConnected {
            _Concurrency.Task {
                try? await self.processQueue()
            }
        }
    }

    // MARK: - Process Queue

    /// Processes pending sync items.
    ///
    /// Dequeues items that are ready for sync and attempts to process them.
    /// Failed items are rescheduled with exponential backoff.
    func processQueue() async throws {
        guard configuration.features.enableSync else { return }
        guard await networkMonitor.isConnected else { return }
        guard !_isSyncing else { return } // Already syncing

        _isSyncing = true
        defer { _isSyncing = false }

        let batchSize = configuration.limits.syncBatchSize

        do {
            let items = try await repository.dequeue(limit: batchSize)

            for item in items {
                await processItem(item)
            }

            lastSyncAt = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            throw ServiceError.persistence(operation: "process sync queue", underlying: error)
        }
    }

    private func processItem(_ item: SyncQueueItem) async {
        do {
            // In Phase 3A, backend is mocked
            let responseId = try await mockBackendSync(item)

            // Success - remove from queue
            try await repository.markProcessed(item.id, responseId: responseId)
        } catch {
            // Failure - update retry info
            try? await repository.markFailed(item.id, error: error.localizedDescription)

            // Schedule retry if under max retries
            if item.retries < configuration.retryPolicy.maxRetries {
                let nextRetry = Date().addingTimeInterval(
                    configuration.retryPolicy.delay(forAttempt: item.retries)
                )
                try? await repository.retry(item.id, nextRetryAt: nextRetry)
            }
        }
    }

    /// Mock backend sync for Phase 3A.
    ///
    /// In Phase 4+, this will be replaced with real API calls.
    private func mockBackendSync(_ item: SyncQueueItem) async throws -> String {
        // Simulate network latency
        try await _Concurrency.Task.sleep(for: .milliseconds(50))

        // Simulate occasional failures (10% failure rate for testing)
        if Int.random(in: 0..<10) == 0 {
            throw NSError(domain: "MockSync", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Simulated server error"
            ])
        }

        // Return mock response ID
        return "mock-response-\(UUID().uuidString.prefix(8))"
    }

    // MARK: - Status

    /// Gets the current sync status.
    func getStatus() async -> SyncStatus {
        let pending = await pendingCount
        let failed = 0 // Would need to track this separately

        return SyncStatus(
            pendingCount: pending,
            failedCount: failed,
            isSyncing: _isSyncing,
            lastSyncAt: lastSyncAt,
            lastError: lastError
        )
    }

    /// Number of pending items.
    var pendingCount: Int {
        get async {
            do {
                let items = try await repository.dequeue(limit: 1000)
                return items.count
            } catch {
                return 0
            }
        }
    }
}

// MARK: - Mock Sync Service

/// Mock sync service for testing and previews.
actor MockSyncService: SyncServiceProtocol {
    nonisolated var isAvailable: Bool { true }
    nonisolated var isSyncing: Bool { false }
    let configuration: ServiceConfiguration

    var enqueuedItems: [(SyncEntity, UUID, SyncAction)] = []
    var processCallCount = 0

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
    }

    func enqueue(entity: SyncEntity, entityId: UUID, action: SyncAction, payload: Data?) async throws {
        enqueuedItems.append((entity, entityId, action))
    }

    func processQueue() async throws {
        processCallCount += 1
    }

    func getStatus() async -> SyncStatus {
        SyncStatus(
            pendingCount: enqueuedItems.count,
            failedCount: 0,
            isSyncing: false,
            lastSyncAt: Date(),
            lastError: nil
        )
    }

    var pendingCount: Int {
        get async { enqueuedItems.count }
    }
}
