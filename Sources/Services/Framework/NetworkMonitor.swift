//
//  NetworkMonitor.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Network Connectivity Monitoring
//  Wrapper around NWPathMonitor for observing network state
//

import Foundation
import Network

// MARK: - Connection Type

/// Type of network connection available.
enum ConnectionType: String, Sendable {
    /// WiFi connection
    case wifi

    /// Cellular data connection
    case cellular

    /// Wired ethernet connection
    case wired

    /// Local loopback (localhost)
    case loopback

    /// Unknown connection type
    case unknown

    /// No connection available
    case none
}

// MARK: - Network Status

/// Current network connectivity status.
struct NetworkStatus: Sendable, Equatable {
    /// Whether the device has network connectivity
    let isConnected: Bool

    /// Type of connection
    let connectionType: ConnectionType

    /// Whether the connection is expensive (cellular)
    let isExpensive: Bool

    /// Whether the connection is constrained (Low Data Mode)
    let isConstrained: Bool

    /// When this status was captured
    let timestamp: Date

    /// Default disconnected status
    static let disconnected = NetworkStatus(
        isConnected: false,
        connectionType: .none,
        isExpensive: false,
        isConstrained: false,
        timestamp: Date()
    )
}

// MARK: - Network Monitor Protocol

/// Protocol for network monitoring.
///
/// Enables mocking in tests.
protocol NetworkMonitorProtocol: Actor, Sendable {
    /// Current network status
    var currentStatus: NetworkStatus { get }

    /// Whether the device is currently connected
    var isConnected: Bool { get }

    /// Starts monitoring network changes
    func startMonitoring()

    /// Stops monitoring network changes
    func stopMonitoring()

    /// Async stream of connectivity changes
    var connectivityChanges: AsyncStream<NetworkStatus> { get }
}

// MARK: - Network Monitor

/// Monitors network connectivity using NWPathMonitor.
///
/// Provides current connectivity status and an async stream of changes.
/// Used by SyncService to determine when to process the sync queue.
///
/// ## Usage
///
/// ```swift
/// let monitor = NetworkMonitor()
/// await monitor.startMonitoring()
///
/// if await monitor.isConnected {
///     // Proceed with network operation
/// }
///
/// // Listen for changes
/// for await status in await monitor.connectivityChanges {
///     if status.isConnected {
///         await syncService.processQueue()
///     }
/// }
/// ```
actor NetworkMonitor: NetworkMonitorProtocol, FrameworkServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .network }

    nonisolated var isAvailable: Bool { true }

    var permissionStatus: PermissionLevel { .authorized }

    func requestPermission() async -> PermissionLevel { .authorized }

    // MARK: - State

    private var pathMonitor: NWPathMonitor?
    private var monitorQueue: DispatchQueue?
    private var _currentStatus: NetworkStatus = .disconnected
    private var continuation: AsyncStream<NetworkStatus>.Continuation?
    private var isMonitoring = false

    // MARK: - Initialization

    init() {}

    // MARK: - Current Status

    /// Current network status
    var currentStatus: NetworkStatus {
        _currentStatus
    }

    /// Whether the device is currently connected
    var isConnected: Bool {
        _currentStatus.isConnected
    }

    // MARK: - Monitoring

    /// Starts monitoring network changes
    func startMonitoring() {
        guard !isMonitoring else { return }

        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.personalai.networkmonitor", qos: .utility)

        monitor.pathUpdateHandler = { [weak self] path in
            _Concurrency.Task { [weak self] in
                await self?.handlePathUpdate(path)
            }
        }

        monitor.start(queue: queue)
        pathMonitor = monitor
        monitorQueue = queue
        isMonitoring = true
    }

    /// Stops monitoring network changes
    func stopMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
        monitorQueue = nil
        isMonitoring = false
    }

    private func handlePathUpdate(_ path: NWPath) {
        let status = NetworkStatus(
            isConnected: path.status == .satisfied,
            connectionType: connectionType(from: path),
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            timestamp: Date()
        )

        _currentStatus = status
        continuation?.yield(status)
    }

    private func connectionType(from path: NWPath) -> ConnectionType {
        guard path.status == .satisfied else {
            return .none
        }

        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .unknown
        }
    }

    // MARK: - Connectivity Changes Stream

    /// Async stream of connectivity changes
    var connectivityChanges: AsyncStream<NetworkStatus> {
        AsyncStream { continuation in
            self.continuation = continuation

            // Emit current status immediately
            continuation.yield(_currentStatus)

            // Start monitoring if not already
            if !isMonitoring {
                startMonitoring()
            }

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

    // MARK: - Service Protocol

    func initialize() async throws {
        startMonitoring()
    }

    func shutdown() async {
        stopMonitoring()
    }
}

// MARK: - Mock Network Monitor

/// Mock network monitor for testing and previews.
actor MockNetworkMonitor: NetworkMonitorProtocol {
    var currentStatus: NetworkStatus
    var isConnected: Bool { currentStatus.isConnected }

    init(isConnected: Bool = true) {
        self.currentStatus = NetworkStatus(
            isConnected: isConnected,
            connectionType: isConnected ? .wifi : .none,
            isExpensive: false,
            isConstrained: false,
            timestamp: Date()
        )
    }

    func startMonitoring() {}
    func stopMonitoring() {}

    func setConnected(_ connected: Bool) {
        currentStatus = NetworkStatus(
            isConnected: connected,
            connectionType: connected ? .wifi : .none,
            isExpensive: false,
            isConstrained: false,
            timestamp: Date()
        )
    }

    var connectivityChanges: AsyncStream<NetworkStatus> {
        AsyncStream { continuation in
            continuation.yield(currentStatus)
            continuation.finish()
        }
    }
}
