//
//  OnboardingViewModel.swift
//  STASH
//
//  Onboarding issue #46: Squirrel-Led First-Run Walkthrough
//  State machine managing step progression through interactive tutorial
//

import Foundation
import Observation
import SwiftUI

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome       = 0
    case personaPicker = 1
    case firstCapture  = 2
    case acornExplainer = 3
    case streakIntro   = 4
    case permissions   = 5
    case notifications = 6
    case futureTeaser  = 7
    case siriSetup     = 8
    case completion    = 9

    var canSkip: Bool {
        switch self {
        case .completion:
            return false // Must complete to exit
        default:
            return true
        }
    }

    var showProgressDots: Bool {
        // Hide dots on welcome and completion for cleaner UI
        return self != .welcome && self != .completion
    }
}

// MARK: - Onboarding View Model

@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - State

    /// Current onboarding step
    var currentStep: OnboardingStep = .welcome

    /// Selected persona (persists immediately on selection)
    var selectedPersona: SquirrelPersona = .default

    /// Whether capture was completed successfully
    var captureDidComplete: Bool = false

    /// Permission toggle states (for notifications step)
    var notificationTypesEnabled: [SquirrelNotificationType: Bool] = [:]

    /// Context permission states (for permissions step)
    var didRequestLocation: Bool = false
    var didRequestCalendar: Bool = false
    var didRequestContacts: Bool = false

    // MARK: - Services

    private let personaService: PersonaService
    private let permissionCoordinator: PermissionCoordinator
    private let reminderService: SquirrelReminderService
    private let onComplete: () -> Void

    // Embedded CaptureViewModel for step 3 (real capture)
    let captureViewModel: CaptureViewModel

    /// Whether this is a replay of the tutorial (skips firstCapture step)
    let isReplay: Bool

    // MARK: - Initialization

    init(
        isReplay: Bool = false,
        personaService: PersonaService = .shared,
        permissionCoordinator: PermissionCoordinator = .shared,
        reminderService: SquirrelReminderService = .shared,
        captureViewModel: CaptureViewModel,
        onComplete: @escaping () -> Void
    ) {
        self.isReplay = isReplay
        self.personaService = personaService
        self.permissionCoordinator = permissionCoordinator
        self.reminderService = reminderService
        self.captureViewModel = captureViewModel
        self.onComplete = onComplete

        // Initialize notification toggles with defaults
        for type in SquirrelNotificationType.allCases {
            notificationTypesEnabled[type] = type.defaultEnabled
        }

        // Start with current default persona
        self.selectedPersona = personaService.defaultPersona
    }

    // MARK: - Navigation

    /// Advance to next step
    func advance() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            // Reached the end
            completeOnboarding()
            return
        }

        // Skip firstCapture when replaying — user has already done this
        if nextStep == .firstCapture && isReplay {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .acornExplainer
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextStep
        }
    }

    /// Go back to previous step
    func goBack() {
        guard currentStep.rawValue > 0,
              let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = previousStep
        }
    }

    /// Skip current step and advance
    func skip() {
        guard currentStep.canSkip else { return }
        advance()
    }

    // MARK: - Step Actions

    /// Handle persona selection (Step 2)
    func selectPersona(_ persona: SquirrelPersona) {
        selectedPersona = persona
        personaService.setDefaultPersona(persona)
        AnalyticsService.shared.track(.personaSelected(persona: persona.name))

        // Auto-advance after short delay for feedback
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(for: .milliseconds(500))
            self.advance()
        }
    }

    /// Handle capture completion (Step 3)
    func completeCapture() {
        captureDidComplete = true

        // Auto-advance after acorn toast shows (1.5s delay)
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(for: .milliseconds(1500))
            self.advance()
        }
    }

    /// Request context permissions (Step 6)
    func requestContextPermissions() async {
        // Request all context permissions in sequence
        if !didRequestLocation {
            _ = await permissionCoordinator.requestPermission(for: .coreLocation)
            didRequestLocation = true
        }

        if !didRequestCalendar {
            _ = await permissionCoordinator.requestPermission(for: .eventKit)
            didRequestCalendar = true
        }

        if !didRequestContacts {
            _ = await permissionCoordinator.requestPermission(for: .contacts)
            didRequestContacts = true
        }
    }

    /// Enable notifications with selected types (Step 7)
    func enableNotifications() async {
        let granted = await reminderService.requestPermission()

        if granted {
            // Apply toggle states to reminder service
            for (type, enabled) in notificationTypesEnabled {
                reminderService.setEnabled(type, enabled)
            }
        }
    }

    // MARK: - Completion

    /// Complete onboarding and set persistence flag
    func completeOnboarding() {
        // Set completion flag
        UserDefaults.standard.set(true, forKey: "onboarding.completed")
        AnalyticsService.shared.track(.onboardingCompleted(stepsCompleted: currentStep.rawValue))

        // Call completion handler (dismisses onboarding)
        onComplete()
    }

    // MARK: - Persistence Helpers

    /// Check if onboarding has been completed
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "onboarding.completed")
    }

    /// Reset onboarding completion (for replay from Settings)
    static func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "onboarding.completed")
    }
}
