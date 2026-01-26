//
//  PermissionCoordinator.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Centralized Permission Management
//  Coordinates permission requests across all frameworks
//

import Foundation

// MARK: - Permission Summary

/// Aggregated permission status for all frameworks.
///
/// Provides a snapshot of permission states and helper properties
/// for determining overall app capability.
struct PermissionSummary: Sendable, Equatable {
    /// Location permission status
    let location: PermissionLevel

    /// HealthKit permission status
    let healthKit: PermissionLevel

    /// Motion/Activity permission status
    let motion: PermissionLevel

    /// Calendar/Reminders permission status
    let eventKit: PermissionLevel

    /// Contacts permission status
    let contacts: PermissionLevel

    /// Speech recognition permission status
    let speech: PermissionLevel

    /// When this summary was captured
    let timestamp: Date

    // MARK: - Computed Properties

    /// Whether all permissions are authorized
    var allAuthorized: Bool {
        location == .authorized &&
        healthKit == .authorized &&
        motion == .authorized &&
        eventKit == .authorized &&
        contacts == .authorized &&
        speech == .authorized
    }

    /// Whether any permission is explicitly denied
    var anyDenied: Bool {
        [location, healthKit, motion, eventKit, contacts, speech].contains(.denied)
    }

    /// Whether any permission is restricted
    var anyRestricted: Bool {
        [location, healthKit, motion, eventKit, contacts, speech].contains(.restricted)
    }

    /// Frameworks that haven't been asked for permission yet
    var pendingPermissions: [FrameworkType] {
        var pending: [FrameworkType] = []
        if location == .notDetermined { pending.append(.coreLocation) }
        if healthKit == .notDetermined { pending.append(.healthKit) }
        if motion == .notDetermined { pending.append(.coreMotion) }
        if eventKit == .notDetermined { pending.append(.eventKit) }
        if contacts == .notDetermined { pending.append(.contacts) }
        if speech == .notDetermined { pending.append(.speech) }
        return pending
    }

    /// Frameworks that have been denied
    var deniedPermissions: [FrameworkType] {
        var denied: [FrameworkType] = []
        if location == .denied { denied.append(.coreLocation) }
        if healthKit == .denied { denied.append(.healthKit) }
        if motion == .denied { denied.append(.coreMotion) }
        if eventKit == .denied { denied.append(.eventKit) }
        if contacts == .denied { denied.append(.contacts) }
        if speech == .denied { denied.append(.speech) }
        return denied
    }

    /// Gets the permission level for a specific framework
    func status(for framework: FrameworkType) -> PermissionLevel {
        switch framework {
        case .coreLocation: return location
        case .healthKit: return healthKit
        case .coreMotion: return motion
        case .eventKit: return eventKit
        case .contacts: return contacts
        case .speech: return speech
        case .network: return .authorized // Network doesn't need permission
        case .foundationModels: return .authorized // Foundation Models is on-device, no permission needed
        }
    }

    // MARK: - Factory

    /// Creates a summary with all permissions at the same level
    static func all(_ level: PermissionLevel) -> PermissionSummary {
        PermissionSummary(
            location: level,
            healthKit: level,
            motion: level,
            eventKit: level,
            contacts: level,
            speech: level,
            timestamp: Date()
        )
    }

    /// Creates a summary with all permissions not determined
    static var initial: PermissionSummary {
        all(.notDetermined)
    }
}

// MARK: - Permission Coordinator Protocol

/// Protocol for permission management.
///
/// Enables mocking in tests.
protocol PermissionCoordinatorProtocol: Actor, Sendable {
    /// Current cached permission summary
    var currentSummary: PermissionSummary { get async }

    /// Refreshes and returns the current permission status for all frameworks
    func refreshStatus() async -> PermissionSummary

    /// Requests permission for a specific framework
    func requestPermission(for framework: FrameworkType) async -> PermissionLevel

    /// Requests all pending permissions in sequence
    func requestAllPermissions() async -> PermissionSummary

    /// Provides an async stream of permission changes
    var permissionChanges: AsyncStream<PermissionSummary> { get }
}

// MARK: - Permission Coordinator

/// Centralized coordinator for managing permissions across all frameworks.
///
/// Aggregates permission status from all framework services and provides
/// a unified interface for requesting permissions during onboarding.
///
/// ## Usage
///
/// ```swift
/// let coordinator = PermissionCoordinator(...)
///
/// // Check current status
/// let summary = await coordinator.currentSummary
///
/// // Request all permissions (onboarding)
/// let result = await coordinator.requestAllPermissions()
///
/// // Listen for changes
/// for await summary in coordinator.permissionChanges {
///     updateUI(with: summary)
/// }
/// ```
actor PermissionCoordinator: PermissionCoordinatorProtocol {
    // MARK: - Dependencies

    private let locationService: any FrameworkServiceProtocol
    private let healthKitService: any FrameworkServiceProtocol
    private let motionService: any FrameworkServiceProtocol
    private let eventKitService: any FrameworkServiceProtocol
    private let contactsService: any FrameworkServiceProtocol
    private let speechService: any FrameworkServiceProtocol

    // MARK: - State

    private var cachedSummary: PermissionSummary = .initial
    private var continuation: AsyncStream<PermissionSummary>.Continuation?

    // MARK: - Initialization

    init(
        locationService: any FrameworkServiceProtocol,
        healthKitService: any FrameworkServiceProtocol,
        motionService: any FrameworkServiceProtocol,
        eventKitService: any FrameworkServiceProtocol,
        contactsService: any FrameworkServiceProtocol,
        speechService: any FrameworkServiceProtocol
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.motionService = motionService
        self.eventKitService = eventKitService
        self.contactsService = contactsService
        self.speechService = speechService
    }

    // MARK: - Current Status

    /// Current cached permission summary
    var currentSummary: PermissionSummary {
        cachedSummary
    }

    /// Refreshes and returns the current permission status
    func refreshStatus() async -> PermissionSummary {
        let summary = PermissionSummary(
            location: await locationService.permissionStatus,
            healthKit: await healthKitService.permissionStatus,
            motion: await motionService.permissionStatus,
            eventKit: await eventKitService.permissionStatus,
            contacts: await contactsService.permissionStatus,
            speech: await speechService.permissionStatus,
            timestamp: Date()
        )

        cachedSummary = summary
        continuation?.yield(summary)

        return summary
    }

    // MARK: - Permission Requests

    /// Requests permission for a specific framework
    func requestPermission(for framework: FrameworkType) async -> PermissionLevel {
        let service: any FrameworkServiceProtocol

        switch framework {
        case .coreLocation: service = locationService
        case .healthKit: service = healthKitService
        case .coreMotion: service = motionService
        case .eventKit: service = eventKitService
        case .contacts: service = contactsService
        case .speech: service = speechService
        case .network: return .authorized // Network doesn't need permission
        case .foundationModels: return .authorized // Foundation Models is on-device, no permission needed
        }

        let result = await service.requestPermission()

        // Refresh the full summary after any change
        _ = await refreshStatus()

        return result
    }

    /// Requests all pending permissions in sequence
    ///
    /// Requests permissions one at a time to avoid overwhelming the user.
    /// Returns the final summary after all requests are complete.
    func requestAllPermissions() async -> PermissionSummary {
        // Get current status first
        var summary = await refreshStatus()

        // Request each pending permission in sequence
        // Order: Location first (most visible benefit), then others
        let orderedFrameworks: [FrameworkType] = [
            .coreLocation,
            .healthKit,
            .coreMotion,
            .eventKit,
            .contacts,
            .speech
        ]

        for framework in orderedFrameworks {
            if summary.status(for: framework) == .notDetermined {
                _ = await requestPermission(for: framework)
                // Small delay between requests for better UX
                try? await _Concurrency.Task.sleep(for: .milliseconds(300))
            }
        }

        // Return final status
        return await refreshStatus()
    }

    // MARK: - Permission Changes Stream

    /// Provides an async stream of permission changes
    var permissionChanges: AsyncStream<PermissionSummary> {
        AsyncStream { continuation in
            self.continuation = continuation

            // Emit current status immediately
            continuation.yield(cachedSummary)

            continuation.onTermination = { [weak self] _ in
                _Concurrency.Task { [weak self] in
                    await self?.clearContinuation()
                }
            }
        }
    }

    private func clearContinuation() {
        continuation = nil
    }
}

// MARK: - Mock Coordinator

/// Mock permission coordinator for testing and previews.
actor MockPermissionCoordinator: PermissionCoordinatorProtocol {
    var currentSummary: PermissionSummary
    var requestedFrameworks: [FrameworkType] = []

    init(summary: PermissionSummary = .all(.authorized)) {
        self.currentSummary = summary
    }

    func refreshStatus() async -> PermissionSummary {
        currentSummary
    }

    func requestPermission(for framework: FrameworkType) async -> PermissionLevel {
        requestedFrameworks.append(framework)
        return .authorized
    }

    func requestAllPermissions() async -> PermissionSummary {
        currentSummary = .all(.authorized)
        return currentSummary
    }

    var permissionChanges: AsyncStream<PermissionSummary> {
        AsyncStream { continuation in
            continuation.yield(currentSummary)
            continuation.finish()
        }
    }
}
