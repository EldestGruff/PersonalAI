//
//  FoundationModelsClassifier.swift
//  STASH
//
//  Foundation Models integration for on-device AI classification
//  iOS 26+ with Apple Intelligence
//

import Foundation
import FoundationModels

/// Result from Foundation Models classification
struct FoundationModelsResult {
    let type: ClassificationType
    let confidence: Double
    let tags: [String]
    let sentiment: Sentiment
}

/// Classifier using Foundation Models framework (iOS 26+)
actor FoundationModelsClassifier {

    // MARK: - Properties

    private var session: LanguageModelSession?
    private var isPrewarmed = false
    // `nonisolated(unsafe)` is intentional here. The flag is written inside
    // `setupSession()`, which runs on the actor's executor, so any two calls from
    // the *same* instance are serialized by the actor. A theoretical race exists
    // only if two *different* `FoundationModelsClassifier` instances call
    // `setupSession()` simultaneously. In practice this cannot happen:
    // `ClassificationService` (the sole owner) lazily creates exactly one instance
    // via `if foundationModelsClassifier == nil` inside its own actor-isolated
    // method, and `ClassificationService` is constructed once inside
    // `ContextEnrichmentService.shared`. The worst-case outcome of a race would
    // be a duplicate analytics event, not a crash or data corruption.
    // If multi-instance usage is ever introduced, replace this with
    // `OSAllocatedUnfairLock` or promote the flag to an actor-isolated property.
    private nonisolated(unsafe) static var hasTrackedUnavailable = false

    /// Availability status of Apple Intelligence
    nonisolated var isAvailable: Bool {
        SystemLanguageModel().availability == .available
    }

    // MARK: - Initialization

    init() {
        // Session will be created lazily on first classification
    }

    // MARK: - Session Setup

    private func setupSession() {
        guard SystemLanguageModel().availability == .available else {
            AppLogger.warning("Apple Intelligence not available", category: .classification)
            if !FoundationModelsClassifier.hasTrackedUnavailable {
                AnalyticsService.shared.track(.aiUnavailable)
                FoundationModelsClassifier.hasTrackedUnavailable = true
            }
            return
        }

        session = LanguageModelSession(
            instructions: """
            You are an expert at understanding the intent behind personal thoughts and capturing them accurately.

            ## Thought Types

            **task** — The user wants to DO something or be REMINDED to do something.
            The user is the agent. Time references are incidental.
            Examples:
            - "remind me to call mom" → task
            - "set a reminder for 9am tomorrow" → task (explicit reminder request, time is just when)
            - "I'd like to set a reminder and see what tomorrow looks like at 9" → task
            - "need to pick up groceries" → task
            - "don't forget to pay rent" → task

            **event** — Something is HAPPENING, typically involving others or a location.
            The user is a participant, not the initiator of a personal action.
            Examples:
            - "meeting with Sarah at 3pm" → event
            - "dentist appointment Thursday" → event
            - "team standup tomorrow morning" → event

            **Key distinction:** If the user says "reminder", "remind me", "don't forget", or "set a reminder" — it is always a task, even if a time is mentioned. Time references on tasks indicate *when* the reminder should fire, not that it's a calendar event.

            **note** — Observations, facts, reference information, things to remember passively.
            **idea** — Creative possibilities, brainstorms, "what if" thinking.
            **question** — Genuine inquiry or wondering.

            Default to "note" if the intent is unclear.

            ## Sentiment

            Range: -1.0 (very negative) to +1.0 (very positive). Most thoughts are neutral.

            NEUTRAL (±0.2): Tasks, reminders, plans, factual observations, sarcasm, dry humor.
            NEGATIVE (-0.3 to -1.0): Only genuine emotional distress — "overwhelmed", "frustrated", "anxious", "terrible day".
            POSITIVE (+0.3 to +1.0): Only genuine joy — "excited", "proud", "love this", "amazing".

            Transactional words ("pay", "rent", "dentist") are NOT negative — they are neutral logistics.

            ## Guidelines

            1. Intent over keywords — classify what the user MEANS, not what words appear
            2. If in doubt between task and event: ask "is the user initiating an action?" → task; "is something happening to/around them?" → event
            3. Be conservative with sentiment — default to neutral
            4. Provide 3-5 specific, relevant tags (lowercase, hyphenated)
            """
        )
    }

    // MARK: - Classification

    /// Classify a thought with AI-powered analysis
    /// - Parameter content: The thought content to classify
    /// - Returns: Classification result with type, tags, sentiment, and confidence
    func classify(_ content: String) async throws -> FoundationModelsResult {
        if session == nil {
            setupSession()
        }
        guard let session else {
            throw ClassificationError.notAvailable
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClassificationError.emptyContent
        }

        let prompt = "Classify this thought:\n\n\"\(content)\""

        do {
            // Get structured classification using @Generable
            let response = try await session.respond(
                to: prompt,
                generating: ThoughtClassificationResponse.self
            )

            let rawType = response.content.type
            let type = mapThoughtType(rawType)
            let sentiment = mapSentiment(response.content.sentiment)

            // Clean tags: replace spaces with hyphens, lowercase
            let cleanTags = response.content.suggestedTags.map { tag in
                tag.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .trimmingCharacters(in: .whitespaces)
            }

            return FoundationModelsResult(
                type: type,
                confidence: response.content.confidence,
                tags: cleanTags,
                sentiment: sentiment
            )

        } catch {
            AppLogger.error("Foundation Models classification failed", category: .classification)
            throw ClassificationError.processingFailed(underlying: error)
        }
    }

    // MARK: - Performance Optimization

    /// Pre-warm the model for faster first classification
    /// Call this when user is likely to capture a thought (e.g., capture screen opens)
    func prewarm() {
        guard !isPrewarmed, let session else { return }

        _Concurrency.Task {
            session.prewarm()
            isPrewarmed = true
            AppLogger.debug("Foundation Models pre-warmed", category: .classification)
        }
    }

    /// Reset pre-warm state (e.g., after app goes to background)
    func resetPrewarm() {
        isPrewarmed = false
    }

    // MARK: - Helper Methods

    private func mapThoughtType(_ rawType: String) -> ClassificationType {
        switch rawType.lowercased() {
        case "task": return .reminder
        case "event": return .event
        case "question": return .question
        case "idea": return .idea
        default: return .note
        }
    }

    private func mapSentiment(_ value: Double) -> Sentiment {
        // Use a wider neutral band to avoid over-classifying as negative/positive
        // Most casual thoughts should be neutral
        //
        // Tuned thresholds (Issue #8):
        // - Very positive: 0.7+ (strong joy/excitement)
        // - Positive: 0.3-0.7 (mild positive)
        // - Neutral: -0.3 to 0.3 (wide band for most thoughts)
        // - Negative: -0.7 to -0.3 (mild negative)
        // - Very negative: < -0.7 (strong distress)
        switch value {
        case 0.7...:
            return .very_positive
        case 0.3..<0.7:
            return .positive
        case -0.3...0.3:
            return .neutral  // Wide neutral band - most thoughts here
        case -0.7 ..< -0.3:
            return .negative
        default:
            return .very_negative
        }
    }
}

// MARK: - Classification Error

enum ClassificationError: LocalizedError {
    case notAvailable
    case emptyContent
    case processingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Intelligence is not available on this device"
        case .emptyContent:
            return "Cannot classify empty content"
        case .processingFailed(let error):
            return "Classification failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Data Models

/// Structured classification response from Foundation Models
@Generable
struct ThoughtClassificationResponse: Codable {
    @Guide(description: "Type of thought: note, idea, task, event, or question")
    var type: String

    @Guide(description: "Confidence score from 0.0 to 1.0")
    var confidence: Double

    @Guide(description: "3-5 contextual tags (single-word or hyphenated only, no spaces). Be specific and relevant. Examples: work, deadline, meeting, project-alpha, follow-up, swiftui, ios-development, health-tracking. Avoid generic tags like 'task' or 'todo'.", .count(3...5))
    var suggestedTags: [String]

    @Guide(description: "Emotional sentiment score. IMPORTANT: Use 0.0 for neutral/factual content. Only use negative scores for genuine distress/frustration. Only use positive scores for genuine joy/excitement. Range: -1.0 (very negative) to +1.0 (very positive). Most thoughts should be between -0.2 and +0.2 (neutral).")
    var sentiment: Double
}
