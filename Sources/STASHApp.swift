//
//  STASHApp.swift
//  STASH
//
//  Phase 3A Spec 3: App Entry Point
//  Main app structure with TabView navigation
//

import SwiftUI
import AppIntents
import FoundationModels
import Combine

@main
struct STASHApp: App {
    // MARK: - Persistence

    let persistenceController = PersistenceController.shared

    // MARK: - Theme

    @State private var themeEngine = ThemeEngine.shared

    // MARK: - Services (Shared Instances)

    // Services are lazily initialized as static properties on their types
    // See BrowseScreen.swift for shared instance definitions

    // MARK: - Initialization

    init() {
        // Register App Shortcuts for Siri integration
        print("🎯 Registering \(ThoughtAppShortcuts.appShortcuts.count) App Shortcuts...")
        ThoughtAppShortcuts.updateAppShortcutParameters()
        print("✅ App Shortcuts registration complete")
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.themeEngine, themeEngine)
        }
    }
}

// MARK: - Main Tab View

/// The main tab-based navigation for the app.
struct MainTabView: View {
    @State private var selectedTab: Tab = .browse
    @State private var showVoiceCapture: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    enum Tab: String {
        case browse
        case chat
        case search
        case insights
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Browse tab
            BrowseScreen(
                viewModel: BrowseViewModel(
                    thoughtService: ThoughtService.shared,
                    fineTuningService: FineTuningService.shared
                )
            )
            .tabItem {
                Label("Thoughts", systemImage: "brain.head.profile")
            }
            .tag(Tab.browse)

            // Chat tab (iOS 26+)
            if #available(iOS 26.0, *) {
                ConversationScreen(thoughtService: ThoughtService.shared)
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    }
                    .tag(Tab.chat)
            }

            // Search tab
            SearchScreen(
                viewModel: SearchViewModel(
                    thoughtService: ThoughtService.shared
                )
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            // Insights tab
            InsightsScreen(
                viewModel: InsightsViewModel(
                    thoughtService: ThoughtService.shared
                )
            )
            .tabItem {
                Label("Insights", systemImage: "chart.xyaxis.line")
            }
            .tag(Tab.insights)

            // Settings tab
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
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tab.settings)
        }
        .fullScreenCover(isPresented: $showVoiceCapture) {
            VoiceCaptureScreen(
                viewModel: VoiceCaptureViewModel()
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkForPendingVoiceCapture()
            }
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Check for voice capture flag periodically (works when app is in foreground)
            if scenePhase == .active {
                checkForPendingVoiceCapture()
            }
        }
    }

    // MARK: - Deep Navigation

    /// Checks for pending voice capture flag from OpenVoiceCaptureIntent
    private func checkForPendingVoiceCapture() {
        let defaults = UserDefaults(suiteName: "group.com.withershins.stash")
        if defaults?.bool(forKey: "pendingVoiceCapture") == true {
            // Clear flag immediately
            defaults?.set(false, forKey: "pendingVoiceCapture")
            defaults?.synchronize()

            // Present voice capture screen
            showVoiceCapture = true
        }
    }
}

// MARK: - Permission Coordinator Shared Instance

extension PermissionCoordinator {
    static let shared: PermissionCoordinator = {
        PermissionCoordinator(
            locationService: LocationService(),
            healthKitService: HealthKitService(),
            motionService: MotionService(),
            eventKitService: EventKitService(),
            contactsService: ContactsService()
        )
    }()
}

// MARK: - Previews

#Preview("Main Tab View") {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
