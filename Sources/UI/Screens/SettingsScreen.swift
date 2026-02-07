//
//  SettingsScreen.swift
//  PersonalAI
//
//  Phase 3A Spec 3: Settings Screen
//  App configuration and permissions
//

import SwiftUI

// MARK: - Settings Screen

/// The settings screen for app configuration.
///
/// Features:
/// - Permission management
/// - Feature toggles
/// - Sync settings
/// - User statistics
struct SettingsScreen: View {
    @State var viewModel: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var thoughtUsage: SubscriptionUsage?

    var body: some View {
        NavigationStack {
            Form {
                // Subscription section
                subscriptionSection

                // Permissions section
                permissionsSection

                // Personalization section
                personalizationSection

                // Features section
                featuresSection

                // Calendar settings section
                calendarSettingsSection

                // Sync section
                syncSection

                // Stats section
                statsSection

                // About section
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallScreen()
            }
            .refreshable {
                await loadUsageAsync()
                await viewModel.updatePermissionStatus()
            }
            .onAppear {
                viewModel.onAppear()
                loadUsage()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    _Concurrency.Task {
                        await viewModel.updatePermissionStatus()
                    }
                    loadUsage()  // Reload usage when returning to app
                }
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Current tier badge
                HStack {
                    Image(systemName: subscriptionManager.status.tier == .pro ? "crown.fill" : "person.circle.fill")
                        .foregroundStyle(subscriptionManager.status.tier == .pro ? .yellow : .blue)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionManager.status.tier.displayName)
                            .font(.headline)

                        if subscriptionManager.status.tier == .free {
                            Text("50 thoughts per month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Unlimited thoughts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if subscriptionManager.status.tier == .pro {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                }

                // Usage info (if free tier)
                if subscriptionManager.status.tier == .free, let usage = thoughtUsage {
                    let remaining = usage.remainingThoughts(for: subscriptionManager.entitlements) ?? 0

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This Month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(usage.thoughtsThisMonth) / 50 thoughts")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(remaining)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(remaining < 10 ? .orange : .primary)
                        }
                    }
                }

                // Action buttons
                Divider()

                if subscriptionManager.status.tier == .free {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Upgrade to Pro")
                            Spacer()
                            Text("$4.99/mo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        _Concurrency.Task {
                            await subscriptionManager.restorePurchases()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Restore Purchases")
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Subscription")
        } footer: {
            if subscriptionManager.status.tier == .pro {
                Text("You have unlimited access to all features. Thank you for supporting PersonalAI!")
            } else {
                Text("Upgrade to Pro for unlimited thoughts, advanced analytics, and export features.")
            }
        }
    }

    // MARK: - Personalization Section

    private var personalizationSection: some View {
        Section {
            NavigationLink {
                PersonalizationScreen()
            } label: {
                HStack(spacing: 12) {
                    Text("🐿️")
                        .font(.title2)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Squirrel-Sona")
                        Text("Customize your AI companion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("AI Companion")
        } footer: {
            Text("Choose from built-in personas or create your own custom AI companion personality.")
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        Section {
            PermissionRow(
                icon: "heart.fill",
                label: "Health Data",
                description: "Energy and activity context",
                authorized: viewModel.healthKitAuthorized,
                action: viewModel.requestHealthKitPermission
            )

            PermissionRow(
                icon: "location.fill",
                label: "Location",
                description: "Location context for thoughts",
                authorized: viewModel.locationAuthorized,
                action: viewModel.requestLocationPermission
            )

            PermissionRow(
                icon: "calendar",
                label: "Calendar & Reminders",
                description: "Both event and reminder access needed",
                authorized: viewModel.eventKitAuthorized,
                action: viewModel.requestEventKitPermission
            )

            PermissionRow(
                icon: "mic.fill",
                label: "Speech Recognition",
                description: "Voice input for thoughts",
                authorized: viewModel.speechAuthorized,
                action: viewModel.requestSpeechPermission
            )

            PermissionRow(
                icon: "person.crop.circle.fill",
                label: "Contacts",
                description: "Entity linking and mentions",
                authorized: viewModel.contactsAuthorized,
                action: viewModel.requestContactsPermission
            )

            if !viewModel.allPermissionsGranted {
                Button {
                    viewModel.requestAllPermissions()
                } label: {
                    HStack {
                        Text("Enable All Permissions")
                        Spacer()
                        if viewModel.isRequestingPermission {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isRequestingPermission)
                .accessibilityIdentifier("enableAllPermissionsButton")
            }
        } header: {
            HStack {
                Text("Permissions")
                Spacer()
                Text("\(viewModel.grantedPermissionCount)/\(viewModel.totalPermissionCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } footer: {
            Text("Permissions enhance context gathering. The app works offline without any permissions, but context will be limited.")
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        Section("Features") {
            Toggle(isOn: $viewModel.enableClassification) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Classification")
                    Text("Automatically classify thoughts using AI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("autoClassificationToggle")

            Toggle(isOn: $viewModel.enableContextEnrichment) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Context Enrichment")
                    Text("Gather context like location and energy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("contextEnrichmentToggle")

            Toggle(isOn: $viewModel.enableAutoTags) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Tagging")
                    Text("Suggest tags based on classification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("autoTaggingToggle")

            Toggle(isOn: $viewModel.autoCreateReminders) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Create Reminders")
                    Text("Automatically create reminders/events from classified thoughts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("autoCreateRemindersToggle")
        }
    }

    // MARK: - Calendar Settings Section

    private var calendarSettingsSection: some View {
        Section {
            if !viewModel.eventKitAuthorized {
                Text("Enable Calendar & Reminders permission to select calendars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Calendar picker for events
                Picker("Default Calendar", selection: Binding(
                    get: { viewModel.selectedCalendarId ?? "" },
                    set: { viewModel.selectedCalendarId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Default").tag("")
                    ForEach(viewModel.availableCalendars) { calendar in
                        HStack {
                            if let components = calendar.colorComponents {
                                Circle()
                                    .fill(Color(
                                        red: components.red,
                                        green: components.green,
                                        blue: components.blue,
                                        opacity: components.alpha
                                    ))
                                    .frame(width: 10, height: 10)
                            }
                            Text(calendar.title)
                        }
                        .tag(calendar.id)
                    }
                }

                // Reminder list picker
                Picker("Default Reminder List", selection: Binding(
                    get: { viewModel.selectedReminderListId ?? "" },
                    set: { viewModel.selectedReminderListId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Default").tag("")
                    ForEach(viewModel.availableReminderLists) { calendar in
                        HStack {
                            if let components = calendar.colorComponents {
                                Circle()
                                    .fill(Color(
                                        red: components.red,
                                        green: components.green,
                                        blue: components.blue,
                                        opacity: components.alpha
                                    ))
                                    .frame(width: 10, height: 10)
                            }
                            Text(calendar.title)
                        }
                        .tag(calendar.id)
                    }
                }
            }
        } header: {
            Text("Calendar & Reminders")
        } footer: {
            Text("Choose which calendar and reminder list to use when creating events and reminders from tasks.")
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section {
            Toggle(isOn: $viewModel.autoSyncEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Sync")
                    Text("Sync thoughts to cloud automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("autoSyncToggle")

            if viewModel.autoSyncEnabled {
                HStack {
                    Text("Sync Interval")
                    Spacer()
                    Picker("", selection: $viewModel.syncInterval) {
                        Text("5 min").tag(TimeInterval(300))
                        Text("15 min").tag(TimeInterval(900))
                        Text("30 min").tag(TimeInterval(1800))
                        Text("1 hour").tag(TimeInterval(3600))
                    }
                    .pickerStyle(.menu)
                }
            }
        } header: {
            Text("Sync")
        } footer: {
            Text("Note: Cloud sync is not implemented in Phase 3A. This setting will take effect in future updates.")
        }
    }

    // MARK: - Helper Functions

    private func loadUsage() {
        _Concurrency.Task {
            await loadUsageAsync()
        }
    }

    private func loadUsageAsync() async {
        let thoughts = try? await ThoughtService.shared.list(filter: nil)
        if let thoughts = thoughts {
            thoughtUsage = SubscriptionUsage.calculate(from: thoughts)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section("Your Stats") {
            if viewModel.isLoadingStats {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                StatRow(label: "Total Thoughts", value: "\(viewModel.totalThoughts)")
                StatRow(label: "This Week", value: "\(viewModel.thisWeekCount)")
                StatRow(label: "Today", value: "\(viewModel.todayCount)")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("3.0.0-alpha (Phase 3A)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text("Spec 3 - UI & ViewModels")
                    .foregroundColor(.secondary)
            }

            NavigationLink {
                PrivacyInfoView()
            } label: {
                Text("Privacy Information")
            }
        }
    }
}

// MARK: - Permission Row

/// A row for displaying and requesting a permission.
struct PermissionRow: View {
    let icon: String
    let label: String
    let description: String
    let authorized: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(authorized ? .green : .secondary)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label). \(description)")

            Spacer()

            if authorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel("Authorized")
                // Still allow re-requesting even when authorized
                // (some frameworks like EventKit have multiple sub-permissions)
                Button("Re-request") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("\(permissionIdentifier)RerequestButton")
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("\(permissionIdentifier)EnableButton")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(label) permission")
        .accessibilityValue(authorized ? "Authorized" : "Not authorized")
    }

    private var permissionIdentifier: String {
        label.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "&", with: "")
    }
}

// MARK: - Stat Row

/// A row for displaying a statistic.
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Privacy Info View

/// Privacy information screen.
struct PrivacyInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Information")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Personal AI is designed with privacy first.")
                    .font(.headline)

                Group {
                    Text("Data Storage")
                        .font(.headline)
                    Text("All your thoughts are stored locally on your device using Core Data. No data is sent to external servers in Phase 3A.")
                }

                Group {
                    Text("Permissions")
                        .font(.headline)
                    Text("Permissions are used solely to enrich context. Location data, health data, and other information is never shared and only used to provide context for your thoughts.")
                }

                Group {
                    Text("Classification")
                        .font(.headline)
                    Text("All classification is done on-device using Apple's Natural Language framework. No thought content is sent to external AI services.")
                }

                Group {
                    Text("Future Updates")
                        .font(.headline)
                    Text("Cloud sync (Phase 4+) will use end-to-end encryption. You will always have full control over what data is synced.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Previews

#Preview("Settings Screen") {
    SettingsScreen(
        viewModel: SettingsViewModel(
            healthKitService: HealthKitService(),
            locationService: LocationService(),
            eventKitService: EventKitService(),
            contactsService: ContactsService(),
            thoughtService: ThoughtService.shared,
            permissionCoordinator: PermissionCoordinator.shared
        )
    )
}
