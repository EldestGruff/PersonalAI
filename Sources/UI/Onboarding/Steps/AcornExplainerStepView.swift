//
//  AcornExplainerStepView.swift
//  STASH
//
//  Onboarding Step 4: Spotlight overlay explaining acorn rewards
//

import SwiftUI

struct AcornExplainerStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared
    @State private var acornService = AcornService.shared
    @State private var currentBalance: Int = 0

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Highlighted acorn balance
                VStack(spacing: 16) {
                    // Mock acorn balance display
                    HStack(spacing: 8) {
                        Text("🌰")
                            .font(.title2)
                        Text("\(currentBalance)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.textColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceColor)
                            .shadow(color: theme.primaryColor.opacity(0.5), radius: 20)
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
                    VStack(spacing: 12) {
                        ForEach(OnboardingCopy.acornExplanation(for: viewModel.selectedPersona), id: \.self) { line in
                            Text(line)
                                .font(.body)
                                .foregroundStyle(theme.textColor)
                                .multilineTextAlignment(.center)
                        }
                    }
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
                        Text("Got it!")
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
        .task {
            currentBalance = await acornService.currentBalance
        }
    }
}
