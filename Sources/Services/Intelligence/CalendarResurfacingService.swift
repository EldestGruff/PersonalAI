//
//  CalendarResurfacingService.swift
//  STASH
//
//  Issue #22: Contextual Thought Resurfacing — Phase 3C: Calendar
//
//  Schedules local notifications that surface related thoughts before
//  upcoming calendar events. Called each time the app comes to foreground.
//

import Foundation
import UserNotifications

// MARK: - Rate Limiter

/// Tracks how many resurfacing notifications have been scheduled today.
///
/// Uses `UserDefaults.standard` for persistence across app launches.
/// Resets automatically at the start of each calendar day.
/// Extracted from the actor so it can be tested synchronously.
final class ResurfacingRateLimiter: @unchecked Sendable {
    private let countKey = "resurfacing.count"
    private let dateKey = "resurfacing.date"
    private let maxPerDay = 3
    private var defaults: UserDefaults { .standard }

    func canSchedule() -> Bool {
        resetIfNewDay()
        return defaults.integer(forKey: countKey) < maxPerDay
    }

    func recordScheduled() {
        resetIfNewDay()
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
    }

    func reset() {
        defaults.set(0, forKey: countKey)
        defaults.set(Calendar.current.startOfDay(for: Date()), forKey: dateKey)
    }

    /// Test hook: override the stored date so `resetIfNewDay()` treats it as a different day.
    func overrideDateForTesting(_ date: Date) {
        defaults.set(date, forKey: dateKey)
    }

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = defaults.object(forKey: dateKey) as? Date ?? .distantPast
        if !Calendar.current.isDate(stored, inSameDayAs: today) {
            defaults.set(0, forKey: countKey)
            defaults.set(today, forKey: dateKey)
        }
    }
}

// MARK: - Calendar Resurfacing Service

/// Schedules pre-meeting local notifications with semantically related thoughts.
///
/// ## Usage
///
/// Call `scheduleResurfacingNotifications()` whenever the app comes to foreground.
/// The method is idempotent — it skips events that already have a pending notification.
///
/// ## Notification behaviour
///
/// - Fires 30 minutes before each eligible event
/// - Requires ≥2 high-confidence thought matches (score > 0.6)
/// - Maximum 3 resurfacing notifications per calendar day
/// - Tapping navigates to Browse tab with event title pre-filled as search query
actor CalendarResurfacingService {
    static let shared = CalendarResurfacingService()

    // MARK: - Dependencies

    private let eventKitService: EventKitService
    private let thoughtService: ThoughtService
    private let semanticSearch: SemanticSearchService
    private let rateLimiter: ResurfacingRateLimiter

    // MARK: - Constants

    private static let minutesBeforeEvent: Double = 30
    private static let minimumMinutesUntilEvent: Double = 10
    private static let lookAheadHours: Int = 24
    private static let minimumRelevantThoughts: Int = 2

    // MARK: - Initialization

    init(
        eventKitService: EventKitService = .shared,
        thoughtService: ThoughtService = .shared,
        semanticSearch: SemanticSearchService = .shared,
        rateLimiter: ResurfacingRateLimiter = ResurfacingRateLimiter()
    ) {
        self.eventKitService = eventKitService
        self.thoughtService = thoughtService
        self.semanticSearch = semanticSearch
        self.rateLimiter = rateLimiter
    }

    // MARK: - Public API

    /// Schedules resurfacing notifications for upcoming events.
    ///
    /// Safe to call on every foreground — skips events with existing notifications.
    func scheduleResurfacingNotifications() async {
        guard await notificationsAuthorized() else { return }

        let events = await eventKitService.getUpcomingEvents(within: Self.lookAheadHours)
        guard !events.isEmpty else { return }

        let thoughts = (try? await thoughtService.list(filter: nil)) ?? []
        guard !thoughts.isEmpty else { return }

        let pending = await pendingNotificationIdentifiers()

        for event in events {
            guard rateLimiter.canSchedule() else { break }
            guard Self.isEligible(event: event) else { continue }

            let identifier = Self.notificationIdentifier(for: event)
            guard !pending.contains(identifier) else { continue }

            let results = await semanticSearch.search(query: event.title, in: thoughts)
            let relevant = results.filter { $0.isHighConfidence }
            guard relevant.count >= Self.minimumRelevantThoughts else { continue }

            let fireDate = event.startDate.addingTimeInterval(-Self.minutesBeforeEvent * 60)
            guard fireDate > Date() else { continue }

            await scheduleNotification(
                identifier: identifier,
                eventTitle: event.title,
                relevantCount: relevant.count,
                fireDate: fireDate
            )
            rateLimiter.recordScheduled()
            AppLogger.info("Resurfacing notification scheduled for '\(event.title)'", category: .general)
        }
    }

    // MARK: - Testable static helpers

    /// Returns `true` if the event starts more than `minimumMinutesUntilEvent` from now.
    static func isEligible(event: UpcomingEvent) -> Bool {
        event.startDate.timeIntervalSinceNow > minimumMinutesUntilEvent * 60
    }

    /// Returns the stable notification identifier for a given event.
    static func notificationIdentifier(for event: UpcomingEvent) -> String {
        "resurfacing.\(event.id)"
    }

    // MARK: - Private

    private func notificationsAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    private func pendingNotificationIdentifiers() async -> Set<String> {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return Set(requests.map { $0.identifier })
    }

    private func scheduleNotification(
        identifier: String,
        eventTitle: String,
        relevantCount: Int,
        fireDate: Date
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Before \(eventTitle)"
        content.body = "You have \(relevantCount) related thought\(relevantCount == 1 ? "" : "s") to review"
        content.sound = .default
        content.userInfo = [
            "deeplink": "stash://search",
            "query": eventTitle
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            AppLogger.warning("Failed to schedule resurfacing notification: \(error.localizedDescription)", category: .general)
        }
    }
}
