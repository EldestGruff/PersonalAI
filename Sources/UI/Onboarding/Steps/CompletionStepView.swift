//
//  CompletionStepView.swift
//  STASH
//
//  Onboarding Step 9: Completion screen with animated checkmark
//

import SwiftUI

struct CompletionStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared
    @State private var showCheckmark = false

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 32) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(theme.successColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(theme.successColor)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }

            // Completion message (persona-voiced)
            Text(OnboardingCopy.completionMessage(for: viewModel.selectedPersona))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(theme.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Done button
            Button {
                viewModel.completeOnboarding()
            } label: {
                HStack {
                    Text("Start Using STASH")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.primaryColor)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showCheckmark = true
            }
        }
    }
}
