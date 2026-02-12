//
//  ContextEnrichmentService.swift
//  STASH
//
//  Background context enrichment for voice-captured thoughts
//  Fills in location, health, calendar, activity, weather after initial save
//

import Foundation
import CoreLocation

/// Service that enriches thought context in the background.
///
/// ## Purpose
///
/// When thoughts are captured quickly (via Siri, voice capture), they save
/// with minimal context for speed. This service fills in the missing data
/// asynchronously to avoid blocking the user.
///
/// ## Usage
///
/// ```swift
/// // After creating a thought with empty context
/// Task.detached {
///     await ContextEnrichmentService.shared.enrichContext(for: thoughtId)
/// }
/// ```
///
/// ## What Gets Enriched
///
/// - **Location:** Current location from LocationService
/// - **Energy:** Latest energy level from HealthKit
/// - **State of Mind:** Recent mental state from HealthKit
/// - **Calendar:** Nearby events from EventKit
/// - **Activity:** Current activity type from MotionService
/// - **Weather:** Current weather (if available)
/// - **Focus State:** Current iOS Focus mode (iOS 26+)
@MainActor
final class ContextEnrichmentService {
    // MARK: - Singleton

    static let shared = ContextEnrichmentService()

    // MARK: - Dependencies

    private let thoughtService: ThoughtService
    private let locationService: LocationService
    private let healthKitService: HealthKitService
    private let eventKitService: EventKitService
    private let motionService: MotionService

    // MARK: - Initialization

    init(
        thoughtService: ThoughtService = .shared,
        locationService: LocationService = LocationService(),
        healthKitService: HealthKitService = HealthKitService(),
        eventKitService: EventKitService = EventKitService(),
        motionService: MotionService = MotionService()
    ) {
        self.thoughtService = thoughtService
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.eventKitService = eventKitService
        self.motionService = motionService
    }

    // MARK: - Public Methods

    /// Enriches context for a thought in the background.
    ///
    /// Fetches location, health, calendar, activity, and weather data,
    /// then updates the thought with the enriched context.
    ///
    /// - Parameter thoughtId: ID of the thought to enrich
    func enrichContext(for thoughtId: UUID) async {
        print("🔄 Enriching context for thought \(thoughtId)...")

        // Fetch the thought
        guard let thought = try? await thoughtService.fetch(thoughtId) else {
            print("❌ Failed to fetch thought \(thoughtId)")
            return
        }

        // Gather context data in parallel
        async let location = fetchLocation()
        async let stateOfMind = fetchStateOfMind()
        async let calendar = fetchCalendar()

        // Wait for all data
        let enrichedContext = await Context(
            timestamp: thought.context.timestamp,
            location: location,
            timeOfDay: thought.context.timeOfDay, // Already set
            energy: thought.context.energy, // Keep existing - TODO: enrich from HealthKit
            focusState: thought.context.focusState, // Keep existing - TODO: enrich from FocusStatus
            calendar: calendar,
            activity: nil, // TODO: Add ActivityContext enrichment
            weather: nil, // TODO: Add WeatherService when available
            stateOfMind: stateOfMind,
            energyBreakdown: nil // TODO: Calculate from HealthKit samples
        )

        // Update thought with enriched context
        var updatedThought = thought
        updatedThought.context = enrichedContext
        updatedThought.updatedAt = Date()

        do {
            try await thoughtService.update(updatedThought)
            print("✅ Context enriched for thought \(thoughtId)")
        } catch {
            print("❌ Failed to update thought context: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Fetches current location if available.
    private func fetchLocation() async -> Location? {
        guard locationService.permissionStatus == .authorized else {
            return nil
        }

        return await locationService.getCurrentLocation()
    }

    /// Fetches most recent state of mind from HealthKit.
    private func fetchStateOfMind() async -> StateOfMindSnapshot? {
        guard healthKitService.permissionStatus == .authorized else {
            return nil
        }

        // Fetch state of mind from last 24 hours
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        guard let samples = try? await healthKitService.fetchStateOfMind(
            from: oneDayAgo,
            to: Date()
        ), let latestSample = samples.last else {
            return nil
        }

        return latestSample
    }

    /// Fetches calendar availability context.
    private func fetchCalendar() async -> CalendarContext? {
        guard eventKitService.permissionStatus == .authorized else {
            return nil
        }

        return await eventKitService.getAvailability()
    }
}
