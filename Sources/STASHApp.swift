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
import UserNotifications

@main
struct STASHApp: App {
    // MARK: - Persistence

    let persistenceController = PersistenceController.shared

    // MARK: - Theme

    @State private var themeEngine = ThemeEngine.shared

    // MARK: - Onboarding

    @State private var showOnboarding = false
    @State private var isReplayOnboarding = false

    // MARK: - Services (Shared Instances)

    // Services are lazily initialized as static properties on their types
    // See BrowseScreen.swift for shared instance definitions

    // MARK: - Initialization

    init() {
        // Register App Shortcuts for Siri integration
        print("🎯 Registering \(ThoughtAppShortcuts.appShortcuts.count) App Shortcuts...")
        ThoughtAppShortcuts.updateAppShortcutParameters()
        print("✅ App Shortcuts registration complete")

        // Register notification delegate for deep link handling
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Activate WatchConnectivity to receive thoughts from Apple Watch
        PhoneConnectivityManager.shared.activate()

        // Initialize analytics (respects user opt-out from UserDefaults)
        AnalyticsService.shared.initialize()

        // Migrate gamification state and preferences from UserDefaults to iCloud KV Store.
        // Runs exactly once per device (guarded by migration flag). Must run before
        // any service reads from SyncedDefaults.
        SyncedDefaultsMigration.migrateIfNeeded(context: PersistenceController.shared.container.viewContext)

        // Check if onboarding should be shown
        let hasCompleted = OnboardingViewModel.hasCompletedOnboarding()
        self._showOnboarding = State(initialValue: !hasCompleted)
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.themeEngine, themeEngine)
                .preferredColorScheme(themeEngine.getCurrentTheme().preferredColorScheme)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingScreen(
                        viewModel: OnboardingViewModel(
                            isReplay: isReplayOnboarding,
                            captureViewModel: CaptureViewModel(
                                thoughtService: ThoughtService.shared,
                                contextService: ContextService.shared,
                                classificationService: ClassificationService.shared,
                                fineTuningService: FineTuningService.shared,
                                taskService: TaskService.shared
                            ),
                            onComplete: {
                                showOnboarding = false
                                isReplayOnboarding = false
                            }
                        )
                    )
                }
                .interactiveDismissDisabled(showOnboarding)
                .onReceive(NotificationCenter.default.publisher(for: .replayOnboarding)) { _ in
                    _Concurrency.Task { @MainActor in
                        OnboardingViewModel.resetOnboarding()
                        isReplayOnboarding = true
                        showOnboarding = true
                    }
                }
        }
    }
}

// MARK: - Main Tab View

/// The main tab-based navigation for the app.
struct MainTabView: View {
    @State private var selectedTab: Tab = .browse
    @State private var showVoiceCapture: Bool = false
    @State private var showCaptureFromNotification: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    enum Tab: String {
        case browse
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
        .sheet(isPresented: $showCaptureFromNotification) {
            CaptureScreen(
                viewModel: CaptureViewModel(
                    thoughtService: ThoughtService.shared,
                    contextService: ContextService.shared,
                    classificationService: ClassificationService.shared,
                    fineTuningService: FineTuningService.shared,
                    taskService: TaskService.shared
                )
            )
        }
        .onReceive(NotificationDelegate.shared.$openCapture) { shouldOpen in
            if shouldOpen {
                showCaptureFromNotification = true
                NotificationDelegate.shared.openCapture = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                StreakTracker.shared.onAppForeground()
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

// MARK: - Notification Delegate

/// Handles notification tap responses and routes deep links to the capture screen.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject, @unchecked Sendable {
    static let shared = NotificationDelegate()

    @Published var openCapture: Bool = false

    // Display notifications even when app is foregrounded
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle notification tap — deep link to capture screen
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let deeplink = userInfo["deeplink"] as? String, deeplink == "stash://capture" {
            DispatchQueue.main.async { self.openCapture = true }
        }
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let replayOnboarding = Notification.Name("replayOnboarding")
}

// MARK: - Previews

#Preview("Main Tab View") {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
