//
//  HealthKitService.swift
//  PersonalAI
//
//  Phase 3A Spec 2: HealthKit Framework Integration
//  Wrapper around HealthKit for reading health data
//

import Foundation
import HealthKit

// MARK: - HealthKit Service Protocol

/// Protocol for HealthKit services.
///
/// Enables mocking in tests.
protocol HealthKitServiceProtocol: FrameworkServiceProtocol {
    /// Gets the inferred energy level based on health data
    func getEnergyLevel() async -> EnergyLevel

    /// Gets activity context for the current day
    func getActivityContext() async -> ActivityContext

    /// Gets energy level with detailed breakdown (for debugging)
    func getEnergyBreakdown() async -> EnergyBreakdown

    /// Gets the most recent state of mind from HealthKit (iOS 18+)
    func getStateOfMind() async -> StateOfMindSnapshot?
}

// MARK: - HealthKit Service

/// Service for accessing health data via HealthKit.
///
/// Implements fail-soft pattern: returns default values on errors
/// or when data is unavailable. Used by ContextService to gather
/// health context.
///
/// ## Privacy
///
/// This service only reads health data; it never writes. Requests
/// read access to:
/// - Step count
/// - Active energy burned
/// - Sleep analysis
/// - Heart rate (for HRV calculation)
///
/// ## Performance
///
/// Health queries have a 100ms timeout. If queries take longer,
/// default values are returned.
actor HealthKitService: HealthKitServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .healthKit }

    nonisolated var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var permissionStatus: PermissionLevel {
        _permissionStatus
    }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - State

    private let healthStore: HKHealthStore
    private var _permissionStatus: PermissionLevel = .notDetermined

    // MARK: - HealthKit Types

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        // State of Mind (iOS 18+)
        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }
        return types
    }()

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
        self.healthStore = HKHealthStore()

        // Check if we've previously requested HealthKit permission
        if UserDefaults.standard.bool(forKey: "healthKitPermissionRequested") {
            _permissionStatus = .authorized
        }
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        guard isAvailable else {
            _permissionStatus = .restricted
            return .restricted
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            // For HealthKit read permissions, we can't determine if user actually granted access
            // (privacy protection). We assume permission was requested successfully and treat
            // it as authorized. The actual data queries will fail silently if denied.
            _permissionStatus = .authorized

            // Persist that we've requested permission
            UserDefaults.standard.set(true, forKey: "healthKitPermissionRequested")

            return .authorized
        } catch {
            _permissionStatus = .denied
            return .denied
        }
    }

    // MARK: - Energy Level

    /// Gets the inferred energy level based on health data.
    ///
    /// Combines sleep quality, activity level, and time of day
    /// to estimate current energy. Returns `.medium` as default.
    func getEnergyLevel() async -> EnergyLevel {
        guard isAvailable, permissionStatus.allowsAccess else {
            return .medium
        }

        let timeout = configuration.timeouts.frameworkOperation

        return await withTimeout(timeout, default: .medium) {
            await self.calculateEnergyLevel()
        }
    }

    /// Gets energy level with detailed breakdown for debugging.
    ///
    /// Returns the individual components (sleep, activity, time) that
    /// contribute to the final energy level calculation.
    func getEnergyBreakdown() async -> EnergyBreakdown {
        guard isAvailable, permissionStatus.allowsAccess else {
            return EnergyBreakdown(
                sleepScore: 0.5,
                activityScore: 0.5,
                hrvScore: 0.5,
                timeBonus: timeOfDayEnergyBonus(),
                totalScore: 0.5,
                level: .medium,
                hrvValueMs: nil,
                sleepHours: nil,
                stepCount: nil
            )
        }

        let timeout = configuration.timeouts.frameworkOperation
        let defaultBreakdown = EnergyBreakdown(
            sleepScore: 0.5,
            activityScore: 0.5,
            hrvScore: 0.5,
            timeBonus: timeOfDayEnergyBonus(),
            totalScore: 0.5,
            level: .medium,
            hrvValueMs: nil,
            sleepHours: nil,
            stepCount: nil
        )

        return await withTimeout(timeout, default: defaultBreakdown) {
            await self.calculateEnergyBreakdown()
        }
    }

    private func calculateEnergyLevel() async -> EnergyLevel {
        let breakdown = await calculateEnergyBreakdown()
        return breakdown.level
    }

    private func calculateEnergyBreakdown() async -> EnergyBreakdown {
        async let sleepData = getSleepQualityWithHours()
        async let activityData = getActivityLevelWithSteps()
        async let hrvData = getHRVScoreWithValue()

        let (sleepScore, sleepHours) = await sleepData
        let (activityScore, stepCount) = await activityData
        let (hrvScore, hrvValue) = await hrvData

        // Weighted score: sleep (40%), activity (25%), HRV (20%), time bonus (15%)
        let timeBonus = timeOfDayEnergyBonus()
        let score = (sleepScore * 0.4) + (activityScore * 0.25) + (hrvScore * 0.2) + (timeBonus * 0.15)

        return EnergyBreakdown(
            sleepScore: sleepScore,
            activityScore: activityScore,
            hrvScore: hrvScore,
            timeBonus: timeBonus,
            totalScore: score,
            level: EnergyLevel.from(score: score),
            hrvValueMs: hrvValue,
            sleepHours: sleepHours,
            stepCount: stepCount
        )
    }

    private func getSleepQuality() async -> Double {
        let (score, _) = await getSleepQualityWithHours()
        return score
    }

    private func getSleepQualityWithHours() async -> (score: Double, hours: Double?) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0.5, nil)
        }

        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let startOfYesterday = calendar.startOfDay(for: yesterday)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfYesterday,
            end: now,
            options: .strictStartDate
        )

        do {
            let samples = try await fetchSamples(type: sleepType, predicate: predicate)
            let sleepHours = calculateSleepHours(from: samples)

            // Score based on hours: <6 = 0.3, 6-7 = 0.6, 7-9 = 1.0, >9 = 0.8
            let score: Double
            switch sleepHours {
            case ..<6: score = 0.3
            case 6..<7: score = 0.6
            case 7..<9: score = 1.0
            default: score = 0.8
            }
            return (score, sleepHours)
        } catch {
            return (0.5, nil)
        }
    }

    private func getActivityLevel() async -> Double {
        let (score, _) = await getActivityLevelWithSteps()
        return score
    }

    private func getActivityLevelWithSteps() async -> (score: Double, steps: Int?) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return (0.5, nil)
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        do {
            let steps = try await fetchStatistics(type: stepType, predicate: predicate)
            let stepCount = Int(steps)

            // Normalize: 0 steps = 0.0, 10000+ steps = 1.0
            let normalized = min(steps / 10000.0, 1.0)
            return (normalized, stepCount)
        } catch {
            return (0.5, nil)
        }
    }

    private func getHRVScore() async -> Double {
        let (score, _) = await getHRVScoreWithValue()
        return score
    }

    private func getHRVScoreWithValue() async -> (score: Double, hrvMs: Double?) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return (0.5, nil)
        }

        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let startOfYesterday = calendar.startOfDay(for: yesterday)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfYesterday,
            end: now,
            options: .strictStartDate
        )

        do {
            let samples = try await fetchSamples(type: hrvType, predicate: predicate)
            guard !samples.isEmpty else { return (0.5, nil) }

            // Calculate average HRV from recent samples
            let hrvValues = samples.compactMap { sample -> Double? in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                return quantitySample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }

            guard !hrvValues.isEmpty else { return (0.5, nil) }
            let avgHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)

            // Score based on HRV (ms):
            // Higher HRV = better recovery and energy
            // <20ms = 0.2 (very poor recovery)
            // 20-40ms = 0.5 (below average)
            // 40-60ms = 0.7 (average)
            // 60-80ms = 0.9 (good)
            // >80ms = 1.0 (excellent)
            let score: Double
            switch avgHRV {
            case ..<20: score = 0.2
            case 20..<40: score = 0.5
            case 40..<60: score = 0.7
            case 60..<80: score = 0.9
            default: score = 1.0
            }
            return (score, avgHRV)
        } catch {
            return (0.5, nil)
        }
    }

    private func timeOfDayEnergyBonus() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())

        // Peak energy typically mid-morning and mid-afternoon
        switch hour {
        case 9..<12: return 1.0   // Mid-morning peak
        case 14..<17: return 0.9  // Afternoon peak
        case 7..<9: return 0.7    // Morning ramp-up
        case 17..<20: return 0.6  // Evening decline
        default: return 0.4       // Night/early morning low
        }
    }

    // MARK: - Activity Context

    /// Gets activity context for the current day.
    ///
    /// Returns step count, calories burned, and active minutes.
    /// Returns zeros if data is unavailable.
    func getActivityContext() async -> ActivityContext {
        guard isAvailable, permissionStatus.allowsAccess else {
            return ActivityContext(stepCount: 0, caloriesBurned: 0, activeMinutes: 0)
        }

        let timeout = configuration.timeouts.frameworkOperation
        let defaultContext = ActivityContext(stepCount: 0, caloriesBurned: 0, activeMinutes: 0)

        return await withTimeout(timeout, default: defaultContext) {
            await self.fetchActivityContext()
        }
    }

    /// Gets the most recent state of mind from HealthKit.
    ///
    /// Queries for the most recent HKStateOfMind sample from the last hour.
    /// Returns nil if data is unavailable, unauthorized, or on iOS < 18.
    ///
    /// - Returns: StateOfMindSnapshot or nil
    @available(iOS 18.0, *)
    func getStateOfMind() async -> StateOfMindSnapshot? {
        guard isAvailable, permissionStatus.allowsAccess else {
            return nil
        }

        let timeout = configuration.timeouts.frameworkOperation

        return await withTimeout(timeout, default: nil) {
            await self.fetchStateOfMind()
        }
    }

    @available(iOS 18.0, *)
    private func fetchStateOfMind() async -> StateOfMindSnapshot? {
        let stateOfMindType = HKObjectType.stateOfMindType()

        // Query for samples from the last hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let predicate = HKQuery.predicateForSamples(
            withStart: oneHourAgo,
            end: Date(),
            options: .strictStartDate
        )

        // Sort by start date descending to get most recent first
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        do {
            let samples = try await fetchSamples(
                type: stateOfMindType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            )

            guard let stateOfMind = samples.first as? HKStateOfMind else {
                return nil
            }

            // Convert HKStateOfMind to our StateOfMindSnapshot
            let classification = StateOfMindSnapshot.ValenceClassification.from(
                valence: stateOfMind.valence
            )

            // Extract labels (convert from HKStateOfMind.Label to String)
            let labels = stateOfMind.labels.map { $0.rawValue }

            // Extract associations (convert from HKStateOfMind.Association to String)
            let associations = stateOfMind.associations.map { $0.rawValue }

            return StateOfMindSnapshot(
                valence: stateOfMind.valence,
                classification: classification,
                labels: labels,
                associations: associations
            )

        } catch {
            NSLog("⚠️ Failed to fetch state of mind: \(error)")
            return nil
        }
    }

    private func fetchActivityContext() async -> ActivityContext {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        // Create separate predicates for parallel execution to avoid data race
        let stepsPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
        let caloriesPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        async let steps = fetchStepCount(predicate: stepsPredicate)
        async let calories = fetchCalories(predicate: caloriesPredicate)

        let stepCount = await steps
        return ActivityContext(
            stepCount: stepCount,
            caloriesBurned: await calories,
            activeMinutes: stepCount / 100 // Rough estimate
        )
    }

    private func fetchStepCount(predicate: NSPredicate) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        do {
            let steps = try await fetchStatistics(type: stepType, predicate: predicate)
            return Int(steps)
        } catch {
            return 0
        }
    }

    private func fetchCalories(predicate: NSPredicate) async -> Double {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        do {
            return try await fetchStatistics(type: calorieType, predicate: predicate)
        } catch {
            return 0
        }
    }

    // MARK: - Query Helpers

    private func fetchSamples(type: HKSampleType, predicate: NSPredicate) async throws -> [HKSample] {
        try await fetchSamples(
            type: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        )
    }

    private func fetchSamples(
        type: HKSampleType,
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchStatistics(type: HKQuantityType, predicate: NSPredicate) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let unit = self.unit(for: type)
                    let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                    continuation.resume(returning: value)
                }
            }
            healthStore.execute(query)
        }
    }

    private nonisolated func unit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return .count()
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return .kilocalorie()
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        default:
            return .count()
        }
    }

    private func calculateSleepHours(from samples: [HKSample]) -> Double {
        var totalSeconds: TimeInterval = 0

        for sample in samples {
            if let categorySample = sample as? HKCategorySample {
                // Only count asleep samples (not inBed)
                if categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSeconds += categorySample.endDate.timeIntervalSince(categorySample.startDate)
                }
            }
        }

        return totalSeconds / 3600.0 // Convert to hours
    }

    // MARK: - Timeout Helper

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

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        // No cleanup needed
    }
}

// MARK: - Energy Level Extension

extension EnergyLevel {
    /// Creates an energy level from a normalized score (0.0-1.0)
    static func from(score: Double) -> EnergyLevel {
        switch score {
        case ..<0.33: return .low
        case 0.33..<0.66: return .medium
        case 0.66..<0.85: return .high
        default: return .peak
        }
    }
}

// MARK: - Mock HealthKit Service

/// Mock HealthKit service for testing and previews.
actor MockHealthKitService: HealthKitServiceProtocol {
    nonisolated var frameworkType: FrameworkType { .healthKit }
    nonisolated var isAvailable: Bool { true }
    var permissionStatus: PermissionLevel

    var mockEnergyLevel: EnergyLevel
    var mockActivityContext: ActivityContext

    init(
        permissionStatus: PermissionLevel = .authorized,
        energyLevel: EnergyLevel = .medium,
        activityContext: ActivityContext = ActivityContext(stepCount: 5000, caloriesBurned: 200, activeMinutes: 30)
    ) {
        self.permissionStatus = permissionStatus
        self.mockEnergyLevel = energyLevel
        self.mockActivityContext = activityContext
    }

    func requestPermission() async -> PermissionLevel {
        permissionStatus = .authorized
        return .authorized
    }

    func getEnergyLevel() async -> EnergyLevel {
        mockEnergyLevel
    }

    func getActivityContext() async -> ActivityContext {
        mockActivityContext
    }

    func getEnergyBreakdown() async -> EnergyBreakdown {
        EnergyBreakdown(
            sleepScore: 0.8,
            activityScore: 0.6,
            hrvScore: 0.75,
            timeBonus: 0.9,
            totalScore: 0.74,
            level: mockEnergyLevel,
            hrvValueMs: 58.3,
            sleepHours: 7.5,
            stepCount: 6000
        )
    }

    func getStateOfMind() async -> StateOfMindSnapshot? {
        // Return a mock pleasant state for testing
        StateOfMindSnapshot(
            valence: 0.5,
            classification: .slightlyPleasant,
            labels: ["calm", "focused"],
            associations: ["work", "health"]
        )
    }
}
