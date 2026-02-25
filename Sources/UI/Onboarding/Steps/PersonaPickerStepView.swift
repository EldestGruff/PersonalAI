//
//  PersonaPickerStepView.swift
//  STASH
//
//  Onboarding Step 2: Persona selection grid with live greeting preview
//

import SwiftUI

struct PersonaPickerStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose Your Companion")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.center)

                    Text("Pick the personality that resonates with you. You can change this anytime in Settings.")
                        .font(.body)
                        .foregroundStyle(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // Live greeting preview
                VStack(spacing: 12) {
                    // Squirrel avatar
                    Image(viewModel.selectedPersona.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                    // Greeting text
                    Text(OnboardingCopy.greeting(for: viewModel.selectedPersona))
                        .font(.body)
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surfaceColor)
                        )
                        .padding(.horizontal, 24)
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedPersona.id)

                // Persona grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(SquirrelPersona.builtIn) { persona in
                        PersonaCard(
                            persona: persona,
                            isDefault: viewModel.selectedPersona.id == persona.id,
                            onTap: {
                                // No detail sheet in onboarding
                            },
                            onSetDefault: {
                                // Preview only — does not advance. Confirm button below commits the choice.
                                viewModel.selectedPersona = persona
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Confirm button — commits selection and advances
                Button {
                    viewModel.selectPersona(viewModel.selectedPersona)
                } label: {
                    Text("Choose \(viewModel.selectedPersona.name)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPersona.id)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// Note: PersonaCard is defined in Sources/UI/Screens/PersonalizationScreen.swift
