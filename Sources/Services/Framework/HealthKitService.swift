//
//  HealthKitService.swift
//  STASH
//
//  Phase 3A Spec 2: HealthKit Framework Integration
//  Wrapper around HealthKit for reading health data
//

import Foundation
import HealthKit

// MARK: - Historical Health Data Structures

/// Sleep data for a specific date
struct DailySleepData: Sendable {
    let date: Date
    let totalSleepHours: Double
    let timeInBedHours: Double
    let sleepQuality: Double  // 0.0 - 1.0 based on sleep stages ratio
    let deepSleepHours: Double
    let remSleepHours: Double
    let coreSleepHours: Double
}

/// HRV data for a specific date
struct DailyHRVData: Sendable {
    let date: Date
    let averageHRV: Double  // SDNN in milliseconds
    let minHRV: Double
    let maxHRV: Double
    let sampleCount: Int
    let recoveryIndicator: HRVRecoveryIndicator
}

/// HRV recovery indicator based on daily average
enum HRVRecoveryIndicator: String, Sendable {
    case poor = "poor"           // < 30ms
    case belowAverage = "below_average"  // 30-50ms
    case average = "average"     // 50-70ms
    case good = "good"           // 70-90ms
    case excellent = "excellent" // > 90ms

    static func from(hrv: Double) -> HRVRecoveryIndicator {
        switch hrv {
        case ..<30: return .poor
        case 30..<50: return .belowAverage
        case 50..<70: return .average
        case 70..<90: return .good
        default: return .excellent
        }
    }
}

/// Workout data for a specific date
struct DailyWorkoutData: Sendable {
    let date: Date
    let totalWorkoutMinutes: Int
    let totalCaloriesBurned: Double
    let workoutCount: Int
    let workoutTypes: [String]
    let averageHeartRate: Double?
}

/// Resting heart rate data for a specific date
struct DailyRestingHRData: Sendable {
    let date: Date
    let restingHeartRate: Double  // BPM
    let trend: HeartRateTrend
}

/// Heart rate trend compared to baseline
enum HeartRateTrend: String, Sendable {
    case elevated = "elevated"    // > 5 BPM above baseline
    case normal = "normal"        // within 5 BPM of baseline
    case low = "low"              // > 5 BPM below baseline
}

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

    // MARK: - Historical Data Queries

    /// Gets historical sleep data for a date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of daily sleep data, one entry per day
    func getHistoricalSleepData(from startDate: Date, to endDate: Date) async -> [DailySleepData]

    /// Gets historical HRV data for a date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of daily HRV data, one entry per day
    func getHistoricalHRVData(from startDate: Date, to endDate: Date) async -> [DailyHRVData]

    /// Gets historical workout data for a date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of daily workout data, one entry per day
    func getHistoricalWorkoutData(from startDate: Date, to endDate: Date) async -> [DailyWorkoutData]

    /// Gets historical resting heart rate data for a date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of daily resting HR data, one entry per day
    func getHistoricalRestingHRData(from startDate: Date, to endDate: Date) async -> [DailyRestingHRData]

    /// Gets historical step count data for a date range
    /// - Parameters:
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Dictionary mapping dates to step counts
    func getHistoricalStepData(from startDate: Date, to endDate: Date) async -> [Date: Int]
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

        // MARK: Activity & Fitness
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let cycling = HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
            types.insert(cycling)
        }
        if let swimming = HKQuantityType.quantityType(forIdentifier: .distanceSwimming) {
            types.insert(swimming)
        }
        if let flightsClimbed = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            types.insert(flightsClimbed)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let basalEnergy = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(basalEnergy)
        }
        if let exerciseTime = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseTime)
        }
        if let standTime = HKQuantityType.quantityType(forIdentifier: .appleStandTime) {
            types.insert(standTime)
        }
        types.insert(HKObjectType.workoutType())

        // MARK: Heart & Cardiovascular
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHR)
        }
        if let walkingHR = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage) {
            types.insert(walkingHR)
        }
        if let vo2Max = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
            types.insert(vo2Max)
        }

        // MARK: Sleep
        if let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }

        // MARK: Mindfulness & Mental Health
        if let mindfulMinutes = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulMinutes)
        }
        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }

        // MARK: Nutrition (MyFitnessPal-style tracking)
        if let dietaryEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(dietaryEnergy)
        }
        if let protein = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            types.insert(protein)
        }
        if let carbs = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            types.insert(carbs)
        }
        if let fat = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            types.insert(fat)
        }
        if let sugar = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
            types.insert(sugar)
        }
        if let fiber = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            types.insert(fiber)
        }
        if let sodium = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
            types.insert(sodium)
        }
        if let water = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }
        if let caffeine = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) {
            types.insert(caffeine)
        }

        // MARK: Body Measurements
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFat)
        }
        if let leanMass = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) {
            types.insert(leanMass)
        }
        if let height = HKQuantityType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let bmi = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) {
            types.insert(bmi)
        }
        if let waist = HKQuantityType.quantityType(forIdentifier: .waistCircumference) {
            types.insert(waist)
        }

        // MARK: Vitals
        if let oxygenSat = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(oxygenSat)
        }
        if let bloodPressureSystolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(bloodPressureSystolic)
        }
        if let bloodPressureDiastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(bloodPressureDiastolic)
        }
        if let respiratoryRate = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }
        if let bodyTemp = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }
        if let bloodGlucose = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) {
            types.insert(bloodGlucose)
        }

        // MARK: Reproductive Health
        if let basalBodyTemp = HKQuantityType.quantityType(forIdentifier: .basalBodyTemperature) {
            types.insert(basalBodyTemp)
        }
        if let menstruation = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) {
            types.insert(menstruation)
        }

        // MARK: Hearing
        if let headphoneAudio = HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure) {
            types.insert(headphoneAudio)
        }
        if let envAudio = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) {
            types.insert(envAudio)
        }

        // MARK: Medications (iOS 16+)
        // Note: Medication tracking uses HKUserAnnotatedMedicationQueryDescriptor
        // which requires per-object authorization (requested at query time)
        // No types to add here - medications handled separately

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
            let labels = stateOfMind.labels.map { label in
                // HKStateOfMind.Label is an enum with descriptive string values
                switch label {
                case .amazed: return "amazed"
                case .amused: return "amused"
                case .anxious: return "anxious"
                case .calm: return "calm"
                case .content: return "content"
                case .disappointed: return "disappointed"
                case .excited: return "excited"
                case .frustrated: return "frustrated"
                case .grateful: return "grateful"
                case .happy: return "happy"
                case .irritated: return "irritated"
                case .sad: return "sad"
                case .scared: return "scared"
                case .stressed: return "stressed"
                case .worried: return "worried"
                @unknown default: return "unknown"
                }
            }

            // Extract associations (convert from HKStateOfMind.Association to String)
            let associations = stateOfMind.associations.map { association in
                switch association {
                case .community: return "community"
                case .currentEvents: return "currentEvents"
                case .dating: return "dating"
                case .education: return "education"
                case .family: return "family"
                case .fitness: return "fitness"
                case .friends: return "friends"
                case .health: return "health"
                case .hobbies: return "hobbies"
                case .identity: return "identity"
                case .money: return "money"
                case .partner: return "partner"
                case .selfCare: return "selfCare"
                case .spirituality: return "spirituality"
                case .tasks: return "tasks"
                case .travel: return "travel"
                case .weather: return "weather"
                case .work: return "work"
                @unknown default: return "unknown"
                }
            }

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

    private nonisolated func fetchSamples(type: HKSampleType, predicate: NSPredicate) async throws -> [HKSample] {
        try await fetchSamples(
            type: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        )
    }

    private nonisolated func fetchSamples(
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

    // MARK: - Historical Data Queries

    /// Gets historical sleep data for a date range
    func getHistoricalSleepData(from startDate: Date, to endDate: Date) async -> [DailySleepData] {
        guard isAvailable, permissionStatus.allowsAccess else {
            return []
        }

        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }

        let calendar = Calendar.current
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        do {
            let samples = try await fetchSamples(type: sleepType, predicate: predicate)

            // Group samples by day (using the end date as the sleep night)
            var dailyData: [Date: (inBed: TimeInterval, asleep: TimeInterval, deep: TimeInterval, rem: TimeInterval, core: TimeInterval)] = [:]

            for sample in samples {
                guard let categorySample = sample as? HKCategorySample else { continue }

                // Use the end date to determine which "sleep night" this belongs to
                let sleepDate = calendar.startOfDay(for: categorySample.endDate)
                let duration = categorySample.endDate.timeIntervalSince(categorySample.startDate)

                var existing = dailyData[sleepDate] ?? (inBed: 0, asleep: 0, deep: 0, rem: 0, core: 0)

                switch categorySample.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    existing.inBed += duration
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    existing.asleep += duration
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    existing.deep += duration
                    existing.asleep += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    existing.rem += duration
                    existing.asleep += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    existing.core += duration
                    existing.asleep += duration
                default:
                    break
                }

                dailyData[sleepDate] = existing
            }

            // Convert to DailySleepData
            return dailyData.map { date, data in
                let totalSleepHours = data.asleep / 3600.0
                let timeInBedHours = max(data.inBed, data.asleep) / 3600.0
                let deepHours = data.deep / 3600.0
                let remHours = data.rem / 3600.0
                let coreHours = data.core / 3600.0

                // Sleep quality: ratio of deep + REM to total sleep (ideal is ~40%)
                let qualitySleep = data.deep + data.rem
                let sleepQuality = data.asleep > 0 ? min(1.0, (qualitySleep / data.asleep) / 0.4) : 0.5

                return DailySleepData(
                    date: date,
                    totalSleepHours: totalSleepHours,
                    timeInBedHours: timeInBedHours,
                    sleepQuality: sleepQuality,
                    deepSleepHours: deepHours,
                    remSleepHours: remHours,
                    coreSleepHours: coreHours
                )
            }
            .sorted { $0.date < $1.date }

        } catch {
            NSLog("Warning: Failed to fetch historical sleep data: \(error)")
            return []
        }
    }

    /// Gets historical HRV data for a date range
    func getHistoricalHRVData(from startDate: Date, to endDate: Date) async -> [DailyHRVData] {
        guard isAvailable, permissionStatus.allowsAccess else {
            return []
        }

        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return []
        }

        let calendar = Calendar.current
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        do {
            let samples = try await fetchSamples(type: hrvType, predicate: predicate)

            // Group samples by day
            var dailyData: [Date: [Double]] = [:]

            for sample in samples {
                guard let quantitySample = sample as? HKQuantitySample else { continue }
                let date = calendar.startOfDay(for: quantitySample.startDate)
                let hrvValue = quantitySample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))

                dailyData[date, default: []].append(hrvValue)
            }

            // Convert to DailyHRVData
            return dailyData.compactMap { date, values -> DailyHRVData? in
                guard !values.isEmpty else { return nil }

                let avgHRV = values.reduce(0, +) / Double(values.count)
                let minHRV = values.min() ?? avgHRV
                let maxHRV = values.max() ?? avgHRV

                return DailyHRVData(
                    date: date,
                    averageHRV: avgHRV,
                    minHRV: minHRV,
                    maxHRV: maxHRV,
                    sampleCount: values.count,
                    recoveryIndicator: HRVRecoveryIndicator.from(hrv: avgHRV)
                )
            }
            .sorted { $0.date < $1.date }

        } catch {
            NSLog("Warning: Failed to fetch historical HRV data: \(error)")
            return []
        }
    }

    /// Gets historical workout data for a date range
    func getHistoricalWorkoutData(from startDate: Date, to endDate: Date) async -> [DailyWorkoutData] {
        guard isAvailable, permissionStatus.allowsAccess else {
            return []
        }

        let workoutType = HKObjectType.workoutType()
        let calendar = Calendar.current
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        do {
            let samples = try await fetchSamples(type: workoutType, predicate: predicate)

            // Group workouts by day
            var dailyData: [Date: (minutes: Int, calories: Double, count: Int, types: Set<String>, heartRates: [Double])] = [:]

            for sample in samples {
                guard let workout = sample as? HKWorkout else { continue }
                let date = calendar.startOfDay(for: workout.startDate)
                let duration = Int(workout.duration / 60)  // Convert to minutes

                // Use statisticsForType for activeEnergyBurned (iOS 18+ recommendation)
                let activeEnergyType = HKQuantityType(.activeEnergyBurned)
                let calories = workout.statistics(for: activeEnergyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0

                // Get workout type name
                let workoutTypeName = workout.workoutActivityType.name

                var existing = dailyData[date] ?? (minutes: 0, calories: 0, count: 0, types: [], heartRates: [])
                existing.minutes += duration
                existing.calories += calories
                existing.count += 1
                existing.types.insert(workoutTypeName)

                // Get average heart rate if available
                if let avgHR = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)?.averageQuantity() {
                    existing.heartRates.append(avgHR.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                }

                dailyData[date] = existing
            }

            // Convert to DailyWorkoutData
            return dailyData.map { date, data in
                let avgHeartRate: Double? = data.heartRates.isEmpty ? nil : data.heartRates.reduce(0, +) / Double(data.heartRates.count)

                return DailyWorkoutData(
                    date: date,
                    totalWorkoutMinutes: data.minutes,
                    totalCaloriesBurned: data.calories,
                    workoutCount: data.count,
                    workoutTypes: Array(data.types),
                    averageHeartRate: avgHeartRate
                )
            }
            .sorted { $0.date < $1.date }

        } catch {
            NSLog("Warning: Failed to fetch historical workout data: \(error)")
            return []
        }
    }

    /// Gets historical resting heart rate data for a date range
    func getHistoricalRestingHRData(from startDate: Date, to endDate: Date) async -> [DailyRestingHRData] {
        guard isAvailable, permissionStatus.allowsAccess else {
            return []
        }

        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return []
        }

        let calendar = Calendar.current
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        do {
            let samples = try await fetchSamples(type: restingHRType, predicate: predicate)

            // Group samples by day
            var dailyData: [Date: [Double]] = [:]

            for sample in samples {
                guard let quantitySample = sample as? HKQuantitySample else { continue }
                let date = calendar.startOfDay(for: quantitySample.startDate)
                let hrValue = quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

                dailyData[date, default: []].append(hrValue)
            }

            // Calculate baseline (average across all days)
            let allValues = dailyData.values.flatMap { $0 }
            let baseline = allValues.isEmpty ? 70.0 : allValues.reduce(0, +) / Double(allValues.count)

            // Convert to DailyRestingHRData
            return dailyData.compactMap { date, values -> DailyRestingHRData? in
                guard !values.isEmpty else { return nil }

                let avgHR = values.reduce(0, +) / Double(values.count)

                let trend: HeartRateTrend
                if avgHR > baseline + 5 {
                    trend = .elevated
                } else if avgHR < baseline - 5 {
                    trend = .low
                } else {
                    trend = .normal
                }

                return DailyRestingHRData(
                    date: date,
                    restingHeartRate: avgHR,
                    trend: trend
                )
            }
            .sorted { $0.date < $1.date }

        } catch {
            NSLog("Warning: Failed to fetch historical resting HR data: \(error)")
            return []
        }
    }

    /// Gets historical step count data for a date range
    func getHistoricalStepData(from startDate: Date, to endDate: Date) async -> [Date: Int] {
        guard isAvailable, permissionStatus.allowsAccess else {
            return [:]
        }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return [:]
        }

        let calendar = Calendar.current

        // Query each day separately for accurate daily totals
        var result: [Date: Int] = [:]
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate <= endDay {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }

            let predicate = HKQuery.predicateForSamples(
                withStart: currentDate,
                end: nextDay,
                options: .strictStartDate
            )

            do {
                let steps = try await fetchStatistics(type: stepType, predicate: predicate)
                if steps > 0 {
                    result[currentDate] = Int(steps)
                }
            } catch {
                // Continue with next day
            }

            currentDate = nextDay
        }

        return result
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

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    /// Human-readable name for the workout type
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .coreTraining: return "Core Training"
        case .mindAndBody: return "Mind & Body"
        case .crossTraining: return "Cross Training"
        case .mixedCardio: return "Mixed Cardio"
        case .tennis: return "Tennis"
        case .golf: return "Golf"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        default: return "Workout"
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

    // Mock historical data generators
    var generateMockData: Bool = true

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

    // MARK: - Historical Data (Mock Implementation)

    func getHistoricalSleepData(from startDate: Date, to endDate: Date) async -> [DailySleepData] {
        guard generateMockData else { return [] }

        let calendar = Calendar.current
        var result: [DailySleepData] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate <= endDay {
            // Generate realistic sleep data with some variation
            let baseSleep = 7.0
            let variation = Double.random(in: -1.5...1.5)
            let totalSleep = max(4.0, min(10.0, baseSleep + variation))

            result.append(DailySleepData(
                date: currentDate,
                totalSleepHours: totalSleep,
                timeInBedHours: totalSleep + Double.random(in: 0.3...1.0),
                sleepQuality: Double.random(in: 0.5...0.95),
                deepSleepHours: totalSleep * Double.random(in: 0.12...0.2),
                remSleepHours: totalSleep * Double.random(in: 0.18...0.25),
                coreSleepHours: totalSleep * Double.random(in: 0.4...0.55)
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }

    func getHistoricalHRVData(from startDate: Date, to endDate: Date) async -> [DailyHRVData] {
        guard generateMockData else { return [] }

        let calendar = Calendar.current
        var result: [DailyHRVData] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate <= endDay {
            // Generate realistic HRV data (varies with sleep/stress)
            let baseHRV = 55.0
            let variation = Double.random(in: -20...25)
            let avgHRV = max(20, min(100, baseHRV + variation))

            result.append(DailyHRVData(
                date: currentDate,
                averageHRV: avgHRV,
                minHRV: avgHRV - Double.random(in: 5...15),
                maxHRV: avgHRV + Double.random(in: 5...20),
                sampleCount: Int.random(in: 3...10),
                recoveryIndicator: HRVRecoveryIndicator.from(hrv: avgHRV)
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }

    func getHistoricalWorkoutData(from startDate: Date, to endDate: Date) async -> [DailyWorkoutData] {
        guard generateMockData else { return [] }

        let calendar = Calendar.current
        var result: [DailyWorkoutData] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        let workoutTypes = ["Running", "Walking", "Cycling", "Strength Training", "Yoga", "HIIT"]

        while currentDate <= endDay {
            // ~60% chance of workout on any given day
            if Double.random(in: 0...1) < 0.6 {
                let workoutCount = Int.random(in: 1...2)
                let minutes = Int.random(in: 20...90)
                let selectedTypes = Array(workoutTypes.shuffled().prefix(workoutCount))

                result.append(DailyWorkoutData(
                    date: currentDate,
                    totalWorkoutMinutes: minutes,
                    totalCaloriesBurned: Double(minutes) * Double.random(in: 5...12),
                    workoutCount: workoutCount,
                    workoutTypes: selectedTypes,
                    averageHeartRate: Double.random(in: 110...160)
                ))
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }

    func getHistoricalRestingHRData(from startDate: Date, to endDate: Date) async -> [DailyRestingHRData] {
        guard generateMockData else { return [] }

        let calendar = Calendar.current
        var result: [DailyRestingHRData] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        let baseline = 65.0

        while currentDate <= endDay {
            let variation = Double.random(in: -8...10)
            let restingHR = baseline + variation

            let trend: HeartRateTrend
            if restingHR > baseline + 5 {
                trend = .elevated
            } else if restingHR < baseline - 5 {
                trend = .low
            } else {
                trend = .normal
            }

            result.append(DailyRestingHRData(
                date: currentDate,
                restingHeartRate: restingHR,
                trend: trend
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }

    func getHistoricalStepData(from startDate: Date, to endDate: Date) async -> [Date: Int] {
        guard generateMockData else { return [:] }

        let calendar = Calendar.current
        var result: [Date: Int] = [:]
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate <= endDay {
            // Generate step data with weekend/weekday variation
            let weekday = calendar.component(.weekday, from: currentDate)
            let isWeekend = weekday == 1 || weekday == 7

            let baseSteps = isWeekend ? 6000 : 8000
            let steps = baseSteps + Int.random(in: -3000...4000)
            result[currentDate] = max(1000, steps)

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }
}
