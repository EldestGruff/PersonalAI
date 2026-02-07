//
//  CaptureScreen.swift
//  PersonalAI
//
//  Phase 3A Spec 3: Thought Capture Screen
//  Main screen for capturing new thoughts
//

import SwiftUI

// MARK: - Capture Screen

/// The main thought capture screen.
///
/// Features:
/// - Text input with character count
/// - Voice input mode (toggle)
/// - Tag management
/// - Context gathering (background)
/// - Classification preview
/// - Capture button
struct CaptureScreen: View {
    @State var viewModel: CaptureViewModel
    @State private var showPaywall = false
    @State private var themeEngine = ThemeEngine.shared
    @Environment(\.dismiss) private var dismiss
    @SwiftUI.FocusState private var isTextFieldFocused: Bool

    init(viewModel: CaptureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Error banner with upgrade option
                    if let error = viewModel.error {
                        subscriptionErrorBanner(error: error)
                    }

                    // Content input
                    contentInputSection

                    // Tags
                    tagsSection

                    // Similar thoughts insight
                    if viewModel.hasSimilarThoughts {
                        similarThoughtsInsight
                    }

                    // Context & Classification
                    if viewModel.isContextLoading || viewModel.context != nil {
                        contextSection
                    }

                    if viewModel.isClassificationLoading || viewModel.classification != nil {
                        classificationSection
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Thought")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isCapturing)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Capture") {
                        isTextFieldFocused = false
                        viewModel.captureThought()
                    }
                    .disabled(!viewModel.isValid || viewModel.isCapturing)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.isValid && !viewModel.isCapturing ? theme.accentColor : .gray)
                    .accessibilityIdentifier("captureThoughtButton")
                }
            }
            .onAppear {
                viewModel.gatherContext()
                isTextFieldFocused = true
            }
            .onChange(of: viewModel.captureSucceeded) { _, succeeded in
                if succeeded {
                    dismiss()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallScreen()
            }
        }
    }

    // MARK: - Content Input Section

    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode toggle
            HStack {
                Text("What's on your mind?")
                    .font(.headline)

                Spacer()

                // Rich text toggle (iOS 15+)
                Button {
                    viewModel.toggleRichText()
                } label: {
                    Image(systemName: viewModel.richTextEnabled ? "textformat" : "textformat.alt")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isCapturing)
                .accessibilityLabel(viewModel.richTextEnabled ? "Disable rich text" : "Enable rich text")
                .accessibilityHint("Double tap to toggle formatting")

                Button {
                    viewModel.toggleVoiceInput()
                } label: {
                    Image(systemName: viewModel.voiceInputMode ? "keyboard" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isCapturing)
                .accessibilityLabel(viewModel.voiceInputMode ? "Switch to keyboard input" : "Switch to voice input")
                .accessibilityHint("Double tap to toggle input mode")
                .accessibilityIdentifier("voiceInputToggleButton")
            }

            if viewModel.voiceInputMode {
                // Voice input with live transcription
                VoiceInputView(
                    onCancel: {
                        viewModel.toggleVoiceInput()
                    },
                    onTranscription: { text in
                        viewModel.thoughtContent = text
                        viewModel.toggleVoiceInput()
                    }
                )
            } else if viewModel.richTextEnabled {
                // Rich text input (iOS 15+)
                VStack(spacing: 8) {
                    TextEditor(text: Binding(
                        get: { AttributedString(viewModel.thoughtContent) },
                        set: { newValue in
                            viewModel.thoughtContent = String(newValue.characters)
                            viewModel.syncAttributedContent()
                        }
                    ))
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .accessibilityIdentifier("captureThoughtTextField")
                    .accessibilityHint("Enter formatted thought content")
                    .onChange(of: viewModel.thoughtContent) { oldValue, newValue in
                        // Skip if too short
                        guard newValue.count > 10 else { return }

                        // Detect large paste operation
                        let changeSize = abs(newValue.count - oldValue.count)
                        if changeSize > 50 {
                            viewModel.classifyThoughtImmediately()
                        } else {
                            viewModel.classifyThought()
                        }

                        viewModel.checkForSimilarThoughts()
                    }

                    // Formatting toolbar (iOS 26+)
                    if #available(iOS 26.0, *) {
                        FormattingToolbar(attributedText: Binding(
                            get: { viewModel.attributedThoughtContent ?? AttributedString() },
                            set: { viewModel.attributedThoughtContent = $0 }
                        ))
                    }
                }

                // Character count
                HStack {
                    Spacer()
                    Text("\(viewModel.characterCount) / 5000")
                        .font(.caption)
                        .foregroundColor(viewModel.isOverLimit ? .red : .secondary)
                }
            } else {
                // Plain text input
                TextEditor(text: $viewModel.thoughtContent)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .accessibilityIdentifier("captureThoughtTextField")
                    .accessibilityHint("Enter your thought content. AI will automatically classify and tag it.")
                    .onChange(of: viewModel.thoughtContent) { oldValue, newValue in
                        // Skip if too short
                        guard newValue.count > 10 else { return }

                        // Detect large paste operation (change >50 characters at once)
                        let changeSize = abs(newValue.count - oldValue.count)
                        if changeSize > 50 {
                            // Immediate classification for paste
                            viewModel.classifyThoughtImmediately()
                        } else {
                            // Debounced classification for typing
                            viewModel.classifyThought()
                        }

                        // Check for similar thoughts (debounced)
                        viewModel.checkForSimilarThoughts()
                    }

                // Character count
                HStack {
                    Spacer()
                    Text("\(viewModel.characterCount) / 5000")
                        .font(.caption)
                        .foregroundColor(viewModel.isOverLimit ? .red : .secondary)
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            TagInputView(
                tags: $viewModel.selectedTags,
                onAdd: { viewModel.addTag($0) },
                onRemove: { viewModel.removeTag($0) }
            )
        }
    }

    // MARK: - Similar Thoughts Insight

    private var similarThoughtsInsight: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text("You've thought about this before")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if viewModel.isCheckingSimilar {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            ForEach(viewModel.similarThoughts.prefix(2)) { result in
                NavigationLink {
                    DetailScreen(
                        viewModel: DetailViewModel(
                            thought: result.thought,
                            thoughtService: ThoughtService.shared,
                            fineTuningService: FineTuningService.shared,
                            taskService: TaskService.shared
                        )
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.thought.content)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        HStack {
                            Text(result.thought.createdAt.formatted(.relative(presentation: .named)))
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("\(result.relevancePercentage)% similar")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.03))
        .cornerRadius(12)
    }

    // MARK: - Context Section

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Context")
                    .font(.headline)

                if viewModel.isContextLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let context = viewModel.context {
                ContextDisplayView(context: context)
            } else if let error = viewModel.contextError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Classification Section

    private var classificationSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Classification")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                if viewModel.isClassificationLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.accentColor)
                }
            }

            if let classification = viewModel.classification {
                VStack(alignment: .leading, spacing: 8) {
                    ClassificationBadge(classification: classification)

                    // Issue #8: Show confidence indicator for user awareness
                    if classification.confidence < 0.7 {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                            Text("Low confidence (\(Int(classification.confidence * 100))%) - you can edit type if needed")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
            } else if let error = viewModel.classificationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding()
        .background(theme.surfaceColor.opacity(0.5))
        .cornerRadius(theme.cornerRadius)
    }

    // MARK: - Subscription Error Banner

    @ViewBuilder
    private func subscriptionErrorBanner(error: AppError) -> some View {
        // Check if this is a subscription limit error
        let isSubscriptionError = error.errorDescription?.contains("limit") ?? false

        if isSubscriptionError {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Tier Limit Reached")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(error.errorDescription ?? "Upgrade to Pro for unlimited thoughts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Upgrade to Pro")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
        } else {
            ErrorBanner(error: error) {
                viewModel.error = nil
            }
        }
    }
}

// MARK: - Voice Input

/// Live voice input using SpeechService
struct VoiceInputView: View {
    let onCancel: () -> Void
    let onTranscription: (String) -> Void

    @State private var transcribedText: String = ""
    @State private var isListening: Bool = false
    @State private var errorMessage: String?
    @State private var speechService: SpeechService?
    @State private var transcriptionTask: _Concurrency.Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            // Microphone animation with start/stop toggle
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    restartListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isListening ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isListening ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isListening)

                    Image(systemName: isListening ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isListening ? .red : .blue)
                }
            }
            .buttonStyle(.plain)

            // Status text
            Text(isListening ? "Tap to stop recording" : (transcribedText.isEmpty ? "Tap to start recording" : "Tap to record more"))
                .font(.headline)
                .foregroundColor(isListening ? .red : .secondary)

            // Transcribed text
            if !transcribedText.isEmpty {
                ScrollView {
                    Text(transcribedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 150)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Controls
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Label("Cancel", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)

                if !transcribedText.isEmpty && !isListening {
                    Button(action: {
                        onTranscription(transcribedText)
                    }) {
                        Label("Use Text", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .task {
            await startListening()
        }
        .onDisappear {
            stopListening()
        }
    }

    private func startListening() async {
        print("🎤 VoiceInputView - startListening() called")

        // Initialize speech service
        let service = SpeechService()
        self.speechService = service

        // Request permission
        print("🎤 VoiceInputView - Requesting speech permission")
        let permissionLevel = await service.requestPermission()

        guard permissionLevel == .authorized else {
            print("🎤 VoiceInputView - Permission denied: \(permissionLevel)")
            errorMessage = "Speech recognition permission denied. Please enable in Settings."
            return
        }

        print("🎤 VoiceInputView - Permission granted, starting transcription")

        // Start transcription
        do {
            isListening = true
            let stream = try await service.startLiveTranscription()

            print("🎤 VoiceInputView - Got transcription stream, starting to consume")
            transcriptionTask = _Concurrency.Task {
                do {
                    for try await text in stream {
                        print("🎤 VoiceInputView - Received transcription: '\(text.prefix(50))...'")
                        transcribedText = text
                    }
                    print("🎤 VoiceInputView - Stream finished")
                    isListening = false
                } catch {
                    print("🎤 VoiceInputView - Stream error: \(error)")
                    errorMessage = "Transcription error: \(error.localizedDescription)"
                    isListening = false
                }
            }
        } catch {
            print("🎤 VoiceInputView - Failed to start transcription: \(error)")
            errorMessage = "Failed to start speech recognition: \(error.localizedDescription)"
            isListening = false
        }
    }

    private func stopListening() {
        print("🎤 VoiceInputView - stopListening() called manually")

        // Cancel the transcription task
        transcriptionTask?.cancel()
        transcriptionTask = nil

        // Stop the speech service
        if let service = speechService {
            _Concurrency.Task {
                await service.stopLiveTranscription()
                print("🎤 VoiceInputView - Speech service stopped")
            }
        }

        isListening = false
        print("🎤 VoiceInputView - Listening stopped, isListening = false")
    }

    private func restartListening() {
        print("🎤 VoiceInputView - restartListening() called")

        // Clear any errors
        errorMessage = nil

        // Start listening in a task
        _Concurrency.Task {
            await startListening()
        }
    }
}

// MARK: - Previews

#Preview("Capture Screen - Empty") {
    CaptureScreen(
        viewModel: CaptureViewModel(
            thoughtService: ThoughtService.shared,
            contextService: ContextService.shared,
            classificationService: ClassificationService.shared,
            fineTuningService: FineTuningService.shared,
            taskService: TaskService.shared
        )
    )
}
