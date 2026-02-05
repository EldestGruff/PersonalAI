//
//  MedicationService.swift
//  PersonalAI
//
//  HealthKit Medications API integration for medication tracking
//  Provides opt-in medication correlation with thoughts and mood
//
//  NOTE: HealthKit Medications API (HKUserAnnotatedMedication, HKMedicationDoseEvent)
//  requires iOS 16+ and specific SDK support. Implementation ready for when available.
//

import Foundation
import HealthKit

// TODO: Uncomment when HKUserAnnotatedMedication API is available in SDK
/*

// MARK: - Medication Models

/// A medication from HealthKit with user customizations
@available(iOS 16.0, *)
struct Medication: Identifiable, Sendable, Equatable {
    let id: String // medicationConcept.identifier
    let name: String // displayText
    let nickname: String?
    let form: String? // capsule, tablet, liquid, etc.
    let isArchived: Bool
    let hasSchedule: Bool
    let rxNormCode: String? // RxNorm identifier

    init(from userMedication: HKUserAnnotatedMedication) {
        self.id = userMedication.medicationConcept.identifier
        self.name = userMedication.medicationConcept.displayText
        self.nickname = userMedication.nickname
        self.form = userMedication.medicationConcept.generalForm?.rawValue
        self.isArchived = userMedication.isArchived
        self.hasSchedule = userMedication.hasSchedule

        // Extract RxNorm code if available
        if let rxNorm = userMedication.medicationConcept.relatedCodings.first(where: { $0.system == "http://www.nlm.nih.gov/research/umls/rxnorm" }) {
            self.rxNormCode = rxNorm.code
        } else {
            self.rxNormCode = nil
        }
    }

    /// Display name (nickname if set, otherwise medication name)
    var displayName: String {
        nickname ?? name
    }
}

/// A medication dose event (taken, skipped, snoozed, or not interacted)
@available(iOS 16.0, *)
struct MedicationDoseEvent: Identifiable, Sendable, Equatable {
    let id: UUID
    let medicationId: String
    let status: DoseStatus
    let scheduledDate: Date
    let actualDate: Date
    let scheduledQuantity: Double?
    let actualQuantity: Double?

    init(from doseEvent: HKMedicationDoseEvent) {
        self.id = doseEvent.uuid
        self.medicationId = doseEvent.medicationConceptIdentifier

        switch doseEvent.logStatus {
        case .taken:
            self.status = .taken
        case .skipped:
            self.status = .skipped
        case .snoozed:
            self.status = .snoozed
        case .notInteracted:
            self.status = .notInteracted
        @unknown default:
            self.status = .unknown
        }

        self.scheduledDate = doseEvent.scheduledDate ?? doseEvent.startDate
        self.actualDate = doseEvent.startDate
        self.scheduledQuantity = doseEvent.scheduledQuantity?.doubleValue(for: .count())
        self.actualQuantity = doseEvent.doseQuantity?.doubleValue(for: .count())
    }

    enum DoseStatus: String, Codable, Sendable {
        case taken
        case skipped
        case snoozed
        case notInteracted
        case unknown
    }
}

// MARK: - Medication Service Protocol

/// Protocol for medication tracking services
@available(iOS 16.0, *)
protocol MedicationServiceProtocol: Sendable {
    /// Gets all active medications
    func getActiveMedications() async -> [Medication]

    /// Gets all medications (including archived)
    func getAllMedications() async -> [Medication]

    /// Gets dose events for a specific date range
    func getDoseEvents(from startDate: Date, to endDate: Date) async -> [MedicationDoseEvent]

    /// Gets dose events for a specific medication
    func getDoseEvents(for medicationId: String, from startDate: Date, to endDate: Date) async -> [MedicationDoseEvent]

    /// Calculates medication adherence rate for a date range
    func getAdherenceRate(from startDate: Date, to endDate: Date) async -> Double
}

// MARK: - HealthKit Medication Service

/// HealthKit-based medication tracking service
@available(iOS 16.0, *)
actor HealthKitMedicationService: MedicationServiceProtocol {
    private let healthStore: HKHealthStore
    private let configuration: ServiceConfiguration

    init(healthStore: HKHealthStore, configuration: ServiceConfiguration = .shared) {
        self.healthStore = healthStore
        self.configuration = configuration
    }

    // MARK: - Query Medications

    func getActiveMedications() async -> [Medication] {
        let predicate = HKUserAnnotatedMedicationQueryDescriptor.predicate(forUserAnnotatedMedications: isArchived: false)
        return await queryMedications(predicate: predicate)
    }

    func getAllMedications() async -> [Medication] {
        return await queryMedications(predicate: nil)
    }

    private func queryMedications(predicate: NSPredicate?) async -> [Medication] {
        let queryDescriptor = HKUserAnnotatedMedicationQueryDescriptor(predicate: predicate)

        do {
            let results = try await queryDescriptor.result(for: healthStore)
            return results.map { Medication(from: $0) }
        } catch {
            print("❌ Failed to query medications: \(error)")
            return []
        }
    }

    // MARK: - Query Dose Events

    func getDoseEvents(from startDate: Date, to endDate: Date) async -> [MedicationDoseEvent] {
        guard let doseEventType = HKObjectType.objectType(forIdentifier: .medicationDoseEvent) as? HKSampleType else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: doseEventType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Failed to query dose events: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                let events = (samples as? [HKMedicationDoseEvent] ?? []).map { MedicationDoseEvent(from: $0) }
                continuation.resume(returning: events)
            }

            healthStore.execute(query)
        }
    }

    func getDoseEvents(for medicationId: String, from startDate: Date, to endDate: Date) async -> [MedicationDoseEvent] {
        let allEvents = await getDoseEvents(from: startDate, to: endDate)
        return allEvents.filter { $0.medicationId == medicationId }
    }

    // MARK: - Adherence Calculation

    func getAdherenceRate(from startDate: Date, to endDate: Date) async -> Double {
        let events = await getDoseEvents(from: startDate, to: endDate)

        guard !events.isEmpty else { return 0.0 }

        let takenCount = events.filter { $0.status == .taken }.count
        let totalScheduled = events.count

        return Double(takenCount) / Double(totalScheduled)
    }
}

// MARK: - Mock Medication Service

/// Mock medication service for testing/preview
@available(iOS 16.0, *)
actor MockMedicationService: MedicationServiceProtocol {
    func getActiveMedications() async -> [Medication] {
        // Return empty for now - can add mock data if needed
        []
    }

    func getAllMedications() async -> [Medication] {
        []
    }

    func getDoseEvents(from startDate: Date, to endDate: Date) async -> [MedicationDoseEvent] {
        []
    }

    func getDoseEvents(for medicationId: String, from startDate: Date, to endDate: Date) async -> [MedicationDoseEvent] {
        []
    }

    func getAdherenceRate(from startDate: Date, to endDate: Date) async -> Double {
        0.85 // Mock 85% adherence
    }
}
*/

// Placeholder types until SDK supports HKUserAnnotatedMedication API
// These will be uncommented when the HealthKit Medications API becomes available
