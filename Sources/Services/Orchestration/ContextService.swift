//
//  ContextService.swift
//  STASH
//
//  Phase 3A Spec 2: Context Gathering Service
//  Orchestrates parallel context gathering from multiple sources
//

import Foundation

// MARK: - Context Gathering Metrics

/// Performance metrics from context gathering.
struct ContextGatheringMetrics: Sendable {
    /// Total time to gather all context
    let totalDurationMs: Int

    /// Time for location lookup
    let locationDurationMs: Int?

    /// Time for HealthKit queries
    let healthKitDurationMs: Int?

    /// Time for motion queries
    let motionDurationMs: Int?

    /// Time for calendar queries
    let eventKitDurationMs: Int?

    /// Number of sources that timed out
    let timeoutCount: Int

    /// Number of sources that failed
    let failureCount: Int

    /// When these metrics were captured
    let timestamp: Date
}

// MARK: - Context Component

/// Internal enum for aggregating context data from parallel operations.
private enum ContextComponent: Sendable {
    case location(Location?)
    case energy(EnergyLevel)
    case energyBreakdown(EnergyBreakdown)
    case activity(ActivityContext)
    case calendar(CalendarContext)
    case stateOfMind(StateOfMindSnapshot?)
}

// MARK: - Context Service Protocol

/// Protocol for context services.
///
/// Enables mocking in tests.
protocol ContextServiceProtocol: OrchestrationServiceProtocol {
    /// Gathers context from all available sources
    func gatherContext() async -> Context

    /// Gathers context with performance diagnostics
    func gatherContextWithDiagnostics() async -> (Context, ContextGatheringMetrics)
}

// MARK: - Context Service

/// Orchestration service for gathering context from multiple sources.
///
/// Coordinates parallel data gathering from:
/// - Location services
/// - HealthKit
/// - Motion/Activity
/// - Calendar/EventKit
///
/// ## Performance Target
///
/// Context gathering must complete in <300ms. Individual operations
/// have 100ms timeouts and return default values if they exceed this.
///
/// ## Fail-Soft Design
///
/// If any source fails or times out, a default value is used and
/// gathering continues. The resulting Context always has values for
/// all fields, even if some are defaults.
actor ContextService: ContextServiceProtocol {
    // MARK: - Dependencies

    private let locationService: LocationServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let motionService: MotionServiceProtocol
    private let eventKitService: EventKitServiceProtocol
    let configuration: ServiceConfiguration

    // MARK: - Initialization

    init(
        locationService: LocationServiceProtocol,
        healthKitService: HealthKitServiceProtocol,
        motionService: MotionServiceProtocol,
        eventKitService: EventKitServiceProtocol,
        configuration: ServiceConfiguration = .shared
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.motionService = motionService
        self.eventKitService = eventKitService
        self.configuration = configuration
    }

    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Context Gathering

    /// Gathers context from all available sources.
    ///
    /// Executes all context queries in parallel with individual timeouts.
    /// Returns a complete Context with default values for any failed queries.
    ///
    /// - Returns: Complete context (always succeeds, may have defaults)
    func gatherContext() async -> Context {
        let (context, _) = await gatherContextWithDiagnostics()
        return context
    }

    /// Gathers context with performance diagnostics.
    ///
    /// Same as `gatherContext()` but also returns metrics about
    /// how long each operation took.
    func gatherContextWithDiagnostics() async -> (Context, ContextGatheringMetrics) {
        let startTime = Date()
        let timeout = configuration.timeouts.frameworkOperation
        var results = GatheringResults()

        await withTaskGroup(of: (ContextComponent, Int, Bool).self) { group in
            group.addTask { await self.gatherLocation(timeout: timeout) }
            group.addTask { await self.gatherEnergyBreakdown(timeout: timeout) }
            group.addTask { await self.gatherActivity(timeout: timeout) }
            group.addTask { await self.gatherCalendar(timeout: timeout) }
            if #available(iOS 18.0, *) {
                group.addTask { await self.gatherStateOfMind(timeout: timeout) }
            }
            for await (component, duration, timedOut) in group {
                results.apply(component: component, duration: duration, timedOut: timedOut)
            }
        }

        return results.assembled(startedAt: startTime)
    }

    // MARK: - Per-Source Gathering

    private func gatherLocation(timeout: TimeInterval) async -> (ContextComponent, Int, Bool) {
        let opStart = Date()
        let rawResult = await ConcurrencyUtilities.withTimeout(timeout) {
            await self.locationService.getCurrentLocation()
        }
        let result: Location? = rawResult ?? nil
        let duration = Int(Date().timeIntervalSince(opStart) * 1000)
        let location: Location? = result ?? nil
        let timedOut = location == nil && duration >= Int(timeout * 1000)
        return (.location(location), duration, timedOut)
    }

    private func gatherEnergyBreakdown(timeout: TimeInterval) async -> (ContextComponent, Int, Bool) {
        let opStart = Date()
        let defaultBreakdown = EnergyBreakdown(
            sleepScore: 0.5, activityScore: 0.5, hrvScore: 0.5,
            timeBonus: 0.5, totalScore: 0.5, level: .medium,
            hrvValueMs: nil, sleepHours: nil, stepCount: nil
        )
        let result = await ConcurrencyUtilities.withTimeout(timeout, default: defaultBreakdown) {
            await self.healthKitService.getEnergyBreakdown()
        }
        let duration = Int(Date().timeIntervalSince(opStart) * 1000)
        let timedOut = duration >= Int(timeout * 1000)
        return (.energyBreakdown(result), duration, timedOut)
    }

    private func gatherActivity(timeout: TimeInterval) async -> (ContextComponent, Int, Bool) {
        let opStart = Date()
        let defaultActivity = ActivityContext(stepCount: 0, caloriesBurned: 0, activeMinutes: 0)
        let result = await ConcurrencyUtilities.withTimeout(timeout, default: defaultActivity) {
            await self.healthKitService.getActivityContext()
        }
        let duration = Int(Date().timeIntervalSince(opStart) * 1000)
        let timedOut = duration >= Int(timeout * 1000)
        return (.activity(result), duration, timedOut)
    }

    private func gatherCalendar(timeout: TimeInterval) async -> (ContextComponent, Int, Bool) {
        let opStart = Date()
        let defaultCalendar = CalendarContext(nextEventMinutes: nil, isFreetime: true, eventCount: 0)
        let result = await ConcurrencyUtilities.withTimeout(timeout, default: defaultCalendar) {
            await self.eventKitService.getAvailability()
        }
        let duration = Int(Date().timeIntervalSince(opStart) * 1000)
        let timedOut = duration >= Int(timeout * 1000)
        return (.calendar(result), duration, timedOut)
    }

    @available(iOS 18.0, *)
    private func gatherStateOfMind(timeout: TimeInterval) async -> (ContextComponent, Int, Bool) {
        let opStart = Date()
        let result = await ConcurrencyUtilities.withTimeout(timeout, default: nil) {
            await self.healthKitService.getStateOfMind()
        }
        let duration = Int(Date().timeIntervalSince(opStart) * 1000)
        let timedOut = duration >= Int(timeout * 1000)
        return (.stateOfMind(result), duration, timedOut)
    }
}

// MARK: - Gathering Results

/// Mutable accumulator for parallel context gathering results.
private struct GatheringResults {
    var location: Location? = nil
    var energy: EnergyLevel = .medium
    var energyBreakdown: EnergyBreakdown? = nil
    var activity: ActivityContext = ActivityContext(stepCount: 0, caloriesBurned: 0, activeMinutes: 0)
    var calendar: CalendarContext = CalendarContext(nextEventMinutes: nil, isFreetime: true, eventCount: 0)
    var stateOfMind: StateOfMindSnapshot? = nil
    var locationDuration: Int? = nil
    var healthKitDuration: Int? = nil
    var motionDuration: Int? = nil
    var eventKitDuration: Int? = nil
    var timeoutCount: Int = 0

    mutating func apply(component: ContextComponent, duration: Int, timedOut: Bool) {
        if timedOut { timeoutCount += 1 }
        switch component {
        case .location(let loc):
            location = loc
            locationDuration = duration
        case .energy(let e):
            energy = e // Legacy path — energyBreakdown replaces this in practice
        case .energyBreakdown(let eb):
            energyBreakdown = eb
            energy = eb.level
            healthKitDuration = duration
        case .activity(let a):
            activity = a
            motionDuration = duration
        case .calendar(let c):
            calendar = c
            eventKitDuration = duration
        case .stateOfMind(let som):
            stateOfMind = som
            // Duration tracked under healthKitDuration
        }
    }

    func assembled(startedAt startTime: Date) -> (Context, ContextGatheringMetrics) {
        let now = Date()
        let context = Context(
            timestamp: now,
            location: location,
            timeOfDay: TimeOfDay.from(date: now),
            energy: energy,
            focusState: .scattered, // Will be inferred from usage patterns in a future phase
            calendar: calendar,
            activity: activity,
            weather: nil, // Weather API not yet integrated
            stateOfMind: stateOfMind,
            energyBreakdown: energyBreakdown
        )
        let metrics = ContextGatheringMetrics(
            totalDurationMs: Int(now.timeIntervalSince(startTime) * 1000),
            locationDurationMs: locationDuration,
            healthKitDurationMs: healthKitDuration,
            motionDurationMs: motionDuration,
            eventKitDurationMs: eventKitDuration,
            timeoutCount: timeoutCount,
            failureCount: 0,
            timestamp: now
        )
        return (context, metrics)
    }
}

// MARK: - Mock Context Service

/// Mock context service for testing and previews.
actor MockContextService: ContextServiceProtocol {
    nonisolated var isAvailable: Bool { true }
    let configuration: ServiceConfiguration

    var mockContext: Context
    var gatherCallCount = 0

    init(
        configuration: ServiceConfiguration = .shared,
        context: Context? = nil
    ) {
        self.configuration = configuration
        self.mockContext = context ?? Context(
            timestamp: Date(),
            location: Location(latitude: 37.7749, longitude: -122.4194, name: "San Francisco", geofenceId: nil),
            timeOfDay: .afternoon,
            energy: .high,
            focusState: .deep_work,
            calendar: CalendarContext(nextEventMinutes: 60, isFreetime: true, eventCount: 3),
            activity: ActivityContext(stepCount: 5000, caloriesBurned: 200, activeMinutes: 30),
            weather: nil,
            stateOfMind: StateOfMindSnapshot(
                valence: 0.6,
                classification: .slightlyPleasant,
                labels: ["calm", "focused"],
                associations: ["work"]
            ),
            energyBreakdown: EnergyBreakdown(
                sleepScore: 0.8,
                activityScore: 0.6,
                hrvScore: 0.75,
                timeBonus: 0.9,
                totalScore: 0.74,
                level: .high,
                hrvValueMs: 58.3,
                sleepHours: 7.5,
                stepCount: 6000
            )
        )
    }

    func gatherContext() async -> Context {
        gatherCallCount += 1
        return mockContext
    }

    func gatherContextWithDiagnostics() async -> (Context, ContextGatheringMetrics) {
        gatherCallCount += 1
        let metrics = ContextGatheringMetrics(
            totalDurationMs: 150,
            locationDurationMs: 50,
            healthKitDurationMs: 40,
            motionDurationMs: 30,
            eventKitDurationMs: 45,
            timeoutCount: 0,
            failureCount: 0,
            timestamp: Date()
        )
        return (mockContext, metrics)
    }
}
