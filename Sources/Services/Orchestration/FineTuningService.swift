//
//  FineTuningService.swift
//  STASH
//
//  Phase 3A Spec 2: Fine-Tuning Data Service
//  Tracks user interactions for behavioral learning
//

import Foundation

// MARK: - Behavior Profile

/// User behavior profile derived from fine-tuning data.
struct BehaviorProfile: Codable, Sendable {
    /// Total number of thoughts captured
    let totalThoughts: Int

    /// Rate of reminder completion (0.0-1.0)
    let completionRate: Double

    /// Rate of thought archival (0.0-1.0)
    let archivalRate: Double

    /// Average classification confidence
    let avgClassificationConfidence: Double

    /// Most active time of day
    let preferredTimeOfDay: TimeOfDay?

    /// Most common capture location
    let preferredLocation: String?

    /// When this profile was generated
    let generatedAt: Date
}

// MARK: - Fine-Tuning Service Protocol

/// Protocol for fine-tuning services.
///
/// Enables mocking in tests.
protocol FineTuningServiceProtocol: OrchestrationServiceProtocol {
    /// Tracks a new thought creation
    func trackThoughtCreated(_ thought: Thought, classification: Classification) async throws

    /// Tracks reminder creation (positive signal)
    func trackReminderCreated(_ thoughtId: UUID) async throws

    /// Tracks reminder completion (strong positive signal)
    func trackReminderCompleted(_ thoughtId: UUID) async throws

    /// Tracks event creation
    func trackEventCreated(_ thoughtId: UUID) async throws

    /// Tracks event completion
    func trackEventCompleted(_ thoughtId: UUID) async throws

    /// Tracks thought archival (mild negative signal)
    func trackArchived(_ thoughtId: UUID) async throws

    /// Tracks thought deletion (negative signal)
    func trackDeleted(_ thoughtId: UUID) async throws

    /// Tracks thought view
    func trackViewed(_ thoughtId: UUID) async throws

    /// Tracks thought edit
    func trackEdited(_ thoughtId: UUID) async throws

    /// Tracks user feedback on classification
    func trackUserFeedback(thoughtId: UUID, feedbackType: UserFeedback.FeedbackType, correction: String?) async throws

    /// Calculates reward signal for a fine-tuning data point
    func calculateReward(_ data: FineTuningData) -> Double

    /// Generates user behavior profile
    func getUserBehaviorProfile() async throws -> BehaviorProfile
}

// MARK: - Fine-Tuning Service

/// Service for tracking user interactions for behavioral learning.
///
/// Collects implicit feedback signals from user behavior to:
/// 1. Calculate reward signals for model fine-tuning
/// 2. Build user behavior profiles for personalization
/// 3. Identify classification errors
/// 4. Improve future predictions
///
/// ## Reward Signal Calculation
///
/// - Reminder created: +0.5 (user agreed with classification)
/// - Reminder completed: +0.35 (thought was actionable)
/// - Archived: -0.25 (user discarded it)
/// - Deleted: -0.25 (user discarded it)
/// - Incomplete reminder: -0.1 (created but not completed)
actor FineTuningService: FineTuningServiceProtocol {
    // MARK: - Dependencies

    private let repository: FineTuningRepository
    private let syncService: SyncServiceProtocol?
    let configuration: ServiceConfiguration

    // MARK: - Initialization

    init(
        repository: FineTuningRepository = .shared,
        syncService: SyncServiceProtocol? = nil,
        configuration: ServiceConfiguration = .shared
    ) {
        self.repository = repository
        self.syncService = syncService
        self.configuration = configuration
    }

    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Track Thought Created

    /// Tracks a new thought creation with its classification.
    ///
    /// Creates initial fine-tuning data record for the thought.
    func trackThoughtCreated(_ thought: Thought, classification: Classification) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        let data = FineTuningData(
            id: UUID(),
            thoughtId: thought.id,
            classificationId: classification.id,
            createdReminder: false,
            reminderCompleted: nil,
            createdEvent: false,
            eventCompleted: nil,
            archived: false,
            deleted: false,
            timeToFirstAction: nil,
            timeToCompletion: nil,
            views: 0,
            shares: 0,
            edits: 0,
            userFeedback: nil,
            createdAt: Date(),
            lastUpdatedAt: Date()
        )

        do {
            _ = try await repository.create(data)
        } catch {
            throw ServiceError.persistence(operation: "create fine-tuning data", underlying: error)
        }

        // Queue for sync
        if configuration.features.enableSync, let syncService {
            try? await syncService.enqueue(entity: .fineTuningData, entityId: data.id, action: .create, payload: nil)
        }
    }

    // MARK: - Track Reminder Created

    /// Tracks reminder creation (positive signal).
    func trackReminderCreated(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return // No fine-tuning data for this thought
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: true,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: Date().timeIntervalSince(data.createdAt),
            timeToCompletion: data.timeToCompletion,
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)

        if configuration.features.enableSync, let syncService {
            try? await syncService.enqueue(entity: .fineTuningData, entityId: data.id, action: .update, payload: nil)
        }
    }

    // MARK: - Track Reminder Completed

    /// Tracks reminder completion (strong positive signal).
    func trackReminderCompleted(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: true,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: Date().timeIntervalSince(data.createdAt),
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)

        if configuration.features.enableSync, let syncService {
            try? await syncService.enqueue(entity: .fineTuningData, entityId: data.id, action: .update, payload: nil)
        }
    }

    // MARK: - Track Event Created

    /// Tracks calendar event creation.
    func trackEventCreated(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: true,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction ?? Date().timeIntervalSince(data.createdAt),
            timeToCompletion: data.timeToCompletion,
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)
    }

    // MARK: - Track Event Completed

    /// Tracks calendar event completion.
    func trackEventCompleted(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: true,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: Date().timeIntervalSince(data.createdAt),
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)
    }

    // MARK: - Track Archived

    /// Tracks thought archival (mild negative signal).
    func trackArchived(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: true,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: data.timeToCompletion,
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)
    }

    // MARK: - Track Deleted

    /// Tracks thought deletion (negative signal).
    func trackDeleted(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: true,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: data.timeToCompletion,
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)
    }

    // MARK: - Track Viewed

    /// Tracks thought view.
    func trackViewed(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: data.timeToCompletion,
            views: data.views + 1,
            shares: data.shares,
            edits: data.edits,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)
    }

    // MARK: - Track Edited

    /// Tracks thought edit.
    func trackEdited(_ thoughtId: UUID) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: data.timeToCompletion,
            views: data.views,
            shares: data.shares,
            edits: data.edits + 1,
            userFeedback: data.userFeedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)
    }

    /// Returns previously stored feedback for a thought, if any.
    func getFeedback(for thoughtId: UUID) async -> UserFeedback? {
        (try? await repository.fetch(thoughtId: thoughtId))?.userFeedback
    }

    /// Tracks user feedback on classification.
    func trackUserFeedback(thoughtId: UUID, feedbackType: UserFeedback.FeedbackType, correction: String?) async throws {
        guard configuration.features.enableFineTuningTracking else { return }

        guard let data = try await repository.fetch(thoughtId: thoughtId) else {
            return
        }

        let feedback = UserFeedback(
            type: feedbackType,
            comment: correction,
            timestamp: Date()
        )

        let updated = FineTuningData(
            id: data.id,
            thoughtId: data.thoughtId,
            classificationId: data.classificationId,
            createdReminder: data.createdReminder,
            reminderCompleted: data.reminderCompleted,
            createdEvent: data.createdEvent,
            eventCompleted: data.eventCompleted,
            archived: data.archived,
            deleted: data.deleted,
            timeToFirstAction: data.timeToFirstAction,
            timeToCompletion: data.timeToCompletion,
            views: data.views,
            shares: data.shares,
            edits: data.edits,
            userFeedback: feedback,
            createdAt: data.createdAt,
            lastUpdatedAt: Date()
        )

        try await repository.update(updated)

        if configuration.features.enableSync, let syncService {
            try? await syncService.enqueue(entity: .fineTuningData, entityId: data.id, action: .update, payload: nil)
        }
    }

    // MARK: - Reward Calculation

    /// Calculates reward signal for a fine-tuning data point.
    ///
    /// Returns a value between 0.0 and 1.0:
    /// - 0.0: Negative signal (user discarded/ignored)
    /// - 0.5: Neutral
    /// - 1.0: Strong positive signal (user engaged and completed)
    func calculateReward(_ data: FineTuningData) -> Double {
        var reward = 0.5 // Start neutral

        // Positive signals
        if data.createdReminder {
            reward += 0.25 // User agreed with classification
        }

        if data.reminderCompleted == true {
            reward += 0.2 // User completed the task
        }

        if data.createdEvent {
            reward += 0.2 // User created calendar event
        }

        if data.eventCompleted == true {
            reward += 0.15 // Event was completed
        }

        // Negative signals
        if data.archived {
            reward -= 0.15 // User archived without action
        }

        if data.deleted {
            reward -= 0.2 // User deleted it
        }

        // Incomplete reminder is a mild negative
        if data.createdReminder && data.reminderCompleted == false {
            reward -= 0.1
        }

        // Engagement bonus
        if data.views > 3 {
            reward += 0.05 // User engaged with it
        }

        if data.edits > 0 {
            reward += 0.05 // User refined it
        }

        // Clamp to valid range
        return max(0.0, min(1.0, reward))
    }

    // MARK: - Behavior Profile

    /// Generates user behavior profile from fine-tuning data.
    func getUserBehaviorProfile() async throws -> BehaviorProfile {
        let allData = try await repository.list()

        guard !allData.isEmpty else {
            return BehaviorProfile(
                totalThoughts: 0,
                completionRate: 0,
                archivalRate: 0,
                avgClassificationConfidence: 0,
                preferredTimeOfDay: nil,
                preferredLocation: nil,
                generatedAt: Date()
            )
        }

        // Calculate completion rate
        let remindersCreated = allData.filter { $0.createdReminder }
        let remindersCompleted = allData.filter { $0.reminderCompleted == true }
        let completionRate = remindersCreated.isEmpty ? 0.0 :
            Double(remindersCompleted.count) / Double(remindersCreated.count)

        // Calculate archival rate
        let archived = allData.filter { $0.archived || $0.deleted }
        let archivalRate = Double(archived.count) / Double(allData.count)

        // Average confidence (placeholder - would need to join with classifications)
        let avgConfidence = 0.8 // Placeholder

        // Preferred time of day (analyze createdAt timestamps)
        let preferredTime = inferPreferredTimeOfDay(from: allData)

        return BehaviorProfile(
            totalThoughts: allData.count,
            completionRate: completionRate,
            archivalRate: archivalRate,
            avgClassificationConfidence: avgConfidence,
            preferredTimeOfDay: preferredTime,
            preferredLocation: nil, // Would need location data
            generatedAt: Date()
        )
    }

    private func inferPreferredTimeOfDay(from data: [FineTuningData]) -> TimeOfDay? {
        var counts: [TimeOfDay: Int] = [:]

        for item in data {
            let timeOfDay = TimeOfDay.from(date: item.createdAt)
            counts[timeOfDay, default: 0] += 1
        }

        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Mock Fine-Tuning Service

/// Mock fine-tuning service for testing and previews.
actor MockFineTuningService: FineTuningServiceProtocol {
    nonisolated var isAvailable: Bool { true }
    let configuration: ServiceConfiguration

    var trackedThoughts: [UUID] = []
    var trackedReminders: [UUID] = []
    var trackedCompletions: [UUID] = []

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
    }

    func trackThoughtCreated(_ thought: Thought, classification: Classification) async throws {
        trackedThoughts.append(thought.id)
    }

    func trackReminderCreated(_ thoughtId: UUID) async throws {
        trackedReminders.append(thoughtId)
    }

    func trackReminderCompleted(_ thoughtId: UUID) async throws {
        trackedCompletions.append(thoughtId)
    }

    func trackEventCreated(_ thoughtId: UUID) async throws {}
    func trackEventCompleted(_ thoughtId: UUID) async throws {}
    func trackArchived(_ thoughtId: UUID) async throws {}
    func trackDeleted(_ thoughtId: UUID) async throws {}
    func trackViewed(_ thoughtId: UUID) async throws {}
    func trackEdited(_ thoughtId: UUID) async throws {}
    func trackUserFeedback(thoughtId: UUID, feedbackType: UserFeedback.FeedbackType, correction: String?) async throws {}

    func calculateReward(_ data: FineTuningData) -> Double {
        0.75
    }

    func getUserBehaviorProfile() async throws -> BehaviorProfile {
        BehaviorProfile(
            totalThoughts: trackedThoughts.count,
            completionRate: 0.8,
            archivalRate: 0.1,
            avgClassificationConfidence: 0.85,
            preferredTimeOfDay: .afternoon,
            preferredLocation: nil,
            generatedAt: Date()
        )
    }
}
