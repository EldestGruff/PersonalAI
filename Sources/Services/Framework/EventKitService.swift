//
//  EventKitService.swift
//  STASH
//
//  Phase 3A Spec 2: EventKit Framework Integration
//  Wrapper around EventKit for calendar and reminder integration
//

import Foundation
import EventKit

// MARK: - Calendar Info

/// Sendable representation of a calendar for cross-actor use.
struct CalendarInfo: Sendable, Identifiable {
    let id: String
    let title: String
    let colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)?

    init(calendar: EKCalendar) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        if let cgColor = calendar.cgColor {
            self.colorComponents = (
                red: cgColor.components?[safe: 0] ?? 0,
                green: cgColor.components?[safe: 1] ?? 0,
                blue: cgColor.components?[safe: 2] ?? 0,
                alpha: cgColor.components?[safe: 3] ?? 1
            )
        } else {
            self.colorComponents = nil
        }
    }
}

// Helper extension for safe array subscripting
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - EventKit Service Protocol

/// Protocol for EventKit services.
///
/// Enables mocking in tests.
protocol EventKitServiceProtocol: FrameworkServiceProtocol {
    /// Creates a system reminder
    func createReminder(title: String, description: String?, dueDate: Date?, calendarIdentifier: String?) async throws -> String

    /// Creates a calendar event
    func createEvent(title: String, description: String?, startDate: Date, endDate: Date, calendarIdentifier: String?) async throws -> String

    /// Gets calendar availability context
    func getAvailability() async -> CalendarContext

    /// Gets available calendars for events
    func getAvailableCalendars() async -> [CalendarInfo]

    /// Gets available reminder lists
    func getAvailableReminderLists() async -> [CalendarInfo]
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
    // MARK: - Shared Instance

    static let shared = EventKitService()

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
        var eventGranted = false
        var reminderGranted = false

        // Request FULL ACCESS to events (not just write-only)
        // This allows us to see all calendars for selection in Settings
        do {
            eventGranted = try await eventStore.requestFullAccessToEvents()
            AppLogger.debugPublic("EventKit event permission request result: \(eventGranted)", category: .context)
        } catch {
            AppLogger.error("EventKit event permission request failed: \(error.localizedDescription)", category: .context)
        }

        // Request full access to reminders (independent of event permission)
        do {
            reminderGranted = try await eventStore.requestFullAccessToReminders()
            AppLogger.debugPublic("EventKit reminder permission request result: \(reminderGranted)", category: .context)
        } catch {
            AppLogger.error("EventKit reminder permission request failed: \(error.localizedDescription)", category: .context)
        }

        // If either permission is granted, return authorized
        // The specific methods (getAvailableCalendars/ReminderLists) will check their own permissions
        if eventGranted || reminderGranted {
            AppLogger.debugPublic("EventKit overall permission: authorized", category: .context)
            return .authorized
        } else {
            AppLogger.debug("EventKit overall permission: denied", category: .context)
            return .denied
        }
    }

    // MARK: - Create Reminder

    /// Creates a system reminder.
    ///
    /// - Parameters:
    ///   - title: The reminder title
    ///   - description: Optional notes
    ///   - dueDate: Optional due date
    ///   - calendarIdentifier: Optional identifier for the reminder list to use (defaults to default list)
    /// - Returns: The reminder identifier
    /// - Throws: `ServiceError` if creation fails
    func createReminder(title: String, description: String?, dueDate: Date?, calendarIdentifier: String?) async throws -> String {
        // Always request permission - let iOS handle if already granted
        AppLogger.debug("EventKit createReminder - requesting permission", category: .context)
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            AppLogger.debugPublic("EventKit createReminder - permission granted: \(granted)", category: .context)

            if !granted {
                throw ServiceError.permissionDenied(
                    framework: .eventKit,
                    currentLevel: .denied
                )
            }
        } catch let error as ServiceError {
            throw error
        } catch {
            AppLogger.error("EventKit createReminder - permission request error: \(error.localizedDescription)", category: .context)
            throw ServiceError.permissionDenied(
                framework: .eventKit,
                currentLevel: .denied
            )
        }

        // Select calendar - use specified or default
        let selectedCalendar: EKCalendar
        if let identifier = calendarIdentifier,
           let calendar = eventStore.calendar(withIdentifier: identifier) {
            selectedCalendar = calendar
        } else if let defaultCalendar = eventStore.defaultCalendarForNewReminders() {
            selectedCalendar = defaultCalendar
        } else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "No reminder calendar found"
            )
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = description
        reminder.calendar = selectedCalendar

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
    ///   - calendarIdentifier: Optional identifier for the calendar to use (defaults to default calendar)
    /// - Returns: The event identifier
    /// - Throws: `ServiceError` if creation fails
    func createEvent(title: String, description: String?, startDate: Date, endDate: Date, calendarIdentifier: String?) async throws -> String {
        // Check and request event-specific permission
        let rawInitialStatus = EKEventStore.authorizationStatus(for: .event)
        let initialStatus = mapAuthorizationStatus(rawInitialStatus)

        AppLogger.debug("EventKit createEvent: checking event permission", category: .context)

        if !initialStatus.allowsAccess {
            // Request FULL ACCESS to events (not write-only)
            AppLogger.debug("EventKit createEvent: requesting permission", category: .context)
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                guard granted else {
                    AppLogger.debug("EventKit createEvent: permission denied by user", category: .context)
                    throw ServiceError.permissionDenied(
                        framework: .eventKit,
                        currentLevel: .denied
                    )
                }
                AppLogger.debug("EventKit createEvent: permission granted", category: .context)
            } catch let error as ServiceError {
                throw error
            } catch {
                AppLogger.error("EventKit createEvent: permission request failed: \(error.localizedDescription)", category: .context)
                throw ServiceError.permissionDenied(
                    framework: .eventKit,
                    currentLevel: initialStatus
                )
            }
        }

        // Select calendar - use specified or default
        let selectedCalendar: EKCalendar
        if let identifier = calendarIdentifier,
           let calendar = eventStore.calendar(withIdentifier: identifier) {
            selectedCalendar = calendar
        } else if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            selectedCalendar = defaultCalendar
        } else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "No calendar found"
            )
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = description
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = selectedCalendar

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

    // MARK: - Get Calendars and Lists

    /// Gets available calendars for events.
    ///
    /// - Returns: Array of calendar info that can be used for creating events
    func getAvailableCalendars() async -> [CalendarInfo] {
        // Check event-specific permission
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        let eventLevel = mapAuthorizationStatus(eventStatus)

        AppLogger.debug("EventKit: checking event permission", category: .context)

        guard eventLevel.allowsAccess else {
            AppLogger.debug("EventKit: event permission not granted", category: .context)
            return []
        }

        let calendars = eventStore.calendars(for: .event)
        AppLogger.debugPublic("EventKit: found \(calendars.count) calendars", category: .context)

        return calendars.map { CalendarInfo(calendar: $0) }
    }

    /// Gets available reminder lists.
    ///
    /// - Returns: Array of calendar info that can be used for creating reminders
    func getAvailableReminderLists() async -> [CalendarInfo] {
        // Check reminder-specific permission
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        let reminderLevel = mapAuthorizationStatus(reminderStatus)

        AppLogger.debug("EventKit: checking reminder permission", category: .context)

        guard reminderLevel.allowsAccess else {
            AppLogger.debug("EventKit: reminder permission not granted", category: .context)
            return []
        }

        let calendars = eventStore.calendars(for: .reminder)
        AppLogger.debugPublic("EventKit: found \(calendars.count) reminder lists", category: .context)
        return calendars.map { CalendarInfo(calendar: $0) }
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

    func createReminder(title: String, description: String?, dueDate: Date?, calendarIdentifier: String?) async throws -> String {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(framework: .eventKit, currentLevel: permissionStatus)
        }
        createdReminders.append((title, description, dueDate))
        return UUID().uuidString
    }

    func createEvent(title: String, description: String?, startDate: Date, endDate: Date, calendarIdentifier: String?) async throws -> String {
        guard permissionStatus.allowsAccess else {
            throw ServiceError.permissionDenied(framework: .eventKit, currentLevel: permissionStatus)
        }
        createdEvents.append((title, description, startDate, endDate))
        return UUID().uuidString
    }

    func getAvailableCalendars() async -> [CalendarInfo] {
        []
    }

    func getAvailableReminderLists() async -> [CalendarInfo] {
        []
    }

    func getAvailability() async -> CalendarContext {
        mockAvailability
    }
}
