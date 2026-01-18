//
//  FineTuningData.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Behavioral learning and fine-tuning data
//

import Foundation

/// Data collected for fine-tuning and behavioral learning.
///
/// Tracks user interactions with thoughts and classifications to:
/// 1. Calculate "reward signal" for model fine-tuning
/// 2. Identify classification errors and improve accuracy
/// 3. Build user behavior model for personalization
/// 4. Improve future suggestions and predictions
/// 5. Train backend models during synchronization
///
/// ## Data Collection Strategy
///
/// - **Automatic**: User actions (creation, completion, archival)
/// - **Semi-automatic**: Time tracking (when reminder completed)
/// - **Manual**: Explicit user feedback ("This was helpful")
///
/// ## Fine-Tuning Use Case Example
///
/// ```
/// Model predicts: "This is a Reminder with 0.95 confidence"
///
/// User creates reminder → ✓ Positive signal (model was correct)
/// User completes reminder → ✓ Strong positive signal (thought was actionable)
/// User marks "helpful" → ✓ Explicit positive feedback
///
/// Alternatively:
/// User created but didn't complete → Neutral signal
/// User marked "not helpful" → Negative signal (retrain needed)
/// ```
///
/// ## Relationships
///
/// - **Thought**: Many-to-one (multiple data points per thought over time)
/// - **Classification**: Many-to-one (multiple data points per classification)
struct FineTuningData: Identifiable, Codable, Equatable, Sendable {
    /// Unique identifier
    let id: UUID

    /// Reference to the thought being tracked
    let thoughtId: UUID

    /// Reference to the classification being evaluated
    let classificationId: UUID

    // MARK: - User Actions (Ground Truth)

    /// Whether user created a reminder from this thought
    let createdReminder: Bool

    /// Whether the reminder was completed (nil if no reminder created)
    let reminderCompleted: Bool?

    /// Whether user created a calendar event from this thought
    let createdEvent: Bool

    /// Whether the event was completed (nil if no event created)
    let eventCompleted: Bool?

    /// Whether user archived this thought
    let archived: Bool

    /// Whether user deleted this thought
    let deleted: Bool

    // MARK: - Time Metrics

    /// Time taken to first action (seconds)
    ///
    /// Measures how quickly user acted on the thought.
    /// Low values indicate high relevance/urgency.
    /// Nil if no action taken.
    let timeToFirstAction: TimeInterval?

    /// Time from creation to completion (seconds)
    ///
    /// Measures full lifecycle of thought → task → done.
    /// Nil if not completed.
    let timeToCompletion: TimeInterval?

    // MARK: - Engagement Metrics

    /// Number of times thought was viewed
    let views: Int

    /// Number of times thought was shared
    let shares: Int

    /// Number of times thought was edited
    let edits: Int

    // MARK: - Explicit Feedback

    /// Optional user feedback on the classification quality
    let userFeedback: UserFeedback?

    // MARK: - Timestamps

    /// When this fine-tuning data record was created
    let createdAt: Date

    /// When this record was last updated
    let lastUpdatedAt: Date
}

/// Explicit feedback from the user about a classification.
///
/// Allows users to rate whether the AI's classification was accurate
/// and provide optional commentary.
struct UserFeedback: Codable, Equatable, Sendable {
    /// Type of feedback provided
    enum FeedbackType: String, Codable, Sendable {
        /// Classification was accurate and helpful
        case helpful

        /// Classification was partially correct
        case partially_helpful

        /// Classification was incorrect or unhelpful
        case not_helpful
    }

    /// Rating of the classification
    let type: FeedbackType

    /// Optional text comment explaining the rating
    let comment: String?

    /// When the feedback was provided
    let timestamp: Date
}
