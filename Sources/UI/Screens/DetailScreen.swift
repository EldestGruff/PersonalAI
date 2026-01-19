//
//  DetailScreen.swift
//  PersonalAI
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

    var body: some View {
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

                // Feedback section
                feedbackSection

                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Thought")
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
                } else {
                    Button("Edit") {
                        viewModel.startEditing()
                    }
                }
            }

            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                    }
                }
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)

            if viewModel.isEditing {
                TextEditor(text: $viewModel.editedContent)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                Text(viewModel.thought.content)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)

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
        VStack(alignment: .leading, spacing: 12) {
            Text("Classification")
                .font(.headline)

            if let classification = viewModel.thought.classification {
                ClassificationBadge(classification: classification)
            }
        }
    }

    // MARK: - Context Section

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context")
                .font(.headline)

            ContextDisplayView(context: viewModel.thought.context)
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Was this classification helpful?")
                .font(.headline)

            HStack(spacing: 16) {
                FeedbackButton(
                    icon: "hand.thumbsup.fill",
                    label: "Helpful",
                    color: .green,
                    isSelected: viewModel.userFeedback?.type == .helpful
                ) {
                    viewModel.provideFeedback(.helpful)
                }

                FeedbackButton(
                    icon: "hand.raised.fill",
                    label: "Okay",
                    color: .orange,
                    isSelected: viewModel.userFeedback?.type == .partially_helpful
                ) {
                    viewModel.provideFeedback(.partially_helpful)
                }

                FeedbackButton(
                    icon: "hand.thumbsdown.fill",
                    label: "Not Helpful",
                    color: .red,
                    isSelected: viewModel.userFeedback?.type == .not_helpful
                ) {
                    viewModel.provideFeedback(.not_helpful)
                }
            }

            if viewModel.userFeedback != nil {
                Text("Thanks for your feedback!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            HStack {
                Text("Created")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.createdAtFormatted)
            }
            .font(.subheadline)

            if let updatedAt = viewModel.updatedAtFormatted {
                HStack {
                    Text("Updated")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(updatedAt)
                }
                .font(.subheadline)
            }

            HStack {
                Text("Status")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.thought.status.rawValue.capitalized)
                    .foregroundColor(statusColor)
            }
            .font(.subheadline)

            HStack {
                Text("ID")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.thought.id.uuidString.prefix(8) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }

    private var statusColor: Color {
        switch viewModel.thought.status {
        case .active: return .green
        case .archived: return .orange
        case .completed: return .blue
        }
    }
}

// MARK: - Feedback Button

/// A button for providing feedback on classification.
struct FeedbackButton: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? color : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
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
                        weather: nil
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
                        createdAt: Date()
                    ),
                    relatedThoughtIds: [],
                    taskId: nil
                ),
                thoughtService: ThoughtService.shared,
                fineTuningService: FineTuningService.shared
            )
        )
    }
}
