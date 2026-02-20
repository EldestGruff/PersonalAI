//
//  NotificationsStepView.swift
//  STASH
//
//  Onboarding Step 7: Optional notification setup
//

import SwiftUI

struct NotificationsStepView: View {
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
                    // Squirrel avatar
                    Image(viewModel.selectedPersona.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                    Text("Squirrel Reminders")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.center)

                    Text(OnboardingCopy.notificationPitch(for: viewModel.selectedPersona))
                        .font(.body)
                        .foregroundStyle(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Notification type toggles
                VStack(spacing: 12) {
                    ForEach(SquirrelNotificationType.allCases, id: \.self) { type in
                        NotificationToggleRow(
                            type: type,
                            isEnabled: Binding(
                                get: { viewModel.notificationTypesEnabled[type] ?? type.defaultEnabled },
                                set: { viewModel.notificationTypesEnabled[type] = $0 }
                            )
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        isRequesting = true
                        _Concurrency.Task {
                            await viewModel.enableNotifications()
                            isRequesting = false
                            viewModel.advance()
                        }
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                                Text("Enabling...")
                            } else {
                                Text("Turn on Notifications")
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
                        Text("Maybe Later")
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

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let type: SquirrelNotificationType
    @Binding var isEnabled: Bool

    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 12) {
            Image(systemName: type.displayIcon)
                .font(.title3)
                .foregroundStyle(theme.primaryColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.body)
                    .foregroundStyle(theme.textColor)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceColor)
        )
    }
}
