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
/// - **Classification:** AI-powered type, tags, and sentiment via Foundation Models
/// - **Location:** Current location from LocationService
/// - **Energy:** Latest energy level from HealthKit
/// - **State of Mind:** Recent mental state from HealthKit
/// - **Calendar:** Nearby events from EventKit
/// - **Activity:** Current activity type from MotionService
/// - **Weather:** Current weather (if available)
/// - **Focus State:** Current iOS Focus mode (iOS 26+)
actor ContextEnrichmentService {
    // MARK: - Singleton

    static let shared = ContextEnrichmentService()

    // MARK: - Dependencies

    private let thoughtService: ThoughtService
    private let classificationService: ClassificationService
    private let locationService: LocationService
    private let healthKitService: HealthKitService
    private let eventKitService: EventKitService
    private let motionService: MotionService
    private let contactsService: ContactsService

    // MARK: - Initialization

    init(
        thoughtService: ThoughtService = .shared,
        classificationService: ClassificationService = ClassificationService(),
        locationService: LocationService = LocationService(),
        healthKitService: HealthKitService = HealthKitService(),
        eventKitService: EventKitService = EventKitService(),
        motionService: MotionService = MotionService(),
        contactsService: ContactsService = .shared
    ) {
        self.thoughtService = thoughtService
        self.classificationService = classificationService
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.eventKitService = eventKitService
        self.motionService = motionService
        self.contactsService = contactsService
    }

    // MARK: - Public Methods

    /// Enriches context for a thought in the background.
    ///
    /// Fetches location, health, calendar, activity, and weather data,
    /// then updates the thought with the enriched context.
    ///
    /// - Parameter thoughtId: ID of the thought to enrich
    func enrichContext(for thoughtId: UUID) async {
        AppLogger.debug("Enriching context for thought", category: .context)

        // Fetch the thought
        guard let thought = try? await thoughtService.fetch(thoughtId) else {
            AppLogger.error("Failed to fetch thought for context enrichment", category: .context)
            return
        }

        // Gather context data and classification in parallel
        async let location = fetchLocation()
        async let energy = fetchEnergy()
        async let activity = fetchActivity()
        async let stateOfMind = fetchStateOfMind()
        async let energyBreakdown = fetchEnergyBreakdown()
        async let calendar = fetchCalendar()
        async let classification = fetchClassification(for: thought)
        async let mentionedContacts = fetchMentionedContacts(for: thought)

        // Wait for all data
        let enrichedContext = await Context(
            timestamp: thought.context.timestamp,
            location: location,
            timeOfDay: thought.context.timeOfDay,
            energy: energy,
            focusState: thought.context.focusState,
            calendar: calendar,
            activity: activity,
            weather: nil,
            stateOfMind: stateOfMind,
            energyBreakdown: energyBreakdown,
            mentionedContacts: await mentionedContacts
        )

        let resolvedClassification = await classification
        let resolvedMentionedContacts = enrichedContext.mentionedContacts

        // Create updated thought (Thought is immutable)
        let updatedThought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            attributedContent: thought.attributedContent,
            tags: mergedTags(
                base: resolvedClassification?.suggestedTags ?? thought.tags,
                contacts: resolvedMentionedContacts
            ),
            status: thought.status,
            context: enrichedContext,
            createdAt: thought.createdAt,
            updatedAt: Date(),
            classification: resolvedClassification ?? thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        do {
            _ = try await thoughtService.update(updatedThought)
            AppLogger.info("Context enriched successfully", category: .context)
        } catch {
            AppLogger.error("Failed to update thought with enriched context", category: .context)
        }
    }

    // MARK: - Private Methods

    /// Fetches current location if available.
    private func fetchLocation() async -> Location? {
        guard await locationService.permissionStatus == .authorized else {
            AnalyticsService.shared.track(.contextEnrichmentFailed(component: .location))
            return nil
        }

        let location = await locationService.getCurrentLocation()
        if location == nil {
            AnalyticsService.shared.track(.contextEnrichmentFailed(component: .location))
        }
        return location
    }

    /// Fetches current energy level from HealthKit.
    private func fetchEnergy() async -> EnergyLevel {
        guard await healthKitService.permissionStatus == .authorized else {
            AnalyticsService.shared.track(.contextEnrichmentFailed(component: .healthKit))
            return .medium
        }

        return await healthKitService.getEnergyLevel()
    }

    /// Fetches current activity context from HealthKit.
    private func fetchActivity() async -> ActivityContext? {
        guard await healthKitService.permissionStatus == .authorized else {
            return nil
        }

        return await healthKitService.getActivityContext()
    }

    /// Fetches most recent state of mind from HealthKit.
    private func fetchStateOfMind() async -> StateOfMindSnapshot? {
        guard await healthKitService.permissionStatus == .authorized else {
            return nil
        }

        return await healthKitService.getStateOfMind()
    }

    /// Fetches energy breakdown from HealthKit.
    private func fetchEnergyBreakdown() async -> EnergyBreakdown? {
        guard await healthKitService.permissionStatus == .authorized else {
            return nil
        }

        return await healthKitService.getEnergyBreakdown()
    }

    /// Fetches calendar availability context.
    private func fetchCalendar() async -> CalendarContext? {
        guard await eventKitService.permissionStatus == .authorized else {
            AnalyticsService.shared.track(.contextEnrichmentFailed(component: .calendar))
            return nil
        }

        return await eventKitService.getAvailability()
    }

    /// Detects contact name mentions in the thought's content.
    ///
    /// Returns an empty array if Contacts permission is not granted.
    private func fetchMentionedContacts(for thought: Thought) async -> [String] {
        let names = await contactsService.getAllContactNames()
        guard !names.isEmpty else { return [] }
        return ContactMentionDetector.detect(in: thought.content, knownNames: names)
    }

    /// Merges contact names into tag list as kebab-case tags (max 2 contact tags).
    private func mergedTags(base: [String], contacts: [String]) -> [String] {
        guard !contacts.isEmpty else { return base }
        var tags = base
        let contactTags = contacts.prefix(2).map { name in
            name.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: "-")
        }
        for tag in contactTags where !tags.contains(tag) {
            tags.append(tag)
        }
        return tags
    }

    /// Classifies the thought if it hasn't been classified yet.
    private func fetchClassification(for thought: Thought) async -> Classification? {
        guard thought.classification == nil else {
            return nil // Already classified, keep existing
        }

        do {
            let result = try await classificationService.classify(thought.content)
            AppLogger.debug("Background classification complete", category: .context)
            return result
        } catch {
            AppLogger.warning("Background classification failed", category: .context)
            return nil
        }
    }
}
