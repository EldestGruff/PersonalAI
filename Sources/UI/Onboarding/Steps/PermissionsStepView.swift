//
//  PermissionsStepView.swift
//  STASH
//
//  Onboarding Step 6: Optional context permissions
//

import SwiftUI

struct PermissionsStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared
    @State private var isRequesting = false

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                // Header
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.primaryColor)

                    Text("Context Permissions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.center)

                    Text(OnboardingCopy.permissionPitch(for: viewModel.selectedPersona))
                        .font(.body)
                        .foregroundStyle(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Permission cards
                VStack(spacing: 16) {
                    PermissionCard(
                        icon: "location.fill",
                        title: "Location",
                        description: "Add location context to your thoughts",
                        color: theme.primaryColor
                    )

                    PermissionCard(
                        icon: "calendar",
                        title: "Calendar & Reminders",
                        description: "Link thoughts to events and tasks",
                        color: theme.successColor
                    )

                    PermissionCard(
                        icon: "person.crop.circle.fill",
                        title: "Contacts",
                        description: "Recognize people mentioned in thoughts",
                        color: theme.warningColor
                    )
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        isRequesting = true
                        _Concurrency.Task {
                            await viewModel.requestContextPermissions()
                            isRequesting = false
                            viewModel.advance()
                        }
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                                Text("Requesting...")
                            } else {
                                Text("Enable Permissions")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primaryColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRequesting)

                    Button {
                        viewModel.skip()
                    } label: {
                        Text("Skip for Now")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceColor)
        )
    }
}
