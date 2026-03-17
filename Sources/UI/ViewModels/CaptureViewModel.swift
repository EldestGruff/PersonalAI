//
//  CaptureViewModel.swift
//  STASH
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

    /// Rich text content with formatting (iOS 15+)
    var attributedThoughtContent: AttributedString?

    /// Whether rich text formatting is enabled
    var isRichTextEnabled: Bool = false

    /// Tags selected for this thought
    var selectedTags: [String] = []

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

    /// Manually selected classification type (overrides AI classification) (#49)
    var manualClassificationType: ClassificationType?

    /// Whether the type picker is showing (#49)
    var showingTypePicker: Bool = false

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
    var captureDidSucceed: Bool = false

    // MARK: - Error Handling

    /// Current error to display to user
    var error: AppError?

    // MARK: - Similar Thoughts Insight

    /// Similar thoughts found (for helpful insight)
    var similarThoughts: [SearchResult] = []

    /// Whether similar thoughts are being checked
    var isCheckingSimilar: Bool = false

    /// Whether to show the similar thoughts insight
    var hasSimilarThoughts: Bool {
        !similarThoughts.isEmpty
    }

    // MARK: - Gamification Feedback

    /// Reward from the most recent capture — consumed by the UI for celebration
    var lastAcornReward: AcornReward?

    /// Badges newly earned from the most recent capture (empty if none)
    var lastEarnedBadges: [BadgeDefinition] = []

    /// Variable reward tier from the most recent capture (nil if no reward fired)
    var lastVariableReward: VRSTier?

    // MARK: - Services

    private let thoughtService: ThoughtService
    private let contextService: ContextService
    private let classificationService: ClassificationService
    private let fineTuningService: FineTuningService
    private let taskService: TaskService
    private let settingsViewModel: SettingsViewModel?
    private let subscriptionManager: SubscriptionManager
    private let smartInsights = SmartInsightsService.shared

    // MARK: - Debounce

    /// Task for debouncing classification requests
    private var classificationDebounceTask: _Concurrency.Task<Void, Never>?

    /// Task for debouncing similar thought checks
    private var similarCheckDebounceTask: _Concurrency.Task<Void, Never>?

    // MARK: - Constants

    private let maxContentLength = 5000
    private let maxTags = 5
    private let classificationDebounceDelay: Duration = .seconds(1.5)
    private let similarCheckDebounceDelay: Duration = .seconds(2.0)

    // MARK: - Initialization

    init(
        thoughtService: ThoughtService,
        contextService: ContextService,
        classificationService: ClassificationService,
        fineTuningService: FineTuningService,
        taskService: TaskService,
        settingsViewModel: SettingsViewModel? = nil,
        subscriptionManager: SubscriptionManager = .shared
    ) {
        self.thoughtService = thoughtService
        self.subscriptionManager = subscriptionManager
        self.contextService = contextService
        self.classificationService = classificationService
        self.fineTuningService = fineTuningService
        self.taskService = taskService
        self.settingsViewModel = settingsViewModel
    }

    // MARK: - Lifecycle

    /// Pre-warm services for optimal performance (Issue #8)
    /// Call this when capture screen appears
    func prewarmServices() {
        _Concurrency.Task {
            await classificationService.prewarm()
        }
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

    /// Toggles rich text formatting mode
    func toggleRichText() {
        isRichTextEnabled.toggle()

        if isRichTextEnabled {
            // Convert plain text to AttributedString
            attributedThoughtContent = AttributedString(thoughtContent)
        } else {
            // Extract plain text from AttributedString
            if let attributed = attributedThoughtContent {
                thoughtContent = String(attributed.characters)
            }
            attributedThoughtContent = nil
        }
    }

    /// Syncs plain text with attributed content
    func syncAttributedContent() {
        if isRichTextEnabled {
            if let attributed = attributedThoughtContent {
                thoughtContent = String(attributed.characters)
            }
        }
    }

    /// Adds a tag to the selected tags
    func addTag(_ tag: String) {
        let normalizedTag = tag.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Classifies the thought content with debounce (waits for user to stop typing)
    func classifyThought() {
        // Cancel any pending classification
        classificationDebounceTask?.cancel()

        // Don't classify if content is too short or invalid
        guard isValid else { return }

        // Create new debounced task
        classificationDebounceTask = _Concurrency.Task {
            // Wait for debounce delay
            try? await _Concurrency.Task.sleep(for: classificationDebounceDelay)

            // Check if cancelled during sleep
            guard !_Concurrency.Task.isCancelled else { return }

            // Perform classification
            await performClassification()
        }
    }

    /// Immediately classifies without debouncing (for voice input or paste)
    func classifyThoughtImmediately() {
        // Cancel any pending debounced classification
        classificationDebounceTask?.cancel()

        _Concurrency.Task {
            await performClassification()
        }
    }

    /// Internal method that performs the actual classification
    private func performClassification() async {
        guard isValid else { return }

        isClassificationLoading = true
        classificationError = nil

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

    // MARK: - Similar Thoughts Check

    /// Check for similar thoughts with debounce (waits for user to stop typing)
    func checkForSimilarThoughts() {
        // Cancel any pending check
        similarCheckDebounceTask?.cancel()

        // Don't check if content is too short
        guard thoughtContent.count > 20 else {
            similarThoughts = []
            return
        }

        // Create new debounced task
        similarCheckDebounceTask = _Concurrency.Task {
            // Wait for debounce delay
            try? await _Concurrency.Task.sleep(for: similarCheckDebounceDelay)

            // Check if cancelled during sleep
            guard !_Concurrency.Task.isCancelled else { return }

            // Perform similar check
            await performSimilarCheck()
        }
    }

    /// Internal method that performs the actual similar thoughts check
    private func performSimilarCheck() async {
        guard thoughtContent.count > 20 else {
            similarThoughts = []
            return
        }

        isCheckingSimilar = true

        do {
            // Fetch all thoughts
            let allThoughts = try await thoughtService.list(filter: nil)

            // Create a temporary thought for comparison
            let tempThought = Thought(
                id: UUID(),
                userId: UUID(),
                content: thoughtContent,
                    attributedContent: nil,
                tags: selectedTags,
                status: .active,
                context: Context.empty(),
                createdAt: Date(),
                updatedAt: Date(),
                classification: classification,
                relatedThoughtIds: [],
                taskId: nil
            )

            // Find possible duplicates (high similarity)
            let duplicates = await smartInsights.findPossibleDuplicates(
                for: tempThought,
                in: allThoughts
            )

            self.similarThoughts = Array(duplicates.prefix(3)) // Show top 3

        } catch {
            // Silently fail - similar thoughts are nice-to-have
            self.similarThoughts = []
        }

        isCheckingSimilar = false
    }

    /// Captures and saves the thought
    func captureThought() {
        guard isValid else { return }

        isCapturing = true
        error = nil

        _Concurrency.Task {
            do {
                guard try await checkSubscriptionEntitlement() else { return }

                if context == nil { context = await contextService.gatherContext() }
                if classification == nil { classification = try? await classificationService.classify(thoughtContent) }

                let finalClassification = buildFinalClassification()
                let thought = buildThought(classification: finalClassification)
                let saved = try await thoughtService.create(thought)

                if let cls = classification {
                    _Concurrency.Task {
                        try? await fineTuningService.trackThoughtCreated(saved, classification: cls)
                    }
                }

                if let settings = settingsViewModel, settings.autoCreateReminders,
                   let cls = finalClassification {
                    await autoCreateTask(for: saved, classification: cls)
                }

                // Enrich context in background — detects mentionedContacts, location, etc.
                _Concurrency.Task.detached {
                    await ContextEnrichmentService.shared.enrichContext(for: saved.id)
                }

                await processGamification(saved: saved)

                _Concurrency.Task.detached {
                    let key = AppConstants.PendingActions.captureTimestampsKey
                    var timestamps = (UserDefaults.standard.array(forKey: key) as? [Double]) ?? []
                    timestamps.append(Date().timeIntervalSince1970)
                    let cutoff = Date().addingTimeInterval(-60 * 24 * 3600).timeIntervalSince1970
                    timestamps = timestamps.filter { $0 > cutoff }
                    UserDefaults.standard.set(timestamps, forKey: key)
                }

                resetForm()
                captureDidSucceed = true
                error = nil
                AnalyticsService.shared.track(.thoughtCaptured(method: .text))

            } catch {
                self.error = AppError.from(error)
            }

            isCapturing = false
        }
    }

    /// Returns false and sets error/isCapturing if subscription limit reached.
    private func checkSubscriptionEntitlement() async throws -> Bool {
        let thoughts = try await thoughtService.list(filter: nil)
        let usage = SubscriptionUsage.calculate(from: thoughts)
        guard subscriptionManager.canCaptureThought(usage: usage) else {
            let limit = subscriptionManager.entitlements.thoughtLimit ?? 0
            self.error = .validationFailed(
                "You've reached your limit of \(limit) thoughts this month. Upgrade to Pro for unlimited thoughts."
            )
            self.isCapturing = false
            return false
        }
        return true
    }

    /// Applies manual type override to the AI classification result.
    private func buildFinalClassification() -> Classification? {
        guard let manualType = manualClassificationType else { return classification }
        guard let base = classification else {
            return Classification(
                id: UUID(),
                type: manualType,
                confidence: 1.0,
                entities: [],
                suggestedTags: [],
                sentiment: .neutral,
                language: "en",
                processingTime: 1.0,
                model: "user-override",
                createdAt: Date(),
                parsedDateTime: nil
            )
        }
        let sanitizedTags = base.suggestedTags.map { tag in
            tag.lowercased()
                .replacingOccurrences(of: "_", with: "-")
                .replacingOccurrences(of: " ", with: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return Classification(
            id: base.id,
            type: manualType,
            confidence: 1.0,
            entities: base.entities,
            suggestedTags: sanitizedTags,
            sentiment: base.sentiment,
            language: base.language,
            processingTime: 1.0,
            model: "user-override",
            createdAt: Date(),
            parsedDateTime: base.parsedDateTime
        )
    }

    /// Constructs the Thought value to save.
    private func buildThought(classification: Classification?) -> Thought {
        Thought(
            id: UUID(),
            userId: UUID(), // Phase 3A: hardcoded, Phase 4+ from settings
            content: thoughtContent.trimmingCharacters(in: .whitespacesAndNewlines),
            attributedContent: isRichTextEnabled ? attributedThoughtContent : nil,
            tags: selectedTags,
            status: .active,
            context: context ?? Context.empty(),
            createdAt: Date(),
            updatedAt: Date(),
            classification: classification,
            relatedThoughtIds: [],
            taskId: nil
        )
    }

    /// Runs all gamification side-effects and surfaces reward values for the UI.
    private func processGamification(saved: Thought) async {
        let hadContext = context?.location != nil
        let result = await GamificationCoordinator.processCapture(
            thought: saved,
            hadContext: hadContext,
            thoughtService: thoughtService
        )
        lastAcornReward = result.acornReward
        lastEarnedBadges = result.earnedBadges
        lastVariableReward = result.variableReward
    }

    /// Resets the form to initial state
    func resetForm() {
        thoughtContent = ""
        selectedTags = []
        context = nil
        classification = nil
        contextError = nil
        classificationError = nil
        captureDidSucceed = false
        manualClassificationType = nil
        showingTypePicker = false
    }


    // MARK: - Auto-Creation

    /// Automatically creates a reminder or event if applicable
    private func autoCreateTask(for thought: Thought, classification: Classification) async {
        do {
            if classification.type == .reminder || classification.type == .event {
                // Create Task model
                // Calculate due date from parsed date/time (if available)
                let dueDate = calculateDueDate(from: classification.parsedDateTime)

                // Extract a clean title by removing the matched date/time portion
                let cleanTitle = extractCleanTitle(
                    from: thought.content,
                    parsedDateTime: classification.parsedDateTime
                )

                let task = Task(
                    id: UUID(),
                    userId: thought.userId,
                    sourceThoughtId: thought.id,
                    title: cleanTitle,
                    description: nil,
                    priority: .medium,
                    status: .pending,
                    dueDate: dueDate,
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
                    // Calculate event start/end times from parsed date/time
                    let (startDate, endDate) = calculateEventTimes(from: classification.parsedDateTime)

                    _ = try await taskService.createCalendarEvent(
                        for: created,
                        startDate: startDate,
                        endDate: endDate
                    )
                    try await fineTuningService.trackEventCreated(thought.id)
                }
            }
        } catch {
            // Silently fail - auto-creation is best-effort
            // The thought was saved successfully, so we don't want to show an error
        }
    }

    // MARK: - Date/Time Helpers

    /// Calculate due date from parsed date/time information.
    ///
    /// Combines the parsed date and time of day into a single Date.
    /// Returns nil if no date was parsed.
    private func calculateDueDate(from parsedDateTime: ParsedDateTime?) -> Date? {
        guard let parsedDateTime = parsedDateTime,
              let baseDate = parsedDateTime.date else {
            return nil
        }

        // If we have a specific time of day, apply it
        if let timeOfDay = parsedDateTime.timeOfDay {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            let hours = timeOfDay / 3600
            let minutes = (timeOfDay % 3600) / 60

            var components = dateComponents
            components.hour = hours
            components.minute = minutes
            components.second = 0

            return calendar.date(from: components)
        }

        // If it's an all-day item, use the base date
        return baseDate
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
}
