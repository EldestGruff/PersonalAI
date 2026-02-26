//
//  DetailViewModel.swift
//  STASH
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

    /// Edited classification type (while in edit mode) (#49)
    var editedClassificationType: ClassificationType?

    /// Whether the classification type picker is showing (#49)
    var showingClassificationPicker: Bool = false

    /// Whether changes are being saved
    var isSaving: Bool = false

    // MARK: - Task Creation State

    /// Whether a task is being created
    var isCreatingTask: Bool = false

    /// Whether a task was created successfully
    var taskCreated: Bool = false

    // MARK: - Action Prompt State (#33 & #34)

    /// Whether the action prompt has been permanently dismissed for this thought
    var actionPromptDismissed: Bool = false

    /// Whether the confirmation sheet is showing before creating
    var showingConfirmationSheet: Bool = false

    /// Editable title in the confirmation sheet
    var confirmationTitle: String = ""

    /// Editable date in the confirmation sheet (for events)
    var confirmationDate: Date = Date()

    /// Event duration in minutes in the confirmation sheet
    var confirmationDurationMinutes: Int = 60

    // MARK: - Error State

    /// Current error to display
    var error: AppError?

    // MARK: - Related Thoughts State

    /// Related thoughts for this thought
    var relatedThoughts: [SearchResult] = []

    /// Whether related thoughts are loading
    var isLoadingRelated: Bool = false

    /// Whether to show the related thoughts section
    var hasRelatedThoughts: Bool {
        !relatedThoughts.isEmpty
    }

    // MARK: - Services

    private let thoughtService: ThoughtService
    private let fineTuningService: FineTuningService
    private let taskService: TaskService
    private let smartInsights = SmartInsightsService.shared

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

        // Load dismissed state (#33)
        self.actionPromptDismissed = UserDefaults.standard.bool(forKey: "dismissedActionPrompt_\(thought.id.uuidString)")
    }

    // MARK: - Feedback Actions

    /// Loads previously stored feedback from CoreData so the UI reflects it on return.
    func loadFeedback() async {
        userFeedback = await fineTuningService.getFeedback(for: thought.id)
    }

    /// Provides feedback on the thought/classification
    func provideFeedback(_ type: UserFeedback.FeedbackType, comment: String? = nil) {
        let feedback = UserFeedback(type: type, comment: comment, timestamp: Date())
        userFeedback = feedback
        isSubmittingFeedback = true

        _Concurrency.Task {
            do {
                try await fineTuningService.trackUserFeedback(
                    thoughtId: thought.id,
                    feedbackType: type,
                    correction: comment
                )
            } catch {
                // Silently fail - feedback is best-effort
            }

            // Update local bias store
            if let currentType = thought.classification?.type {
                let pattern = ClassificationBiasStore.extractPattern(from: thought.content)
                if type == .not_helpful {
                    ClassificationBiasStore.shared.record(pattern: pattern, penalizedType: currentType.rawValue)
                } else if type == .helpful {
                    ClassificationBiasStore.shared.reinforce(pattern: pattern, penalizedType: currentType.rawValue)
                }
            }

            isSubmittingFeedback = false
        }
    }

    // MARK: - Edit Actions

    /// Enters edit mode
    func startEditing() {
        editedContent = thought.content
        editedTags = thought.tags
        editedClassificationType = thought.classification?.type
        isEditing = true
    }

    /// Cancels editing
    func cancelEditing() {
        isEditing = false
        editedContent = ""
        editedTags = []
        editedClassificationType = nil
        showingClassificationPicker = false
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
                // Check if classification type changed (#49)
                var updatedClassification = thought.classification
                if let newType = editedClassificationType,
                   let currentClassification = thought.classification,
                   newType != currentClassification.type {
                    // Sanitize suggested tags (fix underscores, uppercase, etc.)
                    let sanitizedTags = currentClassification.suggestedTags.map { tag in
                        tag.lowercased()
                            .replacingOccurrences(of: "_", with: "-")
                            .replacingOccurrences(of: " ", with: "-")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    // Create new Classification with updated type
                    updatedClassification = Classification(
                        id: currentClassification.id,
                        type: newType,
                        confidence: 1.0,  // User override has 100% confidence
                        entities: currentClassification.entities,
                        suggestedTags: sanitizedTags,  // Use sanitized tags
                        sentiment: currentClassification.sentiment,
                        language: currentClassification.language,
                        processingTime: 1.0,  // Minimal processing time for validation
                        model: "user-override",
                        createdAt: currentClassification.createdAt,
                        parsedDateTime: currentClassification.parsedDateTime
                    )
                }

                // Create updated thought (Thought is immutable, so create new instance)
                let updated = Thought(
                    id: thought.id,
                    userId: thought.userId,
                    content: trimmedContent,
                    attributedContent: nil,
                    tags: editedTags,
                    status: thought.status,
                    context: thought.context,
                    createdAt: thought.createdAt,
                    updatedAt: Date(),
                    classification: updatedClassification,
                    relatedThoughtIds: thought.relatedThoughtIds,
                    taskId: thought.taskId
                )

                // Save
                self.thought = try await thoughtService.update(updated)

                // Analytics + bias correction: only fire if save succeeded
                if let newType = editedClassificationType,
                   let originalType = thought.classification?.type,
                   newType != originalType {
                    AnalyticsService.shared.track(.classificationOverridden(from: originalType.rawValue, to: newType.rawValue))

                    // Record explicit type correction so future captures of similar
                    // content get the preferred type applied by ClassificationBiasStore
                    let pattern = ClassificationBiasStore.extractPattern(from: trimmedContent)
                    ClassificationBiasStore.shared.record(
                        pattern: pattern,
                        penalizedType: originalType.rawValue,
                        preferredType: newType.rawValue
                    )
                }

                // Exit edit mode
                self.isEditing = false
                self.editedContent = ""
                self.editedTags = []
                self.editedClassificationType = nil
                self.showingClassificationPicker = false

            } catch {
                // Enhanced error logging for debugging (#49)
                NSLog("❌ DetailViewModel - Save failed: %@", error.localizedDescription)
                NSLog("❌ Error type: %@", String(describing: type(of: error)))
                if let validationError = error as? ValidationError {
                    NSLog("❌ Validation error details: %@", String(describing: validationError))
                }
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

    /// Permanently dismisses the action prompt for this thought (#33)
    func dismissActionPrompt() {
        UserDefaults.standard.set(true, forKey: "dismissedActionPrompt_\(thought.id.uuidString)")
        actionPromptDismissed = true
    }

    /// Entry point for the action button. Shows confirmation sheet unless auto-create is on (#34)
    func requestAction() {
        guard let classification = thought.classification else { return }
        guard !isCreatingTask else { return }

        let autoCreate = UserDefaults.standard.bool(forKey: "autoCreateReminders")

        if autoCreate {
            createReminderOrEvent()
        } else {
            // Pre-fill confirmation fields
            confirmationTitle = extractCleanTitle(from: thought.content, parsedDateTime: classification.parsedDateTime)
            let (startDate, _) = calculateEventTimes(from: classification.parsedDateTime)
            confirmationDate = startDate
            confirmationDurationMinutes = 60
            showingConfirmationSheet = true
        }
    }

    /// Creates with the user-edited confirmation sheet values (#34)
    func confirmCreate() {
        showingConfirmationSheet = false
        createReminderOrEvent(
            titleOverride: confirmationTitle,
            startDateOverride: confirmationDate,
            durationOverride: confirmationDurationMinutes
        )
    }

    /// Creates a reminder or event from the thought
    func createReminderOrEvent(titleOverride: String? = nil, startDateOverride: Date? = nil, durationOverride: Int? = nil) {
        guard let classification = thought.classification else { return }
        guard !isCreatingTask else { return }

        isCreatingTask = true
        taskCreated = false
        error = nil

        _Concurrency.Task {
            do {
                // Use override title or derive from content
                let cleanTitle = titleOverride ?? extractCleanTitle(
                    from: thought.content,
                    parsedDateTime: classification.parsedDateTime
                )

                let task = Task(
                    id: UUID(),
                    userId: thought.userId,
                    sourceThoughtId: thought.id,
                    title: cleanTitle,
                    description: thought.content,
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
                    // Use override dates or calculate from parsed date/time
                    let eventStart: Date
                    let eventEnd: Date
                    if let overrideStart = startDateOverride {
                        eventStart = overrideStart
                        eventEnd = overrideStart.addingTimeInterval(TimeInterval((durationOverride ?? 60) * 60))
                    } else {
                        (eventStart, eventEnd) = calculateEventTimes(from: classification.parsedDateTime)
                    }
                    let startDate = eventStart
                    let endDate = eventEnd

                    _ = try await taskService.createCalendarEvent(
                        for: created,
                        startDate: startDate,
                        endDate: endDate
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

    // MARK: - Date/Time Helpers

    /// Extract a clean title by removing the date/time portion from the content.
    ///
    /// Uses the matchedText from parsed date/time to remove the temporal reference.
    /// Falls back to using the full content if no match is found.
    private func extractCleanTitle(from content: String, parsedDateTime: ParsedDateTime?) -> String {
        guard let parsedDateTime = parsedDateTime,
              let matchedText = parsedDateTime.matchedText,
              !matchedText.isEmpty else {
            return content
        }

        // Remove the matched date/time text
        var cleanedContent = content

        // Try case-insensitive replacement
        if let range = cleanedContent.range(of: matchedText, options: [.caseInsensitive]) {
            cleanedContent.removeSubrange(range)
        }

        // Clean up extra whitespace and punctuation
        cleanedContent = cleanedContent
            .replacingOccurrences(of: "  ", with: " ")  // Double spaces
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove leading/trailing punctuation that might be left over
        let punctuationSet = CharacterSet(charactersIn: ",-:;")
        cleanedContent = cleanedContent.trimmingCharacters(in: punctuationSet)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // If we removed too much and the title is now too short, use original
        if cleanedContent.count < 3 {
            return content
        }

        // Capitalize first letter if needed
        if let firstChar = cleanedContent.first, firstChar.isLowercase {
            cleanedContent = cleanedContent.prefix(1).uppercased() + cleanedContent.dropFirst()
        }

        return cleanedContent
    }

    /// Calculate event start and end times from parsed date/time.
    ///
    /// Returns a tuple of (startDate, endDate) for calendar events.
    /// Falls back to sensible defaults if no date/time was parsed.
    private func calculateEventTimes(from parsedDateTime: ParsedDateTime?) -> (Date, Date) {
        guard let parsedDateTime = parsedDateTime,
              let baseDate = parsedDateTime.date else {
            // Fallback: 1 hour from now, duration 1 hour
            let now = Date()
            return (now.addingTimeInterval(3600), now.addingTimeInterval(7200))
        }

        let calendar = Calendar.current

        // If we have a specific time of day, use it
        if let timeOfDay = parsedDateTime.timeOfDay {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            let hours = timeOfDay / 3600
            let minutes = (timeOfDay % 3600) / 60

            var components = dateComponents
            components.hour = hours
            components.minute = minutes
            components.second = 0

            if let startDate = calendar.date(from: components) {
                // Default event duration: 1 hour
                let endDate = startDate.addingTimeInterval(3600)
                return (startDate, endDate)
            }
        }

        // All-day event: use 9am to 10am on that date
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = 9
        components.minute = 0
        components.second = 0

        if let startDate = calendar.date(from: components) {
            let endDate = startDate.addingTimeInterval(3600)
            return (startDate, endDate)
        }

        // Final fallback
        return (baseDate, baseDate.addingTimeInterval(3600))
    }

    // MARK: - Delete Action

    /// Deletes the current thought
    func deleteThought() async throws {
        try await thoughtService.delete(thought.id)
        AnalyticsService.shared.track(.thoughtDeleted)
    }

    // MARK: - Related Thoughts

    /// Load related thoughts for this thought
    func loadRelatedThoughts() async {
        guard !isLoadingRelated else { return }

        isLoadingRelated = true

        do {
            // Fetch all thoughts to search
            let allThoughts = try await thoughtService.list(filter: nil)

            // Find related thoughts using semantic search
            let related = await smartInsights.findRelatedThoughts(
                for: thought,
                in: allThoughts,
                limit: 5
            )

            self.relatedThoughts = related

        } catch {
            // Silently fail - related thoughts are nice-to-have
            self.relatedThoughts = []
        }

        isLoadingRelated = false
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
