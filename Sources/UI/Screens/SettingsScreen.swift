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

    var body: some View {
        NavigationStack {
            Form {
                // Permissions section
                permissionsSection

                // Features section
                featuresSection

                // Sync section
                syncSection

                // Stats section
                statsSection

                // About section
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.onAppear()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    _Concurrency.Task {
                        await viewModel.updatePermissionStatus()
                    }
                }
            }
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
                description: "Schedule context and task creation",
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

            Toggle(isOn: $viewModel.enableContextEnrichment) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Context Enrichment")
                    Text("Gather context like location and energy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $viewModel.enableAutoTags) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Tagging")
                    Text("Suggest tags based on classification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $viewModel.autoCreateReminders) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Create Reminders")
                    Text("Automatically create reminders/events from classified thoughts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if authorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
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
            speechService: SpeechService(),
            contactsService: ContactsService(),
            thoughtService: ThoughtService.shared,
            permissionCoordinator: PermissionCoordinator.shared
        )
    )
}
