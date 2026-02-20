//
//  StreakIntroStepView.swift
//  STASH
//
//  Onboarding Step 5: Spotlight overlay explaining streak mechanic
//

import SwiftUI

struct StreakIntroStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared
    @State private var streakTracker = StreakTracker.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Highlighted streak counter
                VStack(spacing: 16) {
                    // Mock streak display
                    HStack(spacing: 8) {
                        Text("🔥")
                            .font(.title2)
                        Text("\(streakTracker.currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.textColor)
                        Text("day\(streakTracker.currentStreak == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceColor)
                            .shadow(color: theme.warningColor.opacity(0.5), radius: 20)
                    )
                }

                // Squirrel explanation card
                VStack(spacing: 16) {
                    // Squirrel avatar
                    Image(viewModel.selectedPersona.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                    // Explanation text (persona-voiced)
                    Text(OnboardingCopy.streakEncouragement(for: viewModel.selectedPersona))
                        .font(.body)
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.surfaceColor)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button {
                    viewModel.advance()
                } label: {
                    HStack {
                        Text("Continue")
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
        }
    }
}
