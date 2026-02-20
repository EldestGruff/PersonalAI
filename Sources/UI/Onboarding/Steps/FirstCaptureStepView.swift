//
//  FirstCaptureStepView.swift
//  STASH
//
//  Onboarding Step 3: Real thought capture with embedded CaptureScreen
//

import SwiftUI

struct FirstCaptureStepView: View {
    @State var viewModel: OnboardingViewModel
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 0) {
            // Persona banner
            VStack(spacing: 12) {
                // Squirrel avatar
                Image(viewModel.selectedPersona.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                // Capture prompt (persona-voiced)
                Text(OnboardingCopy.capturePrompt(for: viewModel.selectedPersona))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(theme.surfaceColor)

            // Embedded CaptureScreen
            CaptureScreenContent(viewModel: viewModel.captureViewModel)
                .onChange(of: viewModel.captureViewModel.captureSucceeded) { _, succeeded in
                    if succeeded {
                        // Capture completed successfully
                        viewModel.completeCapture()
                    }
                }
        }
    }
}

// MARK: - Capture Screen Content

/// Simplified capture screen content without navigation chrome (for embedding)
struct CaptureScreenContent: View {
    @State var viewModel: CaptureViewModel
    @State private var themeEngine = ThemeEngine.shared
    @SwiftUI.FocusState private var isTextFieldFocused: Bool

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Error banner
                    if let error = viewModel.error {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(theme.warningColor)
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.warningColor.opacity(0.1))
                        )
                    }

                    // Content input
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $viewModel.thoughtContent)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(theme.surfaceColor)
                            .cornerRadius(12)
                            .foregroundStyle(theme.textColor)
                            .focused($isTextFieldFocused)
                            .onChange(of: viewModel.thoughtContent) { _, _ in
                                viewModel.classifyThought()
                                viewModel.checkForSimilarThoughts()
                            }

                        HStack {
                            Text("\(viewModel.characterCount) / 5000")
                                .font(.caption)
                                .foregroundStyle(
                                    viewModel.isOverLimit ? theme.warningColor : theme.secondaryTextColor
                                )

                            Spacer()
                        }
                    }

                    // Tags section (simplified)
                    if !viewModel.selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedTags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                        Button {
                                            viewModel.removeTag(tag)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(theme.primaryColor.opacity(0.2))
                                    .foregroundStyle(theme.primaryColor)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Capture button
                    Button {
                        isTextFieldFocused = false
                        viewModel.captureThought()
                    } label: {
                        HStack {
                            if viewModel.isCapturing {
                                ProgressView()
                                    .tint(.white)
                                Text("Capturing...")
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Capture Thought")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isValid && !viewModel.isCapturing ? theme.primaryColor : theme.secondaryTextColor.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid || viewModel.isCapturing)

                    Spacer()
                }
                .padding()
            }

            // Acorn toast overlay
            if let reward = viewModel.lastAcornReward {
                VStack {
                    Spacer()
                    AcornToastView(reward: reward)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            viewModel.gatherContext()
            isTextFieldFocused = true
        }
    }
}

// Note: AcornToastView is defined in Sources/UI/Components/AcornToastView.swift
