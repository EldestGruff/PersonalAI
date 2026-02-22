//
//  SettingsScreen.swift
//  STASH
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
    @State private var themeEngine = ThemeEngine.shared

    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var thoughtUsage: SubscriptionUsage?

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                Form {
                    // Subscription section
                    subscriptionSection

                    // Permissions section
                    permissionsSection

                    // Notifications section
                    notificationsSection

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

                    // Onboarding section
                    onboardingSection

                    // About section
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        let theme = themeEngine.getCurrentTheme()
        return Section {
            VStack(alignment: .leading, spacing: 12) {
                // Current tier badge
                HStack {
                    Image(systemName: subscriptionManager.status.tier == .pro ? "crown.fill" : "person.circle.fill")
                        .foregroundStyle(subscriptionManager.status.tier == .pro ? theme.warningColor : theme.primaryColor)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionManager.status.tier.displayName)
                            .font(.headline)
                            .foregroundStyle(theme.textColor)

                        if subscriptionManager.status.tier == .free {
                            Text("50 thoughts per month")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                        } else {
                            Text("Unlimited thoughts")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                    }

                    Spacer()

                    if subscriptionManager.status.tier == .pro {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(theme.successColor)
                            .font(.title3)
                    }
                }

                // Usage info (if free tier)
                if subscriptionManager.status.tier == .free, let usage = thoughtUsage {
                    let remaining = usage.remainingThoughts(for: subscriptionManager.entitlements) ?? 0

                    Divider()
                        .background(theme.dividerColor)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This Month")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                            Text("\(usage.thoughtsThisMonth) / 50 thoughts")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(theme.textColor)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                            Text("\(remaining)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(remaining < 10 ? theme.warningColor : theme.textColor)
                        }
                    }
                }

                // Action buttons
                Divider()
                    .background(theme.dividerColor)

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
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .themedToggle(theme)
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
                    .themedToggle(theme)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Subscription")
                .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            if subscriptionManager.status.tier == .pro {
                Text("You have unlimited access to all features. Thank you for supporting STASH!")
                    .foregroundStyle(theme.secondaryTextColor)
            } else {
                Text("Upgrade to Pro for unlimited thoughts, advanced analytics, and export features.")
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - Notifications Section

    @State private var reminderService = SquirrelReminderService.shared

    private var notificationsSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
            // Master toggle — requests permission on first enable
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(theme.primaryColor)
                    .frame(width: 28)
                Toggle(isOn: Binding(
                    get: { reminderService.notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            _Concurrency.Task {
                                _ = await reminderService.requestPermission()
                            }
                        } else {
                            reminderService.notificationsEnabled = false
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Squirrel Reminders")
                            .foregroundStyle(theme.textColor)
                        Text(reminderService.authorizationStatus == .denied
                             ? "Blocked in Settings — tap to open"
                             : "Persona-voiced nudges from your squirrelsona")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
                .themedToggle(theme)
                .onChange(of: reminderService.notificationsEnabled) { _, _ in
                    reminderService.rescheduleAll()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if reminderService.authorizationStatus == .denied {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if reminderService.notificationsEnabled {
                ForEach(SquirrelNotificationType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.displayIcon)
                            .foregroundStyle(theme.secondaryTextColor)
                            .frame(width: 28)
                        Toggle(isOn: Binding(
                            get: { reminderService.isEnabled(type) },
                            set: { reminderService.setEnabled(type, $0) }
                        )) {
                            Text(type.displayName)
                                .foregroundStyle(theme.textColor)
                        }
                        .themedToggle(theme)
                    }
                }
            }
        } header: {
            Text("Notifications")
                .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            Text("Timing is based on when you usually capture. Max 1 notification per day.")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
        .task { await reminderService.refreshAuthorizationStatus() }
    }

    // MARK: - Personalization Section

    private var personalizationSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
            NavigationLink {
                PersonalizationScreen()
            } label: {
                HStack(spacing: 12) {
                    Text("\u{1F43F}\u{FE0F}")
                        .font(.title2)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Squirrel-Sona")
                            .foregroundStyle(theme.textColor)
                        Text("Customize your AI companion")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
        } header: {
            Text("AI Companion")
                .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            Text("Choose from built-in personas or create your own custom AI companion personality.")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
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
                            .foregroundStyle(theme.primaryColor)
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
                    .foregroundColor(theme.secondaryTextColor)
            }
            .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            Text("Permissions enhance context gathering. The app works offline without any permissions, but context will be limited.")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
            Toggle(isOn: $viewModel.enableClassification) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Classification")
                        .foregroundStyle(theme.textColor)
                    Text("Automatically classify thoughts using AI")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .themedToggle(theme)
            .accessibilityIdentifier("autoClassificationToggle")

            Toggle(isOn: $viewModel.enableContextEnrichment) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Context Enrichment")
                        .foregroundStyle(theme.textColor)
                    Text("Gather context like location and energy")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .themedToggle(theme)
            .accessibilityIdentifier("contextEnrichmentToggle")

            Toggle(isOn: $viewModel.enableAutoTags) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Tagging")
                        .foregroundStyle(theme.textColor)
                    Text("Suggest tags based on classification")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .themedToggle(theme)
            .accessibilityIdentifier("autoTaggingToggle")

            Toggle(isOn: $viewModel.autoCreateReminders) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Create Reminders")
                        .foregroundStyle(theme.textColor)
                    Text("Automatically create reminders/events from classified thoughts")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .themedToggle(theme)
            .accessibilityIdentifier("autoCreateRemindersToggle")
        } header: {
            Text("Features")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - Calendar Settings Section

    private var calendarSettingsSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
            if !viewModel.eventKitAuthorized {
                Text("Enable Calendar & Reminders permission to select calendars")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
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
                .foregroundStyle(theme.textColor)
                .themedToggle(theme)

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
                .foregroundStyle(theme.textColor)
                .themedToggle(theme)
            }
        } header: {
            Text("Calendar & Reminders")
                .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            Text("Choose which calendar and reminder list to use when creating events and reminders from tasks.")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
            Toggle(isOn: $viewModel.autoSyncEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Sync")
                        .foregroundStyle(theme.textColor)
                    Text("Sync thoughts to cloud automatically")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .themedToggle(theme)
            .accessibilityIdentifier("autoSyncToggle")

            if viewModel.autoSyncEnabled {
                HStack {
                    Text("Sync Interval")
                        .foregroundStyle(theme.textColor)
                    Spacer()
                    Picker("", selection: $viewModel.syncInterval) {
                        Text("5 min").tag(TimeInterval(300))
                        Text("15 min").tag(TimeInterval(900))
                        Text("30 min").tag(TimeInterval(1800))
                        Text("1 hour").tag(TimeInterval(3600))
                    }
                    .pickerStyle(.menu)
                    .themedToggle(theme)
                }
            }
        } header: {
            Text("Sync")
                .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            Text("Note: Cloud sync is not implemented in Phase 3A. This setting will take effect in future updates.")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
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
        let theme = themeEngine.getCurrentTheme()
        return Section {
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
        } header: {
            Text("Your Stats")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - Onboarding Section

    private var onboardingSection: some View {
        let theme = themeEngine.getCurrentTheme()
        return Section {
            Button {
                NotificationCenter.default.post(name: .replayOnboarding, object: nil)
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(theme.primaryColor)
                    Text("Replay Onboarding")
                        .foregroundStyle(theme.textColor)
                }
            }
        } header: {
            Text("Tutorial")
                .foregroundStyle(theme.secondaryTextColor)
        } footer: {
            Text("Replay the first-run tutorial to see the onboarding experience again.")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        let theme = themeEngine.getCurrentTheme()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return Section {
            HStack {
                Text("Version")
                    .foregroundStyle(theme.textColor)
                Spacer()
                Text(version)
                    .foregroundColor(theme.secondaryTextColor)
            }

            HStack {
                Text("Build")
                    .foregroundStyle(theme.textColor)
                Spacer()
                Text(build)
                    .foregroundColor(theme.secondaryTextColor)
            }

            NavigationLink {
                PrivacyInfoView()
            } label: {
                Text("Privacy Information")
                    .foregroundStyle(theme.textColor)
            }
        } header: {
            Text("About")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(theme.surfaceColor)
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
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(authorized ? theme.successColor : theme.secondaryTextColor)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .foregroundStyle(theme.textColor)
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label). \(description)")

            Spacer()

            if authorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.successColor)
                    .accessibilityLabel("Authorized")
                // Still allow re-requesting even when authorized
                // (some frameworks like EventKit have multiple sub-permissions)
                Button("Re-request") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .foregroundColor(theme.secondaryTextColor)
                .accessibilityIdentifier("\(permissionIdentifier)RerequestButton")
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .themedToggle(theme)
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
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        HStack {
            Text(label)
                .foregroundStyle(theme.textColor)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(theme.primaryColor)
        }
    }
}

// MARK: - Privacy Info View

/// Privacy information screen.
struct PrivacyInfoView: View {
    @State private var themeEngine = ThemeEngine.shared
    @State private var isOptedOut = AnalyticsService.shared.isOptedOut

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Information")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)

                    Text("Personal AI is designed with privacy first.")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)

                    Group {
                        Text("Usage Analytics")
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text("STASH collects anonymous metadata about how app features are used — for example, which screens you visit and whether you use voice or text capture. No thought content, tags, health data, or personal information ever leaves your device. This telemetry is used solely to understand which features are working well and where the app can improve.")
                            .foregroundStyle(theme.secondaryTextColor)
                        Toggle(isOn: Binding(
                            get: { !AnalyticsService.shared.isOptedOut },
                            set: { newValue in
                                AnalyticsService.shared.isOptedOut = !newValue
                                isOptedOut = !newValue
                            }
                        )) {
                            Text("Share anonymous usage data")
                                .foregroundStyle(theme.textColor)
                        }
                        .themedToggle(theme)
                        if isOptedOut {
                            Text("Usage data will no longer be collected.")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                    }

                    Group {
                        Text("Data Storage")
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text("All your thoughts are stored locally on your device using Core Data. No data is sent to external servers in Phase 3A.")
                            .foregroundStyle(theme.secondaryTextColor)
                    }

                    Group {
                        Text("Permissions")
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text("Permissions are used solely to enrich context. Location data, health data, and other information is never shared and only used to provide context for your thoughts.")
                            .foregroundStyle(theme.secondaryTextColor)
                    }

                    Group {
                        Text("Classification")
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text("All classification is done on-device using Apple's Natural Language framework. No thought content is sent to external AI services.")
                            .foregroundStyle(theme.secondaryTextColor)
                    }

                    Group {
                        Text("Future Updates")
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text("Cloud sync (Phase 4+) will use end-to-end encryption. You will always have full control over what data is synced.")
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Privacy")
        .toolbarBackground(theme.surfaceColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
