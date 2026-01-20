//
//  DetailViewModel.swift
//  PersonalAI
//
//  Phase 3A Spec 3: Thought Detail ViewModel
//  Manages state for viewing and interacting with a thought
//

import Foundation
import Observation

// MARK: - Context Display

/// Formatted context for display in UI
struct ContextDisplay: Equatable, Sendable {
    let timeOfDay: String
    let location: String?
    let energy: String
    let focus: String
    let activity: String?

    init(from context: Context) {
        // Time of day
        self.timeOfDay = context.timeOfDay.rawValue.capitalized

        // Location
        if let loc = context.location {
            self.location = loc.name ?? "\(String(format: "%.2f", loc.latitude)), \(String(format: "%.2f", loc.longitude))"
        } else {
            self.location = nil
        }

        // Energy
        self.energy = context.energy.rawValue.capitalized

        // Focus
        self.focus = context.focusState.rawValue.replacingOccurrences(of: "_", with: " ").capitalized

        // Activity (from ActivityContext if available)
        if let activityContext = context.activity {
            self.activity = "Steps: \(activityContext.stepCount)"
        } else {
            self.activity = nil
        }
    }
}

// MARK: - Detail ViewModel

/// ViewModel for the thought detail screen.
///
/// Manages:
/// - Displaying thought content and metadata
/// - Showing context and classification details
/// - User feedback for fine-tuning
/// - Edit operations
@Observable
@MainActor
final class DetailViewModel {
    // MARK: - Thought State

    /// The thought being displayed
    var thought: Thought

    /// Formatted context for display
    var contextDisplay: ContextDisplay?

    // MARK: - Feedback State

    /// User's feedback on this thought/classification
    var userFeedback: UserFeedback?

    /// Whether feedback is being submitted
    var isSubmittingFeedback: Bool = false

    // MARK: - Edit State

    /// Whether the thought is being edited
    var isEditing: Bool = false

    /// Edited content (while in edit mode)
    var editedContent: String = ""

    /// Edited tags (while in edit mode)
    var editedTags: [String] = []

    /// Whether changes are being saved
    var isSaving: Bool = false

    // MARK: - Task Creation State

    /// Whether a task is being created
    var isCreatingTask: Bool = false

    /// Whether a task was created successfully
    var taskCreated: Bool = false

    // MARK: - Error State

    /// Current error to display
    var error: AppError?

    // MARK: - Services

    private let thoughtService: ThoughtService
    private let fineTuningService: FineTuningService
    private let taskService: TaskService

    // MARK: - Initialization

    init(
        thought: Thought,
        thoughtService: ThoughtService,
        fineTuningService: FineTuningService,
        taskService: TaskService
    ) {
        self.thought = thought
        self.thoughtService = thoughtService
        self.fineTuningService = fineTuningService
        self.taskService = taskService

        // Initialize context display
        self.contextDisplay = ContextDisplay(from: thought.context)
    }

    // MARK: - Feedback Actions

    /// Provides feedback on the thought/classification
    func provideFeedback(_ type: UserFeedback.FeedbackType, comment: String? = nil) {
        let feedback = UserFeedback(type: type, comment: comment, timestamp: Date())
        userFeedback = feedback
        isSubmittingFeedback = true

        _Concurrency.Task {
            do {
                try await fineTuningService.trackUserFeedback(
                    thoughtId: thought.id,
                    isPositive: type == .helpful,
                    correction: comment
                )
            } catch {
                // Silently fail - feedback is best-effort
            }

            isSubmittingFeedback = false
        }
    }

    // MARK: - Edit Actions

    /// Enters edit mode
    func startEditing() {
        editedContent = thought.content
        editedTags = thought.tags
        isEditing = true
    }

    /// Cancels editing
    func cancelEditing() {
        isEditing = false
        editedContent = ""
        editedTags = []
    }

    /// Saves edited changes
    func saveChanges() {
        guard isEditing else { return }

        let trimmedContent = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            error = .validationFailed("Content cannot be empty")
            return
        }

        isSaving = true
        error = nil

        _Concurrency.Task {
            do {
                // Create updated thought (Thought is immutable, so create new instance)
                let updated = Thought(
                    id: thought.id,
                    userId: thought.userId,
                    content: trimmedContent,
                    tags: editedTags,
                    status: thought.status,
                    context: thought.context,
                    createdAt: thought.createdAt,
                    updatedAt: Date(),
                    classification: thought.classification,
                    relatedThoughtIds: thought.relatedThoughtIds,
                    taskId: thought.taskId
                )

                // Save
                self.thought = try await thoughtService.update(updated)

                // Exit edit mode
                self.isEditing = false
                self.editedContent = ""
                self.editedTags = []

            } catch {
                self.error = AppError.from(error)
            }

            isSaving = false
        }
    }

    /// Adds a tag during editing
    func addEditTag(_ tag: String) {
        let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTag.isEmpty,
              editedTags.count < 5,
              !editedTags.contains(normalizedTag) else {
            return
        }
        editedTags.append(normalizedTag)
    }

    /// Removes a tag during editing
    func removeEditTag(_ tag: String) {
        editedTags.removeAll { $0 == tag }
    }

    // MARK: - Task Creation Actions

    /// Creates a reminder or event from the thought
    func createReminderOrEvent() {
        guard let classification = thought.classification else { return }
        guard !isCreatingTask else { return }

        isCreatingTask = true
        taskCreated = false
        error = nil

        _Concurrency.Task {
            do {
                // Create Task model
                let task = Task(
                    id: UUID(),
                    userId: thought.userId,
                    sourceThoughtId: thought.id,
                    title: thought.content,
                    description: nil,
                    priority: .medium,
                    status: .pending,
                    dueDate: nil,
                    estimatedEffortMinutes: 30,
                    createdAt: Date(),
                    updatedAt: Date(),
                    completedAt: nil,
                    reminderId: nil,
                    eventId: nil
                )

                let created = try await taskService.create(task)

                // Create system reminder or calendar event
                if classification.type == .reminder {
                    _ = try await taskService.createSystemReminder(for: created)
                    try await fineTuningService.trackReminderCreated(thought.id)
                } else if classification.type == .event {
                    _ = try await taskService.createCalendarEvent(
                        for: created,
                        startDate: Date().addingTimeInterval(3600), // 1 hour from now
                        endDate: Date().addingTimeInterval(7200) // 2 hours from now
                    )
                    try await fineTuningService.trackEventCreated(thought.id)
                }

                taskCreated = true

            } catch {
                NSLog("❌ DetailViewModel - Error creating reminder/event: %@", error.localizedDescription)
                NSLog("❌ Error type: %@", String(describing: type(of: error)))
                self.error = AppError.from(error)
                NSLog("❌ Converted to AppError: %@", self.error?.localizedDescription ?? "nil")
            }

            isCreatingTask = false
        }
    }

    // MARK: - Computed Properties

    /// Whether the thought has classification
    var hasClassification: Bool {
        thought.classification != nil
    }

    /// Whether the thought has context
    var hasContext: Bool {
        contextDisplay != nil
    }

    /// Formatted creation date
    var createdAtFormatted: String {
        thought.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    /// Formatted update date (if different from creation)
    var updatedAtFormatted: String? {
        guard thought.updatedAt != thought.createdAt else { return nil }
        return thought.updatedAt.formatted(date: .abbreviated, time: .shortened)
    }
}
