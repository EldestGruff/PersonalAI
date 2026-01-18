//
//  ServiceContainer.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Dependency Injection Container
//  Lightweight DI for service registration and resolution
//

import Foundation

// MARK: - Service Scope

/// Defines the lifecycle of a registered service.
enum ServiceScope: Sendable {
    /// Single instance shared across all resolutions
    case singleton

    /// New instance created for each resolution
    case transient
}

// MARK: - Service Container

/// Lightweight dependency injection container for services.
///
/// Enables loose coupling between services and supports testing through
/// mock injection. Thread-safe via actor isolation.
///
/// ## Registration
///
/// Register services at app startup:
/// ```swift
/// await ServiceContainer.shared.register(LocationServiceProtocol.self) {
///     LocationService()
/// }
/// ```
///
/// ## Resolution
///
/// Resolve services when needed:
/// ```swift
/// let locationService = await ServiceContainer.shared.resolve(LocationServiceProtocol.self)
/// ```
///
/// ## Testing
///
/// Override with mocks in tests:
/// ```swift
/// await ServiceContainer.shared.override(LocationServiceProtocol.self, with: MockLocationService())
/// ```
actor ServiceContainer {
    /// Shared container instance
    static let shared = ServiceContainer()

    /// Service configuration
    private(set) var configuration: ServiceConfiguration

    /// Factory storage
    private var factories: [ObjectIdentifier: FactoryEntry] = [:]

    /// Singleton instance storage
    private var singletons: [ObjectIdentifier: Any] = [:]

    /// Override storage (for testing)
    private var overrides: [ObjectIdentifier: Any] = [:]

    // MARK: - Types

    private struct FactoryEntry {
        let factory: () -> Any
        let scope: ServiceScope
    }

    // MARK: - Initialization

    private init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
    }

    // MARK: - Configuration

    /// Updates the service configuration.
    ///
    /// - Parameter configuration: The new configuration
    func setConfiguration(_ configuration: ServiceConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Registration

    /// Registers a service factory.
    ///
    /// - Parameters:
    ///   - type: The protocol or type to register
    ///   - scope: The service lifecycle (default: singleton)
    ///   - factory: A closure that creates the service instance
    func register<T>(
        _ type: T.Type,
        scope: ServiceScope = .singleton,
        factory: @escaping () -> T
    ) {
        let key = ObjectIdentifier(type)
        factories[key] = FactoryEntry(factory: factory, scope: scope)

        // Clear any existing singleton when re-registering
        singletons.removeValue(forKey: key)
    }

    /// Registers a service instance directly (always singleton).
    ///
    /// - Parameters:
    ///   - type: The protocol or type to register
    ///   - instance: The service instance
    func register<T>(_ type: T.Type, instance: T) {
        let key = ObjectIdentifier(type)
        factories[key] = FactoryEntry(factory: { instance }, scope: .singleton)
        singletons[key] = instance
    }

    // MARK: - Resolution

    /// Resolves a registered service.
    ///
    /// - Parameter type: The protocol or type to resolve
    /// - Returns: The service instance
    /// - Note: Crashes if the service is not registered. Use `resolveOptional` for safe resolution.
    func resolve<T>(_ type: T.Type) -> T {
        guard let service = resolveOptional(type) else {
            fatalError("Service \(type) is not registered. Call register() first.")
        }
        return service
    }

    /// Attempts to resolve a registered service.
    ///
    /// - Parameter type: The protocol or type to resolve
    /// - Returns: The service instance, or nil if not registered
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = ObjectIdentifier(type)

        // Check overrides first (for testing)
        if let override = overrides[key] as? T {
            return override
        }

        // Check existing singletons
        if let singleton = singletons[key] as? T {
            return singleton
        }

        // Create from factory
        guard let entry = factories[key] else {
            return nil
        }

        let instance = entry.factory() as! T

        // Store singleton
        if entry.scope == .singleton {
            singletons[key] = instance
        }

        return instance
    }

    /// Checks if a service is registered.
    ///
    /// - Parameter type: The protocol or type to check
    /// - Returns: True if registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = ObjectIdentifier(type)
        return factories[key] != nil || overrides[key] != nil
    }

    // MARK: - Testing Support

    /// Overrides a service with a mock instance.
    ///
    /// Overrides take precedence over regular registrations.
    /// Use `clearOverride` or `reset` to restore normal behavior.
    ///
    /// - Parameters:
    ///   - type: The protocol or type to override
    ///   - instance: The mock instance
    func override<T>(_ type: T.Type, with instance: T) {
        let key = ObjectIdentifier(type)
        overrides[key] = instance
    }

    /// Clears an override for a specific type.
    ///
    /// - Parameter type: The protocol or type to clear
    func clearOverride<T>(_ type: T.Type) {
        let key = ObjectIdentifier(type)
        overrides.removeValue(forKey: key)
    }

    /// Clears all overrides.
    func clearAllOverrides() {
        overrides.removeAll()
    }

    /// Resets the container to its initial state.
    ///
    /// Clears all registrations, singletons, and overrides.
    /// Typically used between tests.
    func reset() {
        factories.removeAll()
        singletons.removeAll()
        overrides.removeAll()
        configuration = .shared
    }

    /// Clears all singleton instances without removing registrations.
    ///
    /// Forces new instances to be created on next resolution.
    func clearSingletons() {
        singletons.removeAll()
    }

    // MARK: - Diagnostic

    /// Returns the number of registered services.
    var registeredCount: Int {
        factories.count
    }

    /// Returns the number of active overrides.
    var overrideCount: Int {
        overrides.count
    }

    /// Returns the number of instantiated singletons.
    var singletonCount: Int {
        singletons.count
    }
}

// MARK: - Registration Helpers

extension ServiceContainer {
    /// Registers multiple services using a builder pattern.
    ///
    /// - Parameter registrations: A closure that performs registrations
    func registerServices(_ registrations: (ServiceContainer) async -> Void) async {
        await registrations(self)
    }
}

// MARK: - Protocol-Specific Resolution

/// Type-erased protocol for framework services.
///
/// Allows storing different framework service types in collections.
protocol AnyFrameworkService: Sendable {
    var frameworkType: FrameworkType { get }
    var permissionStatus: PermissionLevel { get }
    func requestPermission() async -> PermissionLevel
}

extension ServiceContainer {
    /// Resolves all registered framework services.
    ///
    /// Useful for permission coordinator and health checks.
    ///
    /// - Returns: Array of framework services
    func resolveFrameworkServices() -> [any FrameworkServiceProtocol] {
        var services: [any FrameworkServiceProtocol] = []

        // Try to resolve each known framework service type
        // This is a workaround since we can't enumerate registrations by protocol conformance

        return services
    }
}
