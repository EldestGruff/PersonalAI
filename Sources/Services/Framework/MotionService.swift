//
//  MotionService.swift
//  STASH
//
//  Phase 3A Spec 2: Core Motion Framework Integration
//  Wrapper around CoreMotion for activity and step data
//

import Foundation
import CoreMotion

// MARK: - Motion Service Protocol

/// Protocol for motion services.
///
/// Enables mocking in tests.
protocol MotionServiceProtocol: FrameworkServiceProtocol {
    /// Gets the step count for today
    func getStepCount() async -> Int

    /// Gets the normalized activity level (0.0-1.0)
    func getActivityLevel() async -> Double
}

// MARK: - Motion Service

/// Service for accessing motion data via CoreMotion.
///
/// CoreMotion provides step counting and activity recognition without
/// requiring explicit user permission (unlike HealthKit). This makes it
/// useful as a supplementary data source.
///
/// ## Availability
///
/// Pedometer functionality requires:
/// - Device with motion coprocessor (M-series chip)
/// - iOS 8.0+
///
/// ## Platform Notes
///
/// CMMotionActivityManager is unavailable on macOS. This service
/// falls back to default values when running on macOS.
///
/// ## Performance
///
/// Motion queries typically return quickly, but a 100ms timeout is
/// enforced to meet context gathering targets.
actor MotionService: MotionServiceProtocol {
    // MARK: - Singleton

    static let shared = MotionService()

    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .coreMotion }

    nonisolated var isAvailable: Bool {
        #if os(iOS) || os(watchOS)
        return CMPedometer.isStepCountingAvailable()
        #else
        return false
        #endif
    }

    var permissionStatus: PermissionLevel {
        // CoreMotion doesn't require explicit permission
        // If pedometer is available, we can use it
        isAvailable ? .authorized : .restricted
    }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - State

    #if os(iOS) || os(watchOS)
    private let pedometer: CMPedometer
    #endif

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
        #if os(iOS) || os(watchOS)
        self.pedometer = CMPedometer()
        #endif
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        // CoreMotion automatically triggers permission on first use
        // Just return current status
        return permissionStatus
    }

    // MARK: - Step Count

    /// Gets the step count for today.
    ///
    /// Returns 0 if:
    /// - Pedometer is not available
    /// - Query fails
    /// - Operation times out
    /// - Running on macOS
    func getStepCount() async -> Int {
        #if os(iOS) || os(watchOS)
        guard isAvailable else { return 0 }

        let timeout = configuration.timeouts.frameworkOperation

        return await withTimeout(timeout, default: 0) {
            await self.fetchStepCount()
        }
        #else
        return 0
        #endif
    }

    #if os(iOS) || os(watchOS)
    private func fetchStepCount() async -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: startOfDay, to: Date()) { data, error in
                if let error = error {
                    // Log but don't throw - fail soft
                    AppLogger.warning("Motion: step count query failed", category: .context)
                    continuation.resume(returning: 0)
                } else if let data = data {
                    continuation.resume(returning: data.numberOfSteps.intValue)
                } else {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    #endif

    // MARK: - Activity Level

    /// Gets the normalized activity level (0.0-1.0).
    ///
    /// Calculated from step count relative to a 10,000 step goal.
    /// Returns 0.5 as default if data is unavailable.
    func getActivityLevel() async -> Double {
        let steps = await getStepCount()

        // Normalize: 0 steps = 0.0, 10000+ steps = 1.0
        let normalized = Double(steps) / 10000.0
        return min(normalized, 1.0)
    }

    // MARK: - Timeout Helper

    #if os(iOS) || os(watchOS)
    private func withTimeout<T: Sendable>(_ timeout: TimeInterval, default defaultValue: T, operation: @Sendable @escaping () async -> T) async -> T {
        await withTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return defaultValue
            }

            // First result wins
            for await result in group {
                group.cancelAll()
                return result
            }

            return defaultValue
        }
    }
    #endif

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        #if os(iOS) || os(watchOS)
        pedometer.stopUpdates()
        #endif
    }
}

// MARK: - Mock Motion Service

/// Mock motion service for testing and previews.
actor MockMotionService: MotionServiceProtocol {
    nonisolated var frameworkType: FrameworkType { .coreMotion }
    nonisolated var isAvailable: Bool { true }
    var permissionStatus: PermissionLevel { .authorized }

    var mockStepCount: Int
    var mockActivityLevel: Double

    init(stepCount: Int = 5000, activityLevel: Double = 0.5) {
        self.mockStepCount = stepCount
        self.mockActivityLevel = activityLevel
    }

    func requestPermission() async -> PermissionLevel {
        .authorized
    }

    func getStepCount() async -> Int {
        mockStepCount
    }

    func getActivityLevel() async -> Double {
        mockActivityLevel
    }
}
