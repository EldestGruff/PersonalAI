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
    @Environment(\.dismiss) private var dismiss
    @SwiftUI.FocusState private var isTextFieldFocused: Bool

    init(viewModel: CaptureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
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
                // Voice input placeholder
                VoiceInputPlaceholder {
                    viewModel.toggleVoiceInput()
                }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Classification")
                    .font(.headline)

                if viewModel.isClassificationLoading {
                    ProgressView()
                        .scaleEffect(0.8)
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
                            Text("Low confidence (\(Int(classification.confidence * 100))%) - you can edit type if needed")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            } else if let error = viewModel.classificationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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

// MARK: - Voice Input Placeholder

/// Placeholder for voice input (Phase 3A simplified version)
struct VoiceInputPlaceholder: View {
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("Voice input will be available in a future update")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Use Text Input") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
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
