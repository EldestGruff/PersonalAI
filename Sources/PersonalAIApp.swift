//
//  PersonalAIApp.swift
//  PersonalAI
//
//  Phase 3A Spec 3: App Entry Point
//  Main app structure with TabView navigation
//

import SwiftUI
import AppIntents
import FoundationModels

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
