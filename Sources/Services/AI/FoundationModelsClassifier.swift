//
//  FoundationModelsClassifier.swift
//  PersonalAI
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

    /// Availability status of Apple Intelligence
    nonisolated var isAvailable: Bool {
        SystemLanguageModel.availability == .available
    }

    // MARK: - Initialization

    init() {
        setupSession()
    }

    // MARK: - Session Setup

    private func setupSession() {
        guard SystemLanguageModel.availability == .available else {
            print("⚠️ Apple Intelligence not available")
            return
        }

        session = LanguageModelSession(
            instructions: """
            You are an expert at analyzing personal thoughts and categorizing them accurately.

            Thought Types:
            - note: Reference information, observations, facts, things to remember
            - idea: Creative thoughts, possibilities, innovations, brainstorming
            - task: Action items, to-dos, things to accomplish, responsibilities
            - event: Time-based activities, meetings, appointments, scheduled items
            - question: Things to research, answer, or investigate

            Sentiment Analysis (IMPORTANT):
            Range: -1.0 (very negative) to +1.0 (very positive)

            Key Principles:
            - DEFAULT TO NEUTRAL (0.0) unless there's clear emotional content
            - Sarcasm, irony, and dry humor are typically NEUTRAL, not negative
            - Casual/informal language ≠ negative sentiment
            - Only mark as negative if expressing genuine frustration, sadness, or distress
            - Only mark as positive if expressing genuine joy, excitement, or gratitude
            - Factual statements, observations, and plans are usually neutral

            Examples:
            - "Great, another meeting" → 0.0 (sarcasm, but not genuinely negative)
            - "Need to finish the report" → 0.0 (neutral task)
            - "This project is a disaster" → -0.5 to -0.7 (genuinely negative)
            - "Excited about the new feature!" → 0.6 to 0.8 (genuinely positive)
            - "The weather is nice today" → 0.0 to 0.2 (neutral observation)

            Guidelines:
            1. Classify based on primary intent (a task might mention an event, but classify by main purpose)
            2. Provide 3-5 relevant, specific tags that capture key themes
            3. Be conservative with sentiment - when in doubt, lean toward neutral
            4. Be accurate with confidence scores (0.0 to 1.0)
            5. Consider context when provided (location, energy, focus state)

            Be concise, accurate, and helpful.
            """
        )
    }

    // MARK: - Classification

    /// Classify a thought with AI-powered analysis
    /// - Parameter content: The thought content to classify
    /// - Returns: Classification result with type, tags, sentiment, and confidence
    func classify(_ content: String) async throws -> FoundationModelsResult {
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
            NSLog("❌ Foundation Models classification failed: \(error)")
            throw ClassificationError.processingFailed(underlying: error)
        }
    }

    // MARK: - Performance Optimization

    /// Pre-warm the model for faster first classification
    /// Call this when user is likely to capture a thought (e.g., capture screen opens)
    func prewarm() {
        guard !isPrewarmed, let session else { return }

        Task {
            session.prewarm()
            isPrewarmed = true
            print("✅ Foundation Models pre-warmed")
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
        switch value {
        case 0.6...:
            return .very_positive
        case 0.25..<0.6:
            return .positive
        case -0.25...0.25:
            return .neutral  // Wide neutral band
        case -0.6 ..< -0.25:
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

    @Guide(description: "3-5 contextual tags (single-word or hyphenated only, no spaces). Examples: work, deadline, meeting, project-alpha, follow-up", .count(3...5))
    var suggestedTags: [String]

    @Guide(description: "Emotional sentiment score. IMPORTANT: Use 0.0 for neutral/factual content. Only use negative scores for genuine distress/frustration. Only use positive scores for genuine joy/excitement. Range: -1.0 (very negative) to +1.0 (very positive). Most thoughts should be between -0.2 and +0.2 (neutral).")
    var sentiment: Double
}
