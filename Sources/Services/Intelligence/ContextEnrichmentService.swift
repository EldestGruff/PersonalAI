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
        guard let thought = try? await thoughtService.fetch(by: thoughtId) else {
            print("❌ Failed to fetch thought \(thoughtId)")
            return
        }

        // Gather context data in parallel
        async let location = fetchLocation()
        async let energy = fetchEnergy()
        async let stateOfMind = fetchStateOfMind()
        async let calendar = fetchCalendar()
        async let activity = fetchActivity()
        async let focusState = fetchFocusState()

        // Wait for all data
        let enrichedContext = await Context(
            timestamp: thought.context.timestamp,
            location: location,
            timeOfDay: thought.context.timeOfDay, // Already set
            energy: energy ?? thought.context.energy,
            focusState: focusState ?? thought.context.focusState,
            calendar: calendar,
            activity: activity,
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
    private func fetchLocation() async -> LocationSnapshot? {
        guard await locationService.permissionStatus == .authorized else {
            return nil
        }

        return await locationService.currentLocation
    }

    /// Fetches latest energy level from HealthKit.
    private func fetchEnergy() async -> EnergyLevel? {
        guard await healthKitService.permissionStatus == .authorized else {
            return nil
        }

        // Fetch most recent energy sample from last 6 hours
        let sixHoursAgo = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()

        guard let samples = try? await healthKitService.fetchEnergySamples(
            from: sixHoursAgo,
            to: Date()
        ), let latestSample = samples.last else {
            return nil
        }

        return latestSample.level
    }

    /// Fetches most recent state of mind from HealthKit.
    private func fetchStateOfMind() async -> StateOfMindSnapshot? {
        guard await healthKitService.permissionStatus == .authorized else {
            return nil
        }

        // Fetch state of mind from last 24 hours
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        guard let samples = try? await healthKitService.fetchStateOfMindSamples(
            from: oneDayAgo,
            to: Date()
        ), let latestSample = samples.last else {
            return nil
        }

        return latestSample
    }

    /// Fetches nearby calendar events (within 2 hours).
    private func fetchCalendar() async -> CalendarSnapshot? {
        guard await eventKitService.permissionStatus == .authorized else {
            return nil
        }

        let now = Date()
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now
        let twoHoursLater = Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now

        guard let events = try? await eventKitService.fetchEvents(
            from: twoHoursAgo,
            to: twoHoursLater
        ), !events.isEmpty else {
            return nil
        }

        return CalendarSnapshot(events: events)
    }

    /// Fetches current activity type from MotionService.
    private func fetchActivity() async -> ActivitySnapshot? {
        guard await motionService.permissionStatus == .authorized else {
            return nil
        }

        guard let activityType = await motionService.currentActivityType else {
            return nil
        }

        return ActivitySnapshot(
            type: activityType,
            confidence: .medium,
            startTime: Date() // Approximate
        )
    }

    /// Fetches current iOS Focus mode (iOS 26+).
    private func fetchFocusState() async -> FocusState? {
        if #available(iOS 26.0, *) {
            // TODO: Integrate FocusStatus API when available
            // For now, return nil
            return nil
        }
        return nil
    }
}
