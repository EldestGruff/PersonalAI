//
//  OnboardingScreen.swift
//  STASH
//
//  Onboarding issue #46: Squirrel-Led First-Run Walkthrough
//  Container screen that routes between onboarding steps
//

import SwiftUI

// MARK: - Onboarding Screen

struct OnboardingScreen: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button (show when not on first step)
                if viewModel.currentStep.rawValue > 0 {
                    HStack {
                        Button {
                            viewModel.goBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                Text("Back")
                            }
                            .foregroundStyle(theme.primaryColor)
                        }
                        .padding(.leading, 16)

                        Spacer()
                    }
                    .padding(.top, 12)
                    .transition(.opacity)
                }

                // Progress dots (hide on welcome and completion)
                if viewModel.currentStep.showProgressDots {
                    ProgressDotsView(
                        currentStep: viewModel.currentStep.rawValue,
                        totalSteps: OnboardingStep.allCases.count
                    )
                    .padding(.top, viewModel.currentStep.rawValue > 0 ? 8 : 20)
                    .padding(.bottom, 12)
                }

                // Step content
                stepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .preferredColorScheme(theme.preferredColorScheme)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Step Routing

    @ViewBuilder
    private var stepView: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView(viewModel: viewModel)
        case .personaPicker:
            PersonaPickerStepView(viewModel: viewModel)
        case .firstCapture:
            FirstCaptureStepView(viewModel: viewModel)
        case .acornExplainer:
            AcornExplainerStepView(viewModel: viewModel)
        case .streakIntro:
            StreakIntroStepView(viewModel: viewModel)
        case .permissions:
            PermissionsStepView(viewModel: viewModel)
        case .notifications:
            NotificationsStepView(viewModel: viewModel)
        case .futureTeaser:
            FutureTeaserStepView(viewModel: viewModel)
        case .completion:
            CompletionStepView(viewModel: viewModel)
        }
    }
}

// MARK: - Progress Dots

struct ProgressDotsView: View {
    let currentStep: Int
    let totalSteps: Int
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? theme.primaryColor : theme.secondaryTextColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding Screen") {
    OnboardingScreen(
        viewModel: OnboardingViewModel(
            captureViewModel: CaptureViewModel(
                thoughtService: ThoughtService.shared,
                contextService: ContextService.shared,
                classificationService: ClassificationService.shared,
                fineTuningService: FineTuningService.shared,
                taskService: TaskService.shared
            ),
            onComplete: {}
        )
    )
}
