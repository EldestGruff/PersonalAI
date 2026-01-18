//
//  Thought.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Core domain model for user thoughts
//

import Foundation

/// A thought captured by the user.
///
/// Thoughts are the atomic unit of the Personal AI Assistant. They capture
/// a single idea, observation, or piece of information at a specific moment.
/// Each thought is enriched with context (time, location, energy level) and
/// can be classified by type (reminder, event, note, question, idea).
///
/// Thoughts are immutable value types (struct). Modifications create new instances
/// rather than mutating existing ones. This enables undo/redo, version history,
/// and simplifies concurrent access.
///
/// ## Storage
///
/// Thoughts are persisted locally in Core Data (via ThoughtEntity) and synchronized
/// to the backend when network is available. The Swift struct serves as the domain
/// model, while ThoughtEntity handles persistence.
///
/// ## Relationships
///
/// - **Classification**: One-to-one relationship with Classification (optional)
/// - **Related Thoughts**: Many-to-many self-referencing relationship (bidirectional)
/// - **Task**: One-to-zero-or-one relationship (thought may spawn a task)
/// - **Fine-Tuning Data**: One-to-many relationship for behavioral learning
///
/// ## Example
///
/// ```swift
/// let thought = Thought(
///     id: UUID(),
///     userId: UUID(),
///     content: "Should optimize email spam filter",
///     tags: ["email", "improvement"],
///     status: .active,
///     context: Context(
///         timestamp: Date(),
///         location: nil,
///         timeOfDay: .afternoon,
///         energy: .high,
///         focusState: .deep_work,
///         calendar: nil,
///         activity: nil,
///         weather: nil
///     ),
///     createdAt: Date(),
///     updatedAt: Date(),
///     classification: nil,
///     relatedThoughtIds: [],
///     taskId: nil
/// )
/// ```
struct Thought: Identifiable, Codable, Equatable, Sendable {
    /// Unique identifier (UUID v4)
    let id: UUID

    /// User who owns this thought
    ///
    /// In Phase 3A, there is only one user, but this supports multi-user in future phases
    let userId: UUID

    /// The thought content (1-5000 characters)
    ///
    /// Main text captured by the user. Can be a sentence, paragraph, or longer note.
    /// Validated to be non-empty after trimming whitespace.
    let content: String

    /// User-assigned or AI-suggested tags (0-5 tags, max 50 chars each)
    ///
    /// Tags are lowercase alphanumeric strings with hyphens allowed.
    /// Used for filtering, searching, and organizing thoughts.
    ///
    /// Examples: ["work", "personal", "health", "project-alpha"]
    let tags: [String]

    /// Current status in the thought lifecycle
    let status: ThoughtStatus

    /// Situational context when thought was captured
    ///
    /// Includes time, location, energy level, calendar state, and other factors.
    /// Stored as JSON in Core Data for flexibility.
    let context: Context

    /// When this thought was created (immutable)
    let createdAt: Date

    /// When this thought was last modified
    ///
    /// Updated whenever content, tags, or status changes.
    /// Must be >= createdAt.
    let updatedAt: Date

    /// ML classification results (optional)
    ///
    /// Contains Foundation Model inference: type, confidence, entities, sentiment.
    /// One-to-one relationship. Not all thoughts are classified immediately.
    let classification: Classification?

    /// IDs of related thoughts (many-to-many)
    ///
    /// Links to similar or connected thoughts. Stored as array of UUIDs in
    /// the domain model, but represented as Core Data relationship in persistence.
    ///
    /// - Note: Relationship is bidirectional in Core Data. If A relates to B,
    ///         then B automatically relates to A.
    let relatedThoughtIds: [UUID]

    /// ID of task created from this thought (optional)
    ///
    /// If user converts thought to a task, this links to the TaskEntity.
    /// One-to-zero-or-one relationship.
    let taskId: UUID?
}

// MARK: - Validation

extension Thought {
    /// Validates the thought against all business rules.
    ///
    /// Checks:
    /// - Content is non-empty and within length limits
    /// - Tags are valid (count, length, characters)
    /// - Timestamps are consistent
    /// - Classification (if present) is valid
    ///
    /// - Throws: `ValidationError` if any field is invalid
    nonisolated func validate() throws {
        // Content validation
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw ValidationError.emptyContent
        }
        guard content.count <= 5000 else {
            throw ValidationError.contentTooLong(content.count)
        }

        // Tags validation
        guard tags.count <= 5 else {
            throw ValidationError.tooManyTags(tags.count)
        }

        let validCharacters = CharacterSet.lowercaseLetters
            .union(CharacterSet.decimalDigits)
            .union(CharacterSet(charactersIn: "-"))

        for tag in tags {
            guard tag.count <= 50 else {
                throw ValidationError.tagTooLong(tag, tag.count)
            }
            guard tag.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) else {
                throw ValidationError.invalidTagCharacters(tag)
            }
        }

        // Timestamp validation
        guard createdAt <= updatedAt else {
            throw ValidationError.invalidTimestamp
        }

        // Classification validation (if present)
        if let classification = classification {
            try classification.validate()
        }
    }
}
