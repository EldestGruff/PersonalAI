//
//  BackTapSetupScreen.swift
//  STASH
//
//  Quick setup screen for configuring Back Tap voice capture
//

import SwiftUI

struct BackTapSetupScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeEngine) var themeEngine
    @Environment(\.openURL) private var openURL

    @State private var currentStep: SetupStep = .intro

    enum SetupStep {
        case intro
        case addShortcut
        case configureBackTap
        case complete
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(theme.accentColor)

                        Text("Back Tap Voice Capture")
                            .font(.title2.bold())
                            .foregroundStyle(theme.textColor)

                        Text("Capture thoughts instantly by tapping the back of your phone")
                            .font(.subheadline)
                            .foregroundStyle(theme.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Steps
                    VStack(spacing: 20) {
                        setupStepView(
                            number: 1,
                            title: "Add Voice Capture Shortcut",
                            description: "Opens Shortcuts app where you'll tap the Voice Capture action",
                            buttonTitle: "Open Shortcuts App",
                            theme: theme,
                            isCompleted: currentStep.rawValue > SetupStep.addShortcut.rawValue
                        ) {
                            openShortcutsApp()
                        }

                        setupStepView(
                            number: 2,
                            title: "Configure Back Tap",
                            description: "Opens Settings where you'll assign the shortcut to Double Tap",
                            buttonTitle: "Open Back Tap Settings",
                            theme: theme,
                            isCompleted: currentStep == .complete
                        ) {
                            openBackTapSettings()
                        }
                    }
                    .padding()

                    Spacer()

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(
                            icon: "1.circle.fill",
                            text: "In Shortcuts app: Tap '+' → Search 'Voice' → Tap 'Voice Capture' → Done",
                            theme: theme
                        )

                        InstructionRow(
                            icon: "2.circle.fill",
                            text: "In Settings: Choose Double Tap → Scroll to Shortcuts → Select 'Voice Capture'",
                            theme: theme
                        )

                        InstructionRow(
                            icon: "checkmark.circle.fill",
                            text: "Test: Double-tap back of phone to start voice capture!",
                            theme: theme
                        )
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(12)
                    .padding()

                    // Skip button
                    Button("I'll Set This Up Later") {
                        dismiss()
                    }
                    .font(.footnote)
                    .foregroundStyle(theme.textColor.opacity(0.6))
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(theme.textColor)
                }
            }
        }
    }

    // MARK: - Step View

    @ViewBuilder
    private func setupStepView(
        number: Int,
        title: String,
        description: String,
        buttonTitle: String,
        theme: any ThemeVariant,
        isCompleted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "\(number).circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : theme.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(theme.textColor)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(theme.textColor.opacity(0.7))
                }
            }

            Button(action: action) {
                Text(buttonTitle)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(isCompleted)
            .opacity(isCompleted ? 0.6 : 1.0)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func openShortcutsApp() {
        // Deep link to Shortcuts app
        if let url = URL(string: "shortcuts://") {
            openURL(url)
            currentStep = .configureBackTap
        }
    }

    private func openBackTapSettings() {
        // Deep link to Accessibility settings
        if let url = URL(string: "App-prefs:root=ACCESSIBILITY&path=TOUCH_REACHABILITY_TITLE/BACK_TAP_TITLE") {
            openURL(url)

            // Mark as complete after a delay
            _Concurrency.Task {
                try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)
                currentStep = .complete
            }
        }
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let icon: String
    let text: String
    let theme: any ThemeVariant

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(theme.accentColor)
                .font(.body)

            Text(text)
                .font(.caption)
                .foregroundStyle(theme.textColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Setup Step Extension

extension BackTapSetupScreen.SetupStep: Comparable {
    var rawValue: Int {
        switch self {
        case .intro: return 0
        case .addShortcut: return 1
        case .configureBackTap: return 2
        case .complete: return 3
        }
    }

    static func < (lhs: BackTapSetupScreen.SetupStep, rhs: BackTapSetupScreen.SetupStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Preview

#Preview {
    BackTapSetupScreen()
        .environment(\.themeEngine, ThemeEngine.shared)
}
