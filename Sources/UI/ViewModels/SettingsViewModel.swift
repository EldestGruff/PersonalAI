//
//  SettingsViewModel.swift
//  STASH
//
//  Phase 3A Spec 3: Settings ViewModel
//  Manages app configuration and permission states
//

import Foundation
import Observation

// MARK: - Settings ViewModel

/// ViewModel for the settings screen.
///
/// Manages:
/// - Permission status and requests
/// - Feature toggles
/// - User statistics
@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - Permission State

    /// Whether HealthKit is authorized
    var isHealthKitAuthorized: Bool = false

    /// Whether Location is authorized
    var isLocationAuthorized: Bool = false

    /// Whether EventKit (Calendar/Reminders) is authorized
    var isEventKitAuthorized: Bool = false

    /// Whether Contacts is authorized
    var isContactsAuthorized: Bool = false

    // MARK: - Feature Settings

    /// Whether auto-classification is enabled
    var isClassificationEnabled: Bool = true

    /// Whether context enrichment is enabled
    var isContextEnrichmentEnabled: Bool = true

    /// Whether auto-tagging from classification is enabled
    var isAutoTagsEnabled: Bool = true

    /// Whether to automatically create reminders/events from classified thoughts
    ///
    /// When false (default), a confirmation dialog is shown before creating. Persisted to UserDefaults.
    var autoCreateReminders: Bool {
        get { _autoCreateRemindersCache }
        set {
            _autoCreateRemindersCache = newValue
            UserDefaults.standard.set(newValue, forKey: "autoCreateReminders")
        }
    }

    private var _autoCreateRemindersCache: Bool = false

    /// Whether auto-sync is enabled
    var isAutoSyncEnabled: Bool = true

    /// Sync interval in seconds (default 15 minutes)
    var syncInterval: TimeInterval = 900

    // MARK: - Calendar Settings

    /// Selected calendar identifier for events (nil = use default)
    var selectedCalendarId: String? {
        get {
            _selectedCalendarIdCache
        }
        set {
            _selectedCalendarIdCache = newValue
            UserDefaults.standard.set(newValue, forKey: "selectedCalendarId")
        }
    }

    private var _selectedCalendarIdCache: String?

    /// Selected reminder list identifier (nil = use default)
    var selectedReminderListId: String? {
        get {
            _selectedReminderListIdCache
        }
        set {
            _selectedReminderListIdCache = newValue
            UserDefaults.standard.set(newValue, forKey: "selectedReminderListId")
        }
    }

    private var _selectedReminderListIdCache: String?

    /// Available calendars for events
    var availableCalendars: [CalendarInfo] = []

    /// Available reminder lists
    var availableReminderLists: [CalendarInfo] = []

    // MARK: - User Stats

    /// Total number of thoughts
    var totalThoughts: Int = 0

    /// Thoughts created this week
    var thisWeekCount: Int = 0

    /// Thoughts created today
    var todayCount: Int = 0

    // MARK: - Loading State

    /// Whether stats are loading
    var isLoadingStats: Bool = false

    /// Whether permission update is in progress
    var isRequestingPermission: Bool = false

    // MARK: - Services

    private let healthKitService: HealthKitService
    private let locationService: LocationService
    private let eventKitService: EventKitService
    private let contactsService: ContactsService
    private let thoughtService: ThoughtService
    private let permissionCoordinator: PermissionCoordinator

    // MARK: - Initialization

    init(
        healthKitService: HealthKitService,
        locationService: LocationService,
        eventKitService: EventKitService,
        contactsService: ContactsService,
        thoughtService: ThoughtService,
        permissionCoordinator: PermissionCoordinator
    ) {
        self.healthKitService = healthKitService
        self.locationService = locationService
        self.eventKitService = eventKitService
        self.contactsService = contactsService
        self.thoughtService = thoughtService
        self.permissionCoordinator = permissionCoordinator
    }

    // MARK: - Lifecycle

    /// Loads initial data
    func onAppear() {
        // Load cached settings from UserDefaults
        _selectedCalendarIdCache = UserDefaults.standard.string(forKey: "selectedCalendarId")
        _selectedReminderListIdCache = UserDefaults.standard.string(forKey: "selectedReminderListId")
        _autoCreateRemindersCache = UserDefaults.standard.bool(forKey: "autoCreateReminders")

        _Concurrency.Task {
            await updatePermissionStatus()
            await loadStats()
            await loadCalendars()
        }
    }

    // MARK: - Permission Status

    /// Updates all permission statuses
    func updatePermissionStatus() async {
        let summary = await permissionCoordinator.refreshStatus()

        isHealthKitAuthorized = summary.healthKit.allowsAccess
        isLocationAuthorized = summary.location.allowsAccess
        isEventKitAuthorized = summary.eventKit.allowsAccess
        isContactsAuthorized = summary.contacts.allowsAccess
    }

    // MARK: - Permission Requests

    /// Requests HealthKit permission
    func requestHealthKitPermission() {
        requestPermission { [weak self] in
            _ = await self?.healthKitService.requestPermission()
        }
    }

    /// Requests Location permission
    func requestLocationPermission() {
        requestPermission { [weak self] in
            _ = await self?.locationService.requestPermission()
        }
    }

    /// Requests EventKit permission
    func requestEventKitPermission() {
        requestPermission { [weak self] in
            _ = await self?.eventKitService.requestPermission()
        }
    }

    /// Requests Contacts permission
    func requestContactsPermission() {
        requestPermission { [weak self] in
            _ = await self?.contactsService.requestPermission()
        }
    }

    /// Requests all permissions (onboarding flow)
    func requestAllPermissions() {
        requestPermission { [weak self] in
            _ = await self?.permissionCoordinator.requestAllPermissions()
        }
    }

    private func requestPermission(_ request: @escaping () async -> Void) {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true

        _Concurrency.Task {
            await request()
            await updatePermissionStatus()
            isRequestingPermission = false
        }
    }

    // MARK: - Stats

    /// Loads user statistics
    func loadStats() async {
        isLoadingStats = true

        do {
            // Get all thoughts
            let thoughts = try await thoughtService.list(filter: nil)

            totalThoughts = thoughts.count

            // Calculate this week's count
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            thisWeekCount = thoughts.filter { $0.createdAt >= weekAgo }.count

            // Calculate today's count
            let startOfDay = calendar.startOfDay(for: Date())
            todayCount = thoughts.filter { $0.createdAt >= startOfDay }.count

        } catch {
            // Silently fail - stats are nice-to-have
        }

        isLoadingStats = false
    }

    // MARK: - Computed Properties

    /// Whether all permissions are granted
    var allPermissionsGranted: Bool {
        isHealthKitAuthorized &&
        isLocationAuthorized &&
        isEventKitAuthorized &&
        isContactsAuthorized
    }

    /// Number of permissions granted
    var grantedPermissionCount: Int {
        [isHealthKitAuthorized, isLocationAuthorized, isEventKitAuthorized, isContactsAuthorized]
            .filter { $0 }.count
    }

    /// Total number of permissions
    var totalPermissionCount: Int { 4 }

    /// Formatted sync interval for display
    var syncIntervalFormatted: String {
        let minutes = Int(syncInterval / 60)
        return "\(minutes) min"
    }

    // MARK: - Calendar Loading

    /// Loads available calendars and reminder lists
    func loadCalendars() async {
        AppLogger.debug("SettingsViewModel: loadCalendars called", category: .general)
        guard isEventKitAuthorized else {
            AppLogger.debug("SettingsViewModel: EventKit not authorized, skipping calendar load", category: .general)
            return
        }

        // Load calendars for events
        availableCalendars = await eventKitService.getAvailableCalendars()
        AppLogger.debugPublic("SettingsViewModel: loaded \(availableCalendars.count) calendars", category: .general)

        // Load reminder lists
        availableReminderLists = await eventKitService.getAvailableReminderLists()
        AppLogger.debugPublic("SettingsViewModel: loaded \(availableReminderLists.count) reminder lists", category: .general)

        // Validate selected calendar - clear if it's not in the available list
        if let selectedId = selectedCalendarId,
           !availableCalendars.contains(where: { $0.id == selectedId }) {
            AppLogger.debug("SettingsViewModel: selected calendar not found, clearing", category: .general)
            selectedCalendarId = nil
        }

        // Validate selected reminder list - clear if it's not in the available list
        if let selectedId = selectedReminderListId,
           !availableReminderLists.contains(where: { $0.id == selectedId }) {
            AppLogger.debug("SettingsViewModel: selected reminder list not found, clearing", category: .general)
            selectedReminderListId = nil
        }
    }
}
