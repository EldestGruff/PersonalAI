//
//  ServiceProtocols.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Service Protocol Hierarchy
//  Base protocols for all services with lifecycle, health, and observability
//

import Foundation

// MARK: - Base Service Protocol

/// Base protocol that all services implement.
///
/// Provides lifecycle management, availability checking, and health status.
/// All services are actors for thread safety.
///
/// ## Lifecycle
///
/// Services have a simple lifecycle:
/// 1. Initialization (constructor)
/// 2. Optional async setup via `initialize()`
/// 3. Normal operation
/// 4. Optional cleanup via `shutdown()`
///
/// ## Thread Safety
///
/// All conforming types should be actors. This protocol uses `any` in
/// associated types to enable protocol composition.
protocol ServiceProtocol: Actor, Sendable {
    /// Whether this service is available on the current device.
    ///
    /// For framework services, this checks if the framework is available
    /// (e.g., HealthKit on iPhone). For domain services, this is always true.
    var isAvailable: Bool { get }

    /// Whether this service is in a healthy state.
    ///
    /// A service is healthy if it's available, initialized, and has no
    /// unrecoverable errors. Used for diagnostics and health checks.
    var isHealthy: Bool { get }

    /// Performs any async initialization required by the service.
    ///
    /// Called once after the service is created. Default implementation
    /// does nothing. Override for services that need async setup.
    func initialize() async throws

    /// Performs cleanup before the service is deallocated.
    ///
    /// Called when the app is terminating or the service is being replaced.
    /// Default implementation does nothing.
    func shutdown() async
}

// MARK: - Default Implementations

extension ServiceProtocol {
    /// Default implementation: service is healthy if available
    var isHealthy: Bool { isAvailable }

    /// Default implementation: no initialization needed
    func initialize() async throws {}

    /// Default implementation: no cleanup needed
    func shutdown() async {}
}

// MARK: - Domain Service Protocol

/// Protocol for services that manage domain entities via repositories.
///
/// Domain services handle business logic, validation, and orchestrate
/// side effects (classification, sync, fine-tuning). They always throw
/// errors on failure to ensure explicit error handling by callers.
///
/// ## Error Handling
///
/// Domain services throw `ServiceError` for all failures:
/// - `.validation` for input validation failures
/// - `.notFound` for missing entities
/// - `.persistence` for Core Data failures
/// - `.conflict` for concurrent modification issues
///
/// ## Example
///
/// ```swift
/// actor ThoughtService: DomainServiceProtocol {
///     func create(_ thought: Thought) async throws -> Thought {
///         // Validate
///         try validateThought(thought)
///
///         // Persist
///         let saved = try await repository.create(thought)
///
///         // Side effects
///         if configuration.features.enableClassification {
///             _Concurrency.Task { try? await classificationService.classify(saved) }
///         }
///
///         return saved
///     }
/// }
/// ```
protocol DomainServiceProtocol: ServiceProtocol {
    /// Domain services are always available
    var isAvailable: Bool { get }
}

extension DomainServiceProtocol {
    /// Domain services are always available (no framework dependencies)
    var isAvailable: Bool { true }
}

// MARK: - Framework Service Protocol

/// Protocol for services that wrap iOS frameworks.
///
/// Framework services handle permission requests, availability checks,
/// and provide a consistent interface to iOS frameworks like HealthKit,
/// CoreLocation, EventKit, etc.
///
/// ## Error Handling
///
/// Framework services follow a "fail-soft" pattern:
/// - Return optionals or default values instead of throwing
/// - Only throw for operations where failure must be handled (e.g., createReminder)
/// - Log failures internally for diagnostics
///
/// ## Permission Flow
///
/// 1. Check `permissionStatus` before operations
/// 2. If `.notDetermined`, call `requestPermission()`
/// 3. Handle `.denied` or `.restricted` gracefully
///
/// ## Example
///
/// ```swift
/// actor LocationService: FrameworkServiceProtocol {
///     let frameworkType: FrameworkType = .coreLocation
///
///     func getCurrentLocation() async -> Location? {
///         guard permissionStatus.allowsAccess else { return nil }
///         // ... implementation
///     }
/// }
/// ```
protocol FrameworkServiceProtocol: ServiceProtocol {
    /// The iOS framework this service wraps
    var frameworkType: FrameworkType { get }

    /// Current permission authorization level
    var permissionStatus: PermissionLevel { get }

    /// Requests permission from the user.
    ///
    /// This should present the system permission dialog if permission
    /// is `.notDetermined`. Returns the resulting permission level.
    ///
    /// - Returns: The permission level after the request
    @discardableResult
    func requestPermission() async -> PermissionLevel
}

extension FrameworkServiceProtocol {
    /// Human-readable name for this framework
    var frameworkName: String { frameworkType.displayName }
}

// MARK: - Orchestration Service Protocol

/// Protocol for services that coordinate multiple other services.
///
/// Orchestration services manage complex workflows that span multiple
/// services, handle parallel execution with timeouts, and aggregate
/// results from multiple sources.
///
/// ## Examples
///
/// - `ContextService`: Gathers data from Location, HealthKit, Motion, EventKit
/// - `FineTuningService`: Coordinates repository, sync, and analytics
/// - `SyncService`: Manages network, persistence, and retry logic
///
/// ## Timeout Handling
///
/// Orchestration services implement timeout patterns to meet performance
/// targets (e.g., 300ms for context gathering). Individual operations
/// that exceed timeouts return default values.
protocol OrchestrationServiceProtocol: ServiceProtocol {
    /// Configuration used by this service
    var configuration: ServiceConfiguration { get }
}

// MARK: - Repository Protocol

/// Protocol for data access repositories.
///
/// Repositories handle CRUD operations against Core Data. They are
/// actors for thread safety and provide a clean interface between
/// services and the persistence layer.
///
/// Repositories from Spec 1 (ThoughtRepository, TaskRepository, etc.)
/// already exist and implement this pattern.
protocol RepositoryProtocol: Actor, Sendable {
    /// The domain model type this repository manages
    associatedtype Model: Identifiable & Sendable

    /// Creates a new entity
    func create(_ model: Model) async throws -> Model

    /// Fetches an entity by ID
    func fetch(_ id: Model.ID) async throws -> Model?

    /// Deletes an entity by ID
    func delete(_ id: Model.ID) async throws
}

// MARK: - Service Health Status

/// Aggregated health status for a service.
///
/// Used for diagnostics and monitoring.
struct ServiceHealthStatus: Sendable {
    /// The service name
    let serviceName: String

    /// Whether the service is available
    let isAvailable: Bool

    /// Whether the service is healthy
    let isHealthy: Bool

    /// Current permission level (for framework services)
    let permissionStatus: PermissionLevel?

    /// Any error message
    let errorMessage: String?

    /// When this status was captured
    let timestamp: Date

    init(
        serviceName: String,
        isAvailable: Bool,
        isHealthy: Bool,
        permissionStatus: PermissionLevel? = nil,
        errorMessage: String? = nil,
        timestamp: Date = Date()
    ) {
        self.serviceName = serviceName
        self.isAvailable = isAvailable
        self.isHealthy = isHealthy
        self.permissionStatus = permissionStatus
        self.errorMessage = errorMessage
        self.timestamp = timestamp
    }
}

// MARK: - Service Metrics

/// Performance metrics for a service operation.
///
/// Used for monitoring and optimization.
struct ServiceMetrics: Sendable {
    /// The operation name
    let operation: String

    /// The service name
    let serviceName: String

    /// Duration in milliseconds
    let durationMs: Int

    /// Whether the operation succeeded
    let succeeded: Bool

    /// Error code if failed
    let errorCode: String?

    /// When this metric was captured
    let timestamp: Date

    init(
        operation: String,
        serviceName: String,
        durationMs: Int,
        succeeded: Bool,
        errorCode: String? = nil,
        timestamp: Date = Date()
    ) {
        self.operation = operation
        self.serviceName = serviceName
        self.durationMs = durationMs
        self.succeeded = succeeded
        self.errorCode = errorCode
        self.timestamp = timestamp
    }
}
