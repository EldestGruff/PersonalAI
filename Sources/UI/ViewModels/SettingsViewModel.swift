//
//  SettingsViewModel.swift
//  PersonalAI
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
    var healthKitAuthorized: Bool = false

    /// Whether Location is authorized
    var locationAuthorized: Bool = false

    /// Whether EventKit (Calendar/Reminders) is authorized
    var eventKitAuthorized: Bool = false

    /// Whether Speech Recognition is authorized
    var speechAuthorized: Bool = false

    /// Whether Contacts is authorized
    var contactsAuthorized: Bool = false

    // MARK: - Feature Settings

    /// Whether auto-classification is enabled
    var enableClassification: Bool = true

    /// Whether context enrichment is enabled
    var enableContextEnrichment: Bool = true

    /// Whether auto-tagging from classification is enabled
    var enableAutoTags: Bool = true

    /// Whether to automatically create reminders/events from classified thoughts
    var autoCreateReminders: Bool = false

    /// Whether auto-sync is enabled
    var autoSyncEnabled: Bool = true

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
    private let speechService: SpeechService
    private let contactsService: ContactsService
    private let thoughtService: ThoughtService
    private let permissionCoordinator: PermissionCoordinator

    // MARK: - Initialization

    init(
        healthKitService: HealthKitService,
        locationService: LocationService,
        eventKitService: EventKitService,
        speechService: SpeechService,
        contactsService: ContactsService,
        thoughtService: ThoughtService,
        permissionCoordinator: PermissionCoordinator
    ) {
        self.healthKitService = healthKitService
        self.locationService = locationService
        self.eventKitService = eventKitService
        self.speechService = speechService
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

        healthKitAuthorized = summary.healthKit.allowsAccess
        locationAuthorized = summary.location.allowsAccess
        eventKitAuthorized = summary.eventKit.allowsAccess
        speechAuthorized = summary.speech.allowsAccess
        contactsAuthorized = summary.contacts.allowsAccess
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

    /// Requests Speech permission
    func requestSpeechPermission() {
        requestPermission { [weak self] in
            _ = await self?.speechService.requestPermission()
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
        healthKitAuthorized &&
        locationAuthorized &&
        eventKitAuthorized &&
        speechAuthorized &&
        contactsAuthorized
    }

    /// Number of permissions granted
    var grantedPermissionCount: Int {
        [healthKitAuthorized, locationAuthorized, eventKitAuthorized, speechAuthorized, contactsAuthorized]
            .filter { $0 }.count
    }

    /// Total number of permissions
    var totalPermissionCount: Int { 5 }

    /// Formatted sync interval for display
    var syncIntervalFormatted: String {
        let minutes = Int(syncInterval / 60)
        return "\(minutes) min"
    }

    // MARK: - Calendar Loading

    /// Loads available calendars and reminder lists
    func loadCalendars() async {
        guard eventKitAuthorized else { return }

        // Load calendars for events
        availableCalendars = await eventKitService.getAvailableCalendars()

        // Load reminder lists
        availableReminderLists = await eventKitService.getAvailableReminderLists()
    }
}
