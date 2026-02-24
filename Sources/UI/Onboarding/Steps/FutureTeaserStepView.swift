//
//  FutureTeaserStepView.swift
//  STASH
//
//  Onboarding Step 8: Introduces the Shiny Thoughts feature
//

import SwiftUI

struct FutureTeaserStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared
    @State private var sparkleAnimation = false

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 32) {
            Spacer()

            // Animated sparkles icon
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "sparkles")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.warningColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(sparkleAnimation ? 10 : -10))
                    .scaleEffect(sparkleAnimation ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: sparkleAnimation
                    )
            }

            // Feature preview
            VStack(spacing: 16) {
                Text("Shiny Thoughts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.textColor)

                Text(OnboardingCopy.futureTeaser(for: viewModel.selectedPersona))
                    .font(.body)
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Shiny thought preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(theme.warningColor)
                        Text("Shiny")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.warningColor)
                        Spacer()
                    }

                    Text("Your most insightful captures are automatically surfaced in \"Today's Shiny\" on Browse.")
                        .font(.subheadline)
                        .foregroundStyle(theme.textColor)
                        .lineLimit(3)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.warningColor.opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }

            Spacer()

            // Continue button
            Button {
                viewModel.advance()
            } label: {
                HStack {
                    Text("Sounds Great!")
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
            sparkleAnimation = true
        }
    }
}
