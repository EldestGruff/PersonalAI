//
//  PersonalAIApp.swift
//  PersonalAI
//
//  Phase 3A Spec 3: App Entry Point
//  Main app structure with TabView navigation
//

import SwiftUI
import AppIntents

@main
struct PersonalAIApp: App {
    // MARK: - Persistence

    let persistenceController = PersistenceController.shared

    // MARK: - Services (Shared Instances)

    // Services are lazily initialized as static properties on their types
    // See BrowseScreen.swift for shared instance definitions

    // MARK: - Initialization

    init() {
        // Register App Shortcuts for Siri integration
        ThoughtAppShortcuts.updateAppShortcutParameters()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// MARK: - Main Tab View

/// The main tab-based navigation for the app.
struct MainTabView: View {
    @State private var selectedTab: Tab = .browse

    enum Tab: String {
        case browse
        case search
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

            // Settings tab
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
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tab.settings)
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
            contactsService: ContactsService(),
            speechService: SpeechService()
        )
    }()
}

// MARK: - Previews

#Preview("Main Tab View") {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
