//
//  DetailScreen.swift
//  STASH
//
//  Phase 3A Spec 3: Thought Detail Screen
//  Detailed view of a single thought
//

import SwiftUI

// MARK: - Detail Screen

/// The detail screen for viewing a single thought.
///
/// Features:
/// - Full thought content
/// - Classification details
/// - Context information
/// - User feedback for fine-tuning
/// - Edit mode
struct DetailScreen: View {
    @State var viewModel: DetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeEngine) private var themeEngine
    @State private var showDeleteConfirmation = false
    @State private var showEnergyDebug = false
    @State private var energyBreakdown: EnergyBreakdown?
    @State private var isRefreshingLocation = false
    @State private var refreshedLocation: Location?
    @State private var conversationCount: Int = 0

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            // Theme background color
            theme.backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Error banner
                    if let error = viewModel.error {
                        ErrorBanner(error: error) {
                            viewModel.error = nil
                        }
                    }

                    // Content section
                    contentSection

                    Divider()

                    // Tags section
                    if !viewModel.thought.tags.isEmpty || viewModel.isEditing {
                        tagsSection
                        Divider()
                    }

                    // Classification section
                    if viewModel.hasClassification {
                        classificationSection
                        Divider()
                    }

                    // Context section
                    if viewModel.hasContext {
                        contextSection
                        Divider()
                    }

                    // Related thoughts section
                    if viewModel.hasRelatedThoughts {
                        relatedThoughtsSection
                        Divider()
                    }

                    // Feedback section
                    feedbackSection

                    // Metadata
                    metadataSection
                }
                .padding()
            }

            // Floating conversation button
            if #available(iOS 26.0, *) {
                conversationFloatingButton
            }
        }
        .navigationTitle("Thought")
        .toolbarBackground(theme.surfaceColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isEditing {
                    Button("Done") {
                        viewModel.saveChanges()
                    }
                    .disabled(viewModel.isSaving)
                    .accessibilityIdentifier("doneEditingButton")
                } else {
                    Button("Edit") {
                        viewModel.startEditing()
                    }
                    .accessibilityIdentifier("editThoughtButton")
                }
            }

            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                    }
                    .accessibilityIdentifier("cancelEditingButton")
                }
            }

            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete thought")
                .accessibilityHint("Double tap to confirm deletion. This action cannot be undone.")
                .accessibilityIdentifier("deleteThoughtButton")
            }
        }
        .confirmationDialog(
            "Delete this thought?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                _Concurrency.Task {
                    do {
                        try await viewModel.deleteThought()
                        dismiss()
                    } catch {
                        viewModel.error = AppError.from(error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .task {
            await viewModel.loadRelatedThoughts()
            await loadConversationCount()
        }
    }

    // MARK: - Conversation Floating Button

    @available(iOS 26.0, *)
    private var conversationFloatingButton: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink {
                    ThoughtConversationScreen(thought: viewModel.thought)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(theme.primaryColor.gradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.2), radius: theme.shadowRadius, x: 0, y: 4)

                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(theme.buttonForegroundColor)
                            .font(.title3)
                            .frame(width: 56, height: 56)

                        if conversationCount > 0 {
                            Text("\(conversationCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.buttonForegroundColor)
                                .padding(6)
                                .background(theme.errorColor)
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .padding()
                .accessibilityLabel("Chat with companion")
                .accessibilityHint(conversationCount > 0 ? "You have \(conversationCount) conversation\(conversationCount == 1 ? "" : "s")" : "Start a new conversation")
            }
        }
    }

    private func loadConversationCount() async {
        let conversations = await ThoughtConversationService.shared.getConversations(forThought: viewModel.thought.id)
        conversationCount = conversations.count
    }

    // MARK: - Content Section

    private var contentSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
                .foregroundColor(theme.textColor)

            if viewModel.isEditing {
                TextEditor(text: $viewModel.editedContent)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(theme.inputBackgroundColor)
                    .foregroundColor(theme.textColor)
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.inputBorderColor, lineWidth: theme.borderWidth)
                    )
            } else {
                Text(viewModel.thought.content)
                    .font(.body)
                    .foregroundColor(theme.textColor)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(theme.textColor)

            if viewModel.isEditing {
                TagInputView(
                    tags: $viewModel.editedTags,
                    onAdd: { viewModel.addEditTag($0) },
                    onRemove: { viewModel.removeEditTag($0) }
                )
            } else {
                TagDisplayView(tags: viewModel.thought.tags)
            }
        }
    }

    // MARK: - Classification Section

    private var classificationSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Classification")
                .font(.headline)
                .foregroundColor(theme.textColor)

            if let classification = viewModel.thought.classification {
                ClassificationBadge(classification: classification)

                // Action button for reminder or event types
                if classification.type == .reminder || classification.type == .event {
                    Button {
                        viewModel.createReminderOrEvent()
                    } label: {
                        HStack {
                            Image(systemName: classification.type == .reminder ? "bell.badge.fill" : "calendar.badge.plus")
                                .accessibilityHidden(true)
                            Text(classification.type == .reminder ? "Create Reminder" : "Add to Calendar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.primaryColor)
                    .disabled(viewModel.isCreatingTask)
                    .accessibilityIdentifier(classification.type == .reminder ? "createReminderButton" : "addToCalendarButton")
                    .overlay {
                        if viewModel.isCreatingTask {
                            ProgressView()
                                .tint(theme.primaryColor)
                        }
                    }

                    if viewModel.taskCreated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.successColor)
                            Text(classification.type == .reminder ? "Reminder created!" : "Event added!")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Context Section

    private var contextSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Context")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Spacer()

                // Refresh location button
                Button {
                    refreshLocation()
                } label: {
                    if isRefreshingLocation {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(theme.primaryColor)
                    } else {
                        Image(systemName: "location.circle")
                            .foregroundColor(theme.primaryColor)
                            .font(.caption)
                    }
                }
                .disabled(isRefreshingLocation)
                .accessibilityLabel("Refresh location")
                .accessibilityIdentifier("refreshLocationButton")

                // Debug button for energy breakdown
                Button {
                    showEnergyDebug.toggle()
                    if showEnergyDebug && energyBreakdown == nil {
                        loadEnergyBreakdown()
                    }
                } label: {
                    Image(systemName: showEnergyDebug ? "chevron.up.circle.fill" : "info.circle")
                        .foregroundColor(theme.primaryColor)
                        .font(.caption)
                }
                .accessibilityLabel(showEnergyDebug ? "Hide energy details" : "Show energy details")
                .accessibilityIdentifier("energyDebugButton")
            }

            ContextDisplayView(context: updatedContext)

            // Energy breakdown debug view
            if showEnergyDebug {
                if let breakdown = energyBreakdown {
                    EnergyBreakdownView(breakdown: breakdown)
                        .transition(.opacity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .tint(theme.primaryColor)
                }
            }
        }
    }

    private var updatedContext: Context {
        if let refreshedLocation = refreshedLocation {
            return Context(
                timestamp: viewModel.thought.context.timestamp,
                location: refreshedLocation,
                timeOfDay: viewModel.thought.context.timeOfDay,
                energy: viewModel.thought.context.energy,
                focusState: viewModel.thought.context.focusState,
                calendar: viewModel.thought.context.calendar,
                activity: viewModel.thought.context.activity,
                weather: viewModel.thought.context.weather,
                stateOfMind: viewModel.thought.context.stateOfMind,
                energyBreakdown: viewModel.thought.context.energyBreakdown
            )
        }
        return viewModel.thought.context
    }

    private func loadEnergyBreakdown() {
        _Concurrency.Task {
            let healthKitService = HealthKitService()
            energyBreakdown = await healthKitService.getEnergyBreakdown()
        }
    }

    private func refreshLocation() {
        guard !isRefreshingLocation else { return }

        _Concurrency.Task {
            isRefreshingLocation = true
            let locationService = LocationService()
            refreshedLocation = await locationService.getCurrentLocation()
            isRefreshingLocation = false
        }
    }

    // MARK: - Related Thoughts Section

    private var relatedThoughtsSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(theme.infoColor)
                Text("Related Thoughts")
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Spacer()

                if viewModel.isLoadingRelated {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(theme.primaryColor)
                }
            }

            if viewModel.relatedThoughts.isEmpty && !viewModel.isLoadingRelated {
                Text("No related thoughts found")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            } else {
                ForEach(viewModel.relatedThoughts) { result in
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
                        RelatedThoughtRow(result: result)
                    }
                }
            }
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Was this classification helpful?")
                .font(.headline)
                .foregroundColor(theme.textColor)

            HStack(spacing: 16) {
                FeedbackButton(
                    icon: "hand.thumbsup.fill",
                    label: "Helpful",
                    color: theme.successColor,
                    isSelected: viewModel.userFeedback?.type == .helpful,
                    identifier: "helpfulFeedbackButton"
                ) {
                    viewModel.provideFeedback(.helpful)
                }

                FeedbackButton(
                    icon: "hand.raised.fill",
                    label: "Okay",
                    color: theme.warningColor,
                    isSelected: viewModel.userFeedback?.type == .partially_helpful,
                    identifier: "partiallyHelpfulFeedbackButton"
                ) {
                    viewModel.provideFeedback(.partially_helpful)
                }

                FeedbackButton(
                    icon: "hand.thumbsdown.fill",
                    label: "Not Helpful",
                    color: theme.errorColor,
                    isSelected: viewModel.userFeedback?.type == .not_helpful,
                    identifier: "notHelpfulFeedbackButton"
                ) {
                    viewModel.provideFeedback(.not_helpful)
                }
            }

            if viewModel.userFeedback != nil {
                Text("Thanks for your feedback!")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)
                .foregroundColor(theme.textColor)

            HStack {
                Text("Created")
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
                Text(viewModel.createdAtFormatted)
                    .foregroundColor(theme.textColor)
            }
            .font(.subheadline)

            if let updatedAt = viewModel.updatedAtFormatted {
                HStack {
                    Text("Updated")
                        .foregroundColor(theme.secondaryTextColor)
                    Spacer()
                    Text(updatedAt)
                        .foregroundColor(theme.textColor)
                }
                .font(.subheadline)
            }

            HStack {
                Text("Status")
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
                Text(viewModel.thought.status.rawValue.capitalized)
                    .foregroundColor(statusColor(for: theme))
            }
            .font(.subheadline)

            HStack {
                Text("ID")
                    .foregroundColor(theme.secondaryTextColor)
                Spacer()
                Text(viewModel.thought.id.uuidString.prefix(8) + "...")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            .font(.subheadline)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius)
    }

    private func statusColor(for theme: any ThemeVariant) -> Color {
        switch viewModel.thought.status {
        case .active: return theme.successColor
        case .archived: return theme.warningColor
        case .completed: return theme.infoColor
        }
    }
}

// MARK: - Feedback Button

/// A button for providing feedback on classification.
struct FeedbackButton: View {
    @Environment(\.themeEngine) private var themeEngine

    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? color : theme.secondaryTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.1) : theme.surfaceColor)
            .cornerRadius(theme.cornerRadius)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Feedback: \(label)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Energy Breakdown View

/// Debug view showing how energy level is calculated.
struct EnergyBreakdownView: View {
    @Environment(\.themeEngine) private var themeEngine

    let breakdown: EnergyBreakdown

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 10) {
            Text("Energy Calculation")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryColor)

            VStack(spacing: 8) {
                // Sleep component (40% weight)
                BreakdownRow(
                    label: "Sleep Quality",
                    score: breakdown.sleepScore,
                    weight: 0.4,
                    contribution: breakdown.sleepScore * 0.4,
                    rawValue: breakdown.sleepHours.map { String(format: "%.1f hrs", $0) }
                )

                // Activity component (25% weight)
                BreakdownRow(
                    label: "Activity Level",
                    score: breakdown.activityScore,
                    weight: 0.25,
                    contribution: breakdown.activityScore * 0.25,
                    rawValue: breakdown.stepCount.map { "\($0) steps" }
                )

                // HRV component (20% weight)
                BreakdownRow(
                    label: "HRV/Recovery",
                    score: breakdown.hrvScore,
                    weight: 0.2,
                    contribution: breakdown.hrvScore * 0.2,
                    rawValue: breakdown.hrvValueMs.map { String(format: "%.1f ms", $0) }
                )

                // Time of day component (15% weight)
                BreakdownRow(
                    label: "Time of Day",
                    score: breakdown.timeBonus,
                    weight: 0.15,
                    contribution: breakdown.timeBonus * 0.15,
                    rawValue: nil
                )

                ThemedDivider()

                // Total
                HStack {
                    Text("Total Score")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                    Spacer()
                    Text(String(format: "%.2f", breakdown.totalScore))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textColor)
                }

                HStack {
                    Text("Energy Level")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textColor)
                    Spacer()
                    Text(breakdown.level.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(energyLevelColor(for: breakdown.level, theme: theme))
                }
            }
        }
        .padding(12)
        .background(theme.primaryColor.opacity(0.1))
        .cornerRadius(theme.cornerRadius)
    }

    private func energyLevelColor(for level: EnergyLevel, theme: any ThemeVariant) -> Color {
        switch level {
        case .low: return theme.errorColor
        case .medium: return theme.warningColor
        case .high: return theme.successColor
        case .peak: return theme.accentColor
        }
    }
}

/// A single row in the energy breakdown display.
struct BreakdownRow: View {
    @Environment(\.themeEngine) private var themeEngine

    let label: String
    let score: Double
    let weight: Double
    let contribution: Double
    let rawValue: String?

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    if let rawValue = rawValue {
                        Text(rawValue)
                            .font(.caption2)
                            .foregroundColor(theme.primaryColor)
                    }
                }
                Spacer()
                Text(String(format: "%.0f%%", weight * 100))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }

            HStack(spacing: 8) {
                // Score bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(theme.surfaceColor)
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(colorForScore(score, theme: theme))
                            .frame(width: geometry.size.width * score, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)

                // Score value
                Text(String(format: "%.2f", score))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
                    .frame(width: 35, alignment: .trailing)

                // Contribution value
                Text(String(format: "= %.2f", contribution))
                    .font(.caption2)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }

    private func colorForScore(_ score: Double, theme: any ThemeVariant) -> Color {
        switch score {
        case 0..<0.33: return theme.errorColor
        case 0.33..<0.66: return theme.warningColor
        case 0.66..<0.85: return theme.successColor
        default: return theme.accentColor
        }
    }
}

// MARK: - Previews

#Preview("Detail Screen") {
    NavigationStack {
        DetailScreen(
            viewModel: DetailViewModel(
                thought: Thought(
                    id: UUID(),
                    userId: UUID(),
                    content: "Need to review the Q4 marketing strategy and prepare presentation for the board meeting next Tuesday.",
                    attributedContent: nil,
                    tags: ["work", "presentation", "urgent"],
                    status: .active,
                    context: Context(
                        timestamp: Date(),
                        location: Location(
                            latitude: 37.7749,
                            longitude: -122.4194,
                            name: "Office",
                            geofenceId: nil
                        ),
                        timeOfDay: .morning,
                        energy: .high,
                        focusState: .deep_work,
                        calendar: CalendarContext(
                            nextEventMinutes: 120,
                            isFreetime: false,
                            eventCount: 5
                        ),
                        activity: ActivityContext(
                            stepCount: 2500,
                            caloriesBurned: 150.0,
                            activeMinutes: 30
                        ),
                        weather: nil,
                        stateOfMind: nil,
                        energyBreakdown: nil
                    ),
                    createdAt: Date().addingTimeInterval(-86400),
                    updatedAt: Date(),
                    classification: Classification(
                        id: UUID(),
                        type: .reminder,
                        confidence: 0.91,
                        entities: ["Q4 marketing strategy", "board meeting", "Tuesday"],
                        suggestedTags: ["meeting", "review"],
                        sentiment: .neutral,
                        language: "en",
                        processingTime: 180,
                        model: "foundation-model-v1",
                        createdAt: Date(),
                        parsedDateTime: nil
                    ),
                    relatedThoughtIds: [],
                    taskId: nil
                ),
                thoughtService: ThoughtService.shared,
                fineTuningService: FineTuningService.shared,
                taskService: TaskService.shared
            )
        )
    }
}

// MARK: - Related Thought Row

/// A compact row displaying a related thought with relevance scoring
struct RelatedThoughtRow: View {
    @Environment(\.themeEngine) private var themeEngine

    let result: SearchResult

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 6) {
            Text(result.thought.content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(theme.textColor)

            HStack(spacing: 8) {
                // Date
                Text(result.thought.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)

                Spacer()

                // Relevance score
                HStack(spacing: 4) {
                    Image(systemName: result.isHighConfidence ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.caption2)
                        .foregroundColor(result.isHighConfidence ? theme.successColor : theme.warningColor)

                    Text("\(result.relevancePercentage)% similar")
                        .font(.caption)
                        .foregroundColor(theme.infoColor)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius - 2)
    }
}
