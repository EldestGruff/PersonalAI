//
//  CaptureScreen.swift
//  STASH
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
    @State private var showAcornToast = false
    @State private var showBadgeToast = false
    @State private var showVariableReward = false
    @Environment(\.themeEngine) var themeEngine
    @Environment(\.dismiss) private var dismiss
    @SwiftUI.FocusState private var isTextFieldFocused: Bool

    init(viewModel: CaptureViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ZStack {
                // Theme background color
                theme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Error banner with upgrade option
                        if let error = viewModel.error {
                            subscriptionErrorBanner(error: error, theme: theme)
                        }

                        // Content input
                        contentInputSection(theme: theme)

                        // Tags
                        tagsSection(theme: theme)

                        // Similar thoughts insight
                        if viewModel.hasSimilarThoughts {
                            similarThoughtsInsight(theme: theme)
                        }

                        // Context & Classification
                        if viewModel.isContextLoading || viewModel.context != nil {
                            contextSection(theme: theme)
                        }

                        if viewModel.isClassificationLoading || viewModel.classification != nil {
                            classificationSection
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("New Thought")
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.secondaryTextColor)
                    .disabled(viewModel.isCapturing)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Capture") {
                        isTextFieldFocused = false
                        viewModel.captureThought()
                    }
                    .disabled(!viewModel.isValid || viewModel.isCapturing)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.isValid && !viewModel.isCapturing ? theme.primaryColor : theme.secondaryTextColor)
                    .accessibilityIdentifier("captureThoughtButton")
                }
            }
            .onAppear {
                viewModel.gatherContext()
                isTextFieldFocused = true
            }
            .onChange(of: viewModel.captureSucceeded) { _, succeeded in
                if succeeded {
                    let hasBadge = !viewModel.lastEarnedBadges.isEmpty
                    let hasAcorn = viewModel.lastAcornReward != nil
                    let isNoteworthy = viewModel.lastAcornReward?.isNoteworthy ?? false
                    let vrs = viewModel.lastVariableReward

                    if hasBadge { showBadgeToast = true }
                    if hasAcorn { showAcornToast = true }
                    if vrs != nil { showVariableReward = true }

                    _Concurrency.Task {
                        // VRS tier dictates minimum linger time; badges otherwise
                        let delay: Int
                        if let tier = vrs {
                            delay = tier.dismissDelay
                        } else if hasBadge {
                            delay = 1800
                        } else if isNoteworthy {
                            delay = 1200
                        } else {
                            delay = 700
                        }
                        try? await _Concurrency.Task.sleep(for: .milliseconds(delay))
                        dismiss()
                    }

                    if !hasBadge && !hasAcorn && vrs == nil { dismiss() }
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if showBadgeToast, let badge = viewModel.lastEarnedBadges.first {
                        BadgeToastView(badge: badge)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if showAcornToast, let reward = viewModel.lastAcornReward {
                        AcornToastView(reward: reward)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 8)
            }
            .overlay {
                if showVariableReward, let tier = viewModel.lastVariableReward {
                    VStack {
                        Spacer()
                        VariableRewardView(tier: tier)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .padding(.bottom, 60)
                    }
                }
            }
            .animation(.spring(duration: 0.35), value: showAcornToast)
            .animation(.spring(duration: 0.35), value: showBadgeToast)
            .animation(.spring(response: 0.45, dampingFraction: 0.6), value: showVariableReward)
            .sheet(isPresented: $showPaywall) {
                PaywallScreen()
            }
        }
    }

    // MARK: - Content Input Section

    private func contentInputSection(theme: any ThemeVariant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode toggle
            HStack {
                Text("What's on your mind?")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Spacer()

                // Rich text toggle (iOS 15+)
                Button {
                    viewModel.toggleRichText()
                } label: {
                    Image(systemName: viewModel.richTextEnabled ? "textformat" : "textformat.alt")
                        .foregroundColor(theme.primaryColor)
                }
                .buttonStyle(.bordered)
                .tint(theme.primaryColor)
                .disabled(viewModel.isCapturing)
                .accessibilityLabel(viewModel.richTextEnabled ? "Disable rich text" : "Enable rich text")
                .accessibilityHint("Double tap to toggle formatting")
            }

            if viewModel.richTextEnabled {
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
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(theme.inputBackgroundColor)
                    .foregroundColor(theme.textColor)
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.inputBorderColor, lineWidth: theme.borderWidth)
                    )
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
                        .foregroundColor(viewModel.isOverLimit ? theme.errorColor : theme.secondaryTextColor)
                }
            } else {
                // Plain text input
                TextEditor(text: $viewModel.thoughtContent)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(theme.inputBackgroundColor)
                    .foregroundColor(theme.textColor)
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.inputBorderColor, lineWidth: theme.borderWidth)
                    )
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
                        .foregroundColor(viewModel.isOverLimit ? theme.errorColor : theme.secondaryTextColor)
                }
            }
        }
    }

    // MARK: - Tags Section

    private func tagsSection(theme: any ThemeVariant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(theme.textColor)

            TagInputView(
                tags: $viewModel.selectedTags,
                onAdd: { viewModel.addTag($0) },
                onRemove: { viewModel.removeTag($0) }
            )
        }
    }

    // MARK: - Similar Thoughts Insight

    private func similarThoughtsInsight(theme: any ThemeVariant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(theme.accentColor)
                Text("You've thought about this before")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)

                Spacer()

                if viewModel.isCheckingSimilar {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(theme.accentColor)
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
                            .foregroundColor(theme.textColor)
                            .lineLimit(2)

                        HStack {
                            Text(result.thought.createdAt.formatted(.relative(presentation: .named)))
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)

                            Text("\(result.relevancePercentage)% similar")
                                .font(.caption2)
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius - 4)
                }
            }
        }
        .padding(12)
        .background(theme.surfaceColor.opacity(0.6))
        .cornerRadius(theme.cornerRadius)
    }

    // MARK: - Context Section

    private func contextSection(theme: any ThemeVariant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Context")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                if viewModel.isContextLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.accentColor)
                }
            }

            if let context = viewModel.context {
                ContextDisplayView(context: context)
            } else if let error = viewModel.contextError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
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
    private func subscriptionErrorBanner(error: AppError, theme: any ThemeVariant) -> some View {
        // Check if this is a subscription limit error
        let isSubscriptionError = error.errorDescription?.contains("limit") ?? false

        if isSubscriptionError {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(theme.warningColor)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Tier Limit Reached")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textColor)

                        Text(error.errorDescription ?? "Upgrade to Pro for unlimited thoughts")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
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
                .tint(theme.primaryColor)
                .controlSize(.small)
            }
            .padding()
            .background(theme.warningColor.opacity(0.1))
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.warningColor.opacity(0.3), lineWidth: theme.borderWidth)
            )
        } else {
            ErrorBanner(error: error) {
                viewModel.error = nil
            }
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
