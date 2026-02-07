//
//  Classification.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  ML classification results for thoughts
//

import Foundation

/// Machine learning classification results for a thought.
///
/// Contains the output of on-device Foundation Models inference, including:
/// - Thought type (reminder, event, note, etc.)
/// - Confidence score
/// - Extracted entities
/// - Sentiment analysis
/// - Performance metrics
///
/// Classifications are stored for audit trail and fine-tuning purposes.
/// They represent the model's initial interpretation of a thought and can
/// be compared against user actions to improve future predictions.
///
/// - Important: Classification has a one-to-one relationship with Thought.
///             Each thought can have zero or one classification.
struct Classification: Identifiable, Codable, Equatable, Sendable {
    /// Unique identifier
    let id: UUID

    /// What kind of thought this is (reminder, event, note, etc.)
    let type: ClassificationType

    /// Model's confidence in this classification (0.0 to 1.0)
    ///
    /// - 0.0-0.5: Low confidence, may need user confirmation
    /// - 0.5-0.8: Medium confidence, reasonable prediction
    /// - 0.8-0.95: High confidence, likely correct
    /// - 0.95-1.0: Very high confidence, almost certain
    let confidence: Double

    /// Entities extracted from thought content
    ///
    /// Examples: ["email", "john", "tuesday", "project_alpha"]
    let entities: [String]

    /// Tags suggested by the classification model
    ///
    /// Max 5 tags, following same validation rules as thought tags
    let suggestedTags: [String]

    /// Emotional tone of the thought
    let sentiment: Sentiment

    /// Detected language code (ISO 639-1, e.g., "en", "es", "fr")
    let language: String?

    /// Time taken to generate this classification (milliseconds)
    ///
    /// Used for performance monitoring and optimization
    let processingTime: TimeInterval

    /// Name/version of the Foundation Model that generated this classification
    ///
    /// Example: "foundation-model-v1", "foundation-model-v2-turbo"
    let model: String

    /// When this classification was created
    let createdAt: Date

    /// Parsed date/time from the thought content (Phase 4)
    ///
    /// Extracted using natural language parsing for reminders and events.
    /// Nil if no date/time could be parsed from the content.
    let parsedDateTime: ParsedDateTime?
}

// MARK: - Parsed Date/Time

/// Parsed date and time information from thought content.
///
/// Used to pre-populate date/time fields when creating reminders and events.
struct ParsedDateTime: Codable, Equatable, Sendable {
    /// The parsed date (nil if no date found)
    let date: Date?

    /// The parsed time as seconds since midnight (0-86399)
    /// Nil if no specific time was mentioned
    let timeOfDay: Int?

    /// Whether this is an all-day event (no specific time)
    let isAllDay: Bool

    /// The original text that was matched
    let matchedText: String?

    /// Confidence in the parse (0.0 to 1.0)
    let confidence: Double
}

/// Type of thought classified by the model.
///
/// These categories drive different UI behaviors and suggested actions:
/// - `reminder`: Creates a task without a specific time
/// - `event`: Creates a calendar event with a specific date/time
/// - `note`: Informational, no action needed
/// - `question`: Needs research or answer
/// - `idea`: Creative or brainstorming content
enum ClassificationType: String, Codable, CaseIterable, Sendable {
    case reminder
    case event
    case note
    case question
    case idea
}

/// Emotional sentiment of a thought.
///
/// Derived from tone, word choice, and context.
/// Used for mood tracking and prioritization.
enum Sentiment: String, Codable, CaseIterable, Sendable {
    case very_negative
    case negative
    case neutral
    case positive
    case very_positive
}

// MARK: - Validation

extension Classification {
    /// Validates the classification against all business rules.
    ///
    /// - Throws: `ValidationError` if any field is invalid
    nonisolated func validate() throws {
        guard confidence >= 0.0 && confidence <= 1.0 else {
            throw ValidationError.invalidConfidence(confidence)
        }

        guard processingTime > 0 else {
            throw ValidationError.invalidProcessingTime(processingTime)
        }

        guard suggestedTags.count <= 5 else {
            throw ValidationError.tooManyTags(suggestedTags.count)
        }

        // Validate suggested tags follow same rules as thought tags
        for tag in suggestedTags {
            guard tag.count <= 50 else {
                throw ValidationError.tagTooLong(tag, tag.count)
            }

            let validCharacters = CharacterSet.lowercaseLetters
                .union(CharacterSet.decimalDigits)
                .union(CharacterSet(charactersIn: "-"))
            guard tag.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) else {
                throw ValidationError.invalidTagCharacters(tag)
            }
        }

        // Validate parsed date/time if present
        if let parsedDateTime = parsedDateTime {
            guard parsedDateTime.confidence >= 0.0 && parsedDateTime.confidence <= 1.0 else {
                throw ValidationError.invalidConfidence(parsedDateTime.confidence)
            }

            if let timeOfDay = parsedDateTime.timeOfDay {
                guard timeOfDay >= 0 && timeOfDay < 86400 else {
                    throw ValidationError.invalidTimeOfDay(timeOfDay)
                }
            }
        }
    }
}
