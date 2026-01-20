//
//  EventKitService.swift
//  PersonalAI
//
//  Phase 3A Spec 2: EventKit Framework Integration
//  Wrapper around EventKit for calendar and reminder integration
//

import Foundation
import EventKit

// MARK: - EventKit Service Protocol

/// Protocol for EventKit services.
///
/// Enables mocking in tests.
protocol EventKitServiceProtocol: FrameworkServiceProtocol {
    /// Creates a system reminder
    func createReminder(title: String, description: String?, dueDate: Date?) async throws -> String

    /// Creates a calendar event
    func createEvent(title: String, description: String?, startDate: Date, endDate: Date) async throws -> String

    /// Gets calendar availability context
    func getAvailability() async -> CalendarContext
}

// MARK: - EventKit Service

/// Service for creating reminders and events via EventKit.
///
/// Unlike other framework services, create operations throw errors
/// because failure to create a reminder/event is something the user
/// needs to know about. Read operations (getAvailability) still fail soft.
///
/// ## Permissions
///
/// Requires EventKit permission. In iOS 17+, can request either:
/// - Write-only access (for creating reminders/events)
/// - Full access (for reading calendar data)
///
/// This service requests write-only access by default.
actor EventKitService: EventKitServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .eventKit }

    nonisolated var isAvailable: Bool { true }

    var permissionStatus: PermissionLevel {
        // Check both event and reminder permissions
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)

        // Return the most permissive status (if either is authorized, we can use that one)
        let eventLevel = mapAuthorizationStatus(eventStatus)
        let reminderLevel = mapAuthorizationStatus(reminderStatus)

        // If either is authorized, return authorized
        if eventLevel.allowsAccess || reminderLevel.allowsAccess {
            return .authorized
        }

        // Otherwise return the event status (primary)
        return eventLevel
    }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - State

    private let eventStore: EKEventStore

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
        self.eventStore = EKEventStore()
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        do {
            // Request write-only access for events
            let eventGranted = try await eventStore.requestWriteOnlyAccessToEvents()

            // Request reminder access
            let reminderGranted = try await eventStore.requestFullAccessToReminders()

            // If either permission is granted, return authorized
            return (eventGranted || reminderGranted) ? .authorized : .denied
        } catch {
            // If events fail, try reminders only
            do {
                let reminderGranted = try await eventStore.requestFullAccessToReminders()
                return reminderGranted ? .authorized : .denied
            } catch {
                return .denied
            }
        }
    }

    // MARK: - Create Reminder

    /// Creates a system reminder.
    ///
    /// - Parameters:
    ///   - title: The reminder title
    ///   - description: Optional notes
    ///   - dueDate: Optional due date
    /// - Returns: The reminder identifier
    /// - Throws: `ServiceError` if creation fails
    func createReminder(title: String, description: String?, dueDate: Date?) async throws -> String {
        // Check and request reminder-specific permission
        let rawInitialStatus = EKEventStore.authorizationStatus(for: .reminder)
        let initialStatus = mapAuthorizationStatus(rawInitialStatus)

        print("🔔 EventKit createReminder - Initial status: \(rawInitialStatus.rawValue) -> \(initialStatus)")

        if !initialStatus.allowsAccess {
            // Request reminder permission specifically
            print("🔔 EventKit createReminder - Requesting permission...")
            do {
                let granted = try await eventStore.requestFullAccessToReminders()
                print("🔔 EventKit createReminder - Permission request returned: \(granted)")
            } catch {
                print("🔔 EventKit createReminder - Permission request failed: \(error)")
                throw ServiceError.permissionDenied(
                    framework: .eventKit,
                    currentLevel: initialStatus
                )
            }
        }

        // Verify we have permission after request
        let rawFinalStatus = EKEventStore.authorizationStatus(for: .reminder)
        let finalStatus = mapAuthorizationStatus(rawFinalStatus)
        print("🔔 EventKit createReminder - Final status: \(rawFinalStatus.rawValue) -> \(finalStatus)")

        guard finalStatus.allowsAccess else {
            throw ServiceError.permissionDenied(
                framework: .eventKit,
                currentLevel: finalStatus
            )
        }

        guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "No default reminder calendar found"
            )
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = description
        reminder.calendar = defaultCalendar

        if let dueDate = dueDate {
            let calendar = Calendar.current
            reminder.dueDateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )

            // Add alarm 5 minutes before
            let alarm = EKAlarm(relativeOffset: -300)
            reminder.addAlarm(alarm)
        }

        do {
            try eventStore.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            throw ServiceError.persistence(
                operation: "create reminder",
                underlying: error
            )
        }
    }

    // MARK: - Create Event

    /// Creates a calendar event.
    ///
    /// - Parameters:
    ///   - title: The event title
    ///   - description: Optional notes
    ///   - startDate: Event start time
    ///   - endDate: Event end time
    /// - Returns: The event identifier
    /// - Throws: `ServiceError` if creation fails
    func createEvent(title: String, description: String?, startDate: Date, endDate: Date) async throws -> String {
        // Check and request event-specific permission
        let rawInitialStatus = EKEventStore.authorizationStatus(for: .event)
        let initialStatus = mapAuthorizationStatus(rawInitialStatus)

        print("📅 EventKit createEvent - Initial status: \(rawInitialStatus.rawValue) -> \(initialStatus)")

        if !initialStatus.allowsAccess {
            // Request event permission specifically
            print("📅 EventKit createEvent - Requesting permission...")
            do {
                let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                print("📅 EventKit createEvent - Permission request returned: \(granted)")
            } catch {
                print("📅 EventKit createEvent - Permission request failed: \(error)")
                throw ServiceError.permissionDenied(
                    framework: .eventKit,
                    currentLevel: initialStatus
                )
            }
        }

        // Verify we have permission after request
        let rawFinalStatus = EKEventStore.authorizationStatus(for: .event)
        let finalStatus = mapAuthorizationStatus(rawFinalStatus)
        print("📅 EventKit createEvent - Final status: \(rawFinalStatus.rawValue) -> \(finalStatus)")

        guard finalStatus.allowsAccess else {
            throw ServiceError.permissionDenied(
                framework: .eventKit,
                currentLevel: finalStatus
            )
        }

        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "No default calendar found"
            )
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = description
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = defaultCalendar

        // Add default alert 15 minutes before
        let alarm = EKAlarm(relativeOffset: -900)
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            return event.eventIdentifier
        } catch {
            throw ServiceError.persistence(
                operation: "create event",
                underlying: error
            )
        }
    }

    // MARK: - Get Availability

    /// Gets calendar availability context.
    ///
    /// Returns information about upcoming events to help with
    /// context-aware suggestions. Fails soft with default values.
    func getAvailability() async -> CalendarContext {
        guard permissionStatus.allowsAccess else {
            return CalendarContext(nextEventMinutes: nil, isFreetime: true, eventCount: 0)
        }

        let timeout = configuration.timeouts.frameworkOperation
        let defaultContext = CalendarContext(nextEventMinutes: nil, isFreetime: true, eventCount: 0)

        return await withTimeout(timeout, default: defaultContext) {
            await self.fetchAvailability()
        }
    }

    private func fetchAvailability() async -> CalendarContext {
        let calendar = Calendar.current
        let now = Date()

        // Look ahead 24 hours
        guard let endOfWindow = calendar.date(byAdding: .hour, value: 24, to: now) else {
            return CalendarContext(nextEventMinutes: nil, isFreetime: true, eventCount: 0)
        }

        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endOfWindow,
            calendars: eventStore.calendars(for: .event)
        )

        let events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        // Find next event
        let nextEvent = events.first
        let minutesToNext: Int?
        let isFreetime: Bool

        if let next = nextEvent {
            minutesToNext = Int(next.startDate.timeIntervalSince(now) / 60)
            isFreetime = minutesToNext ?? 0 > 30 // More than 30 minutes to next event
        } else {
            minutesToNext = nil
            isFreetime = true
        }

        return CalendarContext(
            nextEventMinutes: minutesToNext,
            isFreetime: isFreetime,
            eventCount: events.count
        )
    }

    // MARK: - Helpers

    private func mapAuthorizationStatus(_ status: EKAuthorizationStatus) -> PermissionLevel {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .fullAccess, .writeOnly:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    private func withTimeout<T: Sendable>(_ timeout: TimeInterval, default defaultValue: T, operation: @Sendable @escaping () async -> T) async -> T {
        await withTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return defaultValue
            }

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

// MARK: - Mock EventKit Service

/// Mock EventKit service for testing and previews.
actor MockEventKitService: EventKitServiceProtocol {
    nonisolated var frameworkType: FrameworkType { .eventKit }
    nonisolated var isAvailable: Bool { true }
    var permissionStatus: PermissionLevel

    var createdReminders: [(title: String, description: String?, dueDate: Date?)] = []
    var createdEvents: [(title: String, description: String?, startDate: Date, endDate: Date)] = []
    var mockAvailability: CalendarContext

    init(
        permissionStatus: PermissionLevel = .authorized,
        availability: CalendarContext = CalendarContext(nextEventMinutes: 60, isFreetime: true, eventCount: 2)
    ) {
        self.permissionStatus = permissionStatus
        self.mockAvailability = availability
    }

    func requestPermission() async -> PermissionLevel {
        permissionStatus = .authorized
        return .authorized
    }

    func createReminder(title: String, description: String?, dueDate: Date?) async throws -> String {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(framework: .eventKit, currentLevel: permissionStatus)
        }
        createdReminders.append((title, description, dueDate))
        return UUID().uuidString
    }

    func createEvent(title: String, description: String?, startDate: Date, endDate: Date) async throws -> String {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(framework: .eventKit, currentLevel: permissionStatus)
        }
        createdEvents.append((title, description, startDate, endDate))
        return UUID().uuidString
    }

    func getAvailability() async -> CalendarContext {
        mockAvailability
    }
}
