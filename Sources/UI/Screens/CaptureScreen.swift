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
    @Environment(\.dismiss) private var dismiss
    @SwiftUI.FocusState private var isTextFieldFocused: Bool

    init(viewModel: CaptureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Error banner
                    if let error = viewModel.error {
                        ErrorBanner(error: error) {
                            viewModel.error = nil
                        }
                    }

                    // Content input
                    contentInputSection

                    // Tags
                    tagsSection

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

                Button {
                    viewModel.toggleVoiceInput()
                } label: {
                    Image(systemName: viewModel.voiceInputMode ? "keyboard" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isCapturing)
            }

            if viewModel.voiceInputMode {
                // Voice input placeholder
                VoiceInputPlaceholder {
                    viewModel.toggleVoiceInput()
                }
            } else {
                // Text input
                TextEditor(text: $viewModel.thoughtContent)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onChange(of: viewModel.thoughtContent) { _, newValue in
                        // Trigger classification after user stops typing
                        if newValue.count > 10 {
                            viewModel.classifyThought()
                        }
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
                ClassificationBadge(classification: classification)
            } else if let error = viewModel.classificationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
            fineTuningService: FineTuningService.shared
        )
    )
}
