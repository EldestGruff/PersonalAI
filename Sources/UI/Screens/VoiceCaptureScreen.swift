//
//  VoiceCaptureScreen.swift
//  STASH
//
//  Phase 3B: Voice Capture Screen
//  Real-time voice-to-text capture with tap-to-pause microphone
//

import SwiftUI

// MARK: - Voice Capture Screen

/// Voice capture screen with real-time transcription.
///
/// Features:
/// - Tappable microphone icon (tap to pause/resume)
/// - Real-time transcription display
/// - 3-second silence auto-save
/// - Cancel/Done buttons
/// - Permission error handling
struct VoiceCaptureScreen: View {
    @State var viewModel: VoiceCaptureViewModel
    @Environment(\.themeEngine) var themeEngine
    @Environment(\.dismiss) private var dismiss

    // Animation state
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0

    init(viewModel: VoiceCaptureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                // Theme background
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Microphone icon (tappable)
                    microphoneButton(theme: theme)

                    // Status text
                    statusText(theme: theme)

                    // Transcription display
                    transcriptionView(theme: theme)

                    Spacer()

                    // Action buttons
                    actionButtons(theme: theme)
                }
                .padding()
            }
            .navigationTitle("Voice Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        _Concurrency.Task {
                            await viewModel.cancelListening()
                        }
                    }
                    .foregroundStyle(theme.textColor)
                }
            }
            .task {
                await viewModel.startListening()
            }
            .onChange(of: viewModel.captureSucceeded) { _, succeeded in
                if succeeded {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Microphone Button

    @ViewBuilder
    private func microphoneButton(theme: any ThemeVariant) -> some View {
        Button {
            _Concurrency.Task {
                await toggleListening()
            }
        } label: {
            Image(systemName: "mic.fill")
                .font(.system(size: 80))
                .foregroundStyle(micColor(theme: theme))
                .scaleEffect(isListening ? pulseScale : 1.0)
                .opacity(isListening ? pulseOpacity : 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Microphone")
        .accessibilityHint(accessibilityHint)
        .onAppear {
            if isListening {
                startPulseAnimation()
            }
        }
        .onChange(of: isListening) { _, newValue in
            if newValue {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }

    // MARK: - Status Text

    @ViewBuilder
    private func statusText(theme: any ThemeVariant) -> some View {
        Text(statusString)
            .font(.headline)
            .foregroundStyle(theme.textColor.opacity(0.8))
            .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Transcription View

    @ViewBuilder
    private func transcriptionView(theme: any ThemeVariant) -> some View {
        ScrollView {
            Text(viewModel.transcribedText.isEmpty ? "Start speaking..." : viewModel.transcribedText)
                .font(.body)
                .foregroundStyle(viewModel.transcribedText.isEmpty ? theme.textColor.opacity(0.4) : theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(maxHeight: 200)
        .background(theme.backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.textColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(theme: any ThemeVariant) -> some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                _Concurrency.Task {
                    await viewModel.cancelListening()
                }
            }
            .buttonStyle(.bordered)
            .foregroundStyle(theme.textColor)

            Spacer()

            Button("Done") {
                _Concurrency.Task {
                    await viewModel.stopAndSave()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.transcribedText.isEmpty)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var isListening: Bool {
        viewModel.captureState == .listening
    }

    private var statusString: String {
        switch viewModel.captureState {
        case .idle:
            return "Starting..."
        case .listening:
            return "Listening..."
        case .paused:
            return "Paused - Tap to resume"
        case .processing:
            return "Saving..."
        case .saved:
            return "Saved!"
        case .error(let message):
            return message
        }
    }

    private var accessibilityHint: String {
        switch viewModel.captureState {
        case .listening:
            return "Double tap to pause"
        case .paused:
            return "Double tap to resume"
        default:
            return "Microphone control"
        }
    }

    private func micColor(theme: any ThemeVariant) -> Color {
        switch viewModel.captureState {
        case .listening:
            return theme.accentColor
        case .paused:
            return theme.textColor.opacity(0.4)
        case .error:
            return .red
        default:
            return theme.textColor
        }
    }

    private func toggleListening() async {
        switch viewModel.captureState {
        case .listening:
            await viewModel.pauseListening()
        case .paused:
            await viewModel.resumeListening()
        default:
            break
        }
    }

    // MARK: - Animations

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.6
        }
    }

    private func stopPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseScale = 1.0
            pulseOpacity = 1.0
        }
    }
}
