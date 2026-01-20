//
//  CaptureViewModel.swift
//  PersonalAI
//
//  Phase 3A Spec 3: Thought Capture ViewModel
//  Manages state for the thought capture flow
//

import Foundation
import Observation

// MARK: - Capture ViewModel

/// ViewModel for the thought capture screen.
///
/// Manages the complete capture flow including:
/// - Text/voice input
/// - Tag management
/// - Context gathering (parallel, non-blocking)
/// - Classification (automatic, graceful degradation)
/// - Saving to persistence
///
/// All operations are async and never block the main thread.
@Observable
@MainActor
final class CaptureViewModel {
    // MARK: - Input State

    /// The thought content being captured
    var thoughtContent: String = ""

    /// Tags selected for this thought
    var selectedTags: [String] = []

    /// Whether voice input mode is active
    var voiceInputMode: Bool = false

    // MARK: - Processing State

    /// Whether a capture operation is in progress
    var isCapturing: Bool = false

    /// Gathered context for the thought
    var context: Context?

    /// Error message if context gathering failed
    var contextError: String?

    /// Classification result for the thought
    var classification: Classification?

    /// Error message if classification failed
    var classificationError: String?

    // MARK: - UI State

    /// Whether to show the permission alert
    var showPermissionAlert: Bool = false

    /// Message for the permission alert
    var permissionAlertMessage: String = ""

    /// Whether context is currently loading
    var isContextLoading: Bool = false

    /// Whether classification is currently loading
    var isClassificationLoading: Bool = false

    /// Whether the capture was successful (for dismissal)
    var captureSucceeded: Bool = false

    // MARK: - Error Handling

    /// Current error to display to user
    var error: AppError?

    // MARK: - Services

    private let thoughtService: ThoughtService
    private let contextService: ContextService
    private let classificationService: ClassificationService
    private let fineTuningService: FineTuningService
    private let taskService: TaskService
    private let settingsViewModel: SettingsViewModel?

    // MARK: - Constants

    private let maxContentLength = 5000
    private let maxTags = 5

    // MARK: - Initialization

    init(
        thoughtService: ThoughtService,
        contextService: ContextService,
        classificationService: ClassificationService,
        fineTuningService: FineTuningService,
        taskService: TaskService,
        settingsViewModel: SettingsViewModel? = nil
    ) {
        self.thoughtService = thoughtService
        self.contextService = contextService
        self.classificationService = classificationService
        self.fineTuningService = fineTuningService
        self.taskService = taskService
        self.settingsViewModel = settingsViewModel
    }

    // MARK: - Computed Properties

    /// Whether the current input is valid for capture
    var isValid: Bool {
        let trimmed = thoughtContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxContentLength
    }

    /// Character count for display
    var characterCount: Int {
        thoughtContent.count
    }

    /// Whether character limit is exceeded
    var isOverLimit: Bool {
        thoughtContent.count > maxContentLength
    }

    // MARK: - Input Actions

    /// Toggles between text and voice input modes
    func toggleVoiceInput() {
        voiceInputMode.toggle()
    }

    /// Adds a tag to the selected tags
    func addTag(_ tag: String) {
        let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTag.isEmpty,
              selectedTags.count < maxTags,
              !selectedTags.contains(normalizedTag) else {
            return
        }
        selectedTags.append(normalizedTag)
    }

    /// Removes a tag from the selected tags
    func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }

    // MARK: - Processing Actions

    /// Gathers context in the background (non-blocking)
    func gatherContext() {
        isContextLoading = true
        contextError = nil

        _Concurrency.Task {
            let gatheredContext = await contextService.gatherContext()
            self.context = gatheredContext
            self.isContextLoading = false
        }
    }

    /// Classifies the thought content (non-blocking)
    func classifyThought() {
        guard isValid else { return }

        isClassificationLoading = true
        classificationError = nil

        _Concurrency.Task {
            do {
                let result = try await classificationService.classify(thoughtContent)
                self.classification = result

                // Merge suggested tags (up to max)
                for tag in result.suggestedTags {
                    if self.selectedTags.count >= self.maxTags { break }
                    self.addTag(tag)
                }
            } catch {
                self.classificationError = "Classification unavailable"
                self.classification = nil
            }

            self.isClassificationLoading = false
        }
    }

    /// Captures and saves the thought
    func captureThought() {
        guard isValid else { return }

        isCapturing = true
        error = nil

        _Concurrency.Task {
            do {
                // Ensure we have context (gather if not already)
                if context == nil {
                    context = await contextService.gatherContext()
                }

                // Ensure we have classification (classify if not already)
                if classification == nil {
                    classification = try? await classificationService.classify(thoughtContent)
                }

                // Create thought model
                let thought = Thought(
                    id: UUID(),
                    userId: UUID(), // Phase 3A: hardcoded, Phase 4+ from settings
                    content: thoughtContent.trimmingCharacters(in: .whitespacesAndNewlines),
                    tags: selectedTags,
                    status: .active,
                    context: context ?? Context.empty(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    classification: classification,
                    relatedThoughtIds: [],
                    taskId: nil
                )

                // Save thought
                let saved = try await thoughtService.create(thought)

                // Track for fine-tuning (fire and forget)
                if let classification = classification {
                    _Concurrency.Task {
                        try? await fineTuningService.trackThoughtCreated(saved, classification: classification)
                    }
                }

                // Auto-create reminder/event if enabled
                if let settings = settingsViewModel,
                   settings.autoCreateReminders,
                   let classification = classification {
                    await self.autoCreateTask(for: saved, classification: classification)
                }

                // Success - reset form
                self.resetForm()
                self.captureSucceeded = true
                self.error = nil

            } catch {
                self.error = AppError.from(error)
            }

            self.isCapturing = false
        }
    }

    /// Resets the form to initial state
    func resetForm() {
        thoughtContent = ""
        selectedTags = []
        voiceInputMode = false
        context = nil
        classification = nil
        contextError = nil
        classificationError = nil
        captureSucceeded = false
    }

    /// Updates content from voice transcription
    func updateFromTranscription(_ text: String) {
        thoughtContent = text
        voiceInputMode = false
        classifyThought()
    }

    // MARK: - Auto-Creation

    /// Automatically creates a reminder or event if applicable
    private func autoCreateTask(for thought: Thought, classification: Classification) async {
        do {
            if classification.type == .reminder || classification.type == .event {
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
                    estimatedEffortMinutes: 0,
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
            }
        } catch {
            // Silently fail - auto-creation is best-effort
            // The thought was saved successfully, so we don't want to show an error
        }
    }
}
