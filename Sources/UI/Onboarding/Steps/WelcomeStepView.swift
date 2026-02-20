//
//  WelcomeStepView.swift
//  STASH
//
//  Onboarding Step 1: Welcome screen with large squirrel avatar
//

import SwiftUI

struct WelcomeStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 32) {
            Spacer()

            // Large squirrel avatar
            Image(viewModel.selectedPersona.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .shadow(color: theme.primaryColor.opacity(0.3), radius: 20)

            // App title
            Text("Welcome to STASH")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(theme.textColor)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Your AI companion for capturing and exploring thoughts")
                .font(.title3)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Get Started button
            Button {
                viewModel.advance()
            } label: {
                HStack {
                    Text("Get Started")
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
