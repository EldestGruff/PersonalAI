//
//  ClassificationService_FoundationModels.swift
//  PersonalAI
//
//  Phase 4: Intelligence & Automation
//  AI-powered thought classification using Apple's Foundation Models (iOS 26)
//

import Foundation
import FoundationModels

// MARK: - Structured Output Model

/// Structured output from Foundation Models for thought classification.
///
/// The @Generable macro tells Apple's on-device LLM to return structured data
/// instead of raw text, providing intelligent classification beyond keyword matching.
@Generable
struct ExtractedClassification: Codable, Equatable {
    /// The type of thought content
    /// - "reminder": User needs to remember to do something specific
    /// - "event": User is scheduling or describing a time-based occurrence
    /// - "note": User is recording information for later reference
    /// - "question": User is asking something or wondering
    /// - "idea": User is brainstorming or conceptualizing
    @Guide(description: """
        Classify the content type based on intent, not keywords:
        - "reminder": Actionable task the user needs to complete (e.g., "buy milk", "call mom")
        - "event": Time-bound occurrence or appointment (e.g., "meeting at 3pm", "dinner tomorrow")
        - "note": General information or observation (e.g., "password is abc123", "interesting article")
        - "question": Inquiry or wondering (e.g., "what's the weather?", "how does this work?")
        - "idea": Creative concept or brainstorm (e.g., "what if we tried...", "could build a...")

        DEFAULT TO "note" if unsure. Only classify as reminder/event if the intent is clearly actionable or time-bound.
        """)
    let type: String

    /// Sentiment of the content
    /// - "positive": Optimistic, happy, encouraging
    /// - "negative": Pessimistic, sad, discouraging
    /// - "neutral": Matter-of-fact, neither positive nor negative
    @Guide(description: """
        Analyze the emotional tone:
        - "positive": Happy, excited, optimistic content
        - "negative": Sad, angry, frustrated content
        - "neutral": Factual or emotionally balanced content

        Be balanced - don't over-detect negativity. Default to neutral if unsure.
        """)
    let sentiment: String

    /// Suggested tags (max 5, lowercase, relevant keywords)
    @Guide(description: "Extract 1-5 relevant keywords as tags. Use lowercase, remove articles (the, a, an). Focus on nouns and key concepts.")
    let tags: [String]

    /// Confidence score from 0.0 to 1.0
    @Guide(description: "How confident are you in this classification? 1.0 = very confident, 0.5 = uncertain, 0.0 = cannot classify")
    let confidence: Double
}

// MARK: - Foundation Models Classifier

/// Modern thought classifier using Apple's Foundation Models (iOS 26).
///
/// Replaces keyword-based classification with on-device AI that understands intent.
/// Supports nuanced classification that goes beyond hardcoded patterns.
///
/// ## Advantages over Keyword Patterns
/// - Understands intent, not just keywords
/// - Handles context and nuance
/// - No false positives from common words
/// - Apple's AI improves over time via OS updates
actor FoundationModelsClassifier {
    private var session: LanguageModelSession?
    private var isProcessing = false

    init() {
        // Session will be created lazily on first use
    }

    /// Classify thought content using Foundation Models.
    func classify(_ text: String) async throws -> (type: ClassificationType, sentiment: Sentiment, tags: [String], confidence: Double) {
        // CRITICAL: Prevent concurrent requests - Foundation Models can only handle one at a time
        guard !isProcessing else {
            throw ServiceError.frameworkUnavailable(
                framework: .foundationModels,
                reason: "Foundation Models is already processing a request"
            )
        }

        isProcessing = true
        defer { isProcessing = false }

        // Recreate session on each call to avoid context accumulation
        session = createSession()

        guard let session = session else {
            throw ServiceError.frameworkUnavailable(
                framework: .foundationModels,
                reason: "Could not create LanguageModelSession"
            )
        }

        // Create prompt for the AI
        let prompt = createPrompt(text: text)

        do {
            // Get structured output from Foundation Models
            let response = try await session.respond(
                to: prompt,
                generating: ExtractedClassification.self
            )

            // Convert to internal format
            return convertToInternal(extracted: response.content)
        } catch {
            // Reset session on error to clear accumulated context
            self.session = nil
            throw error
        }
    }

    private func createSession() -> LanguageModelSession {
        LanguageModelSession {
            """
            You are an intelligent thought classification assistant. Your job is to:
            1. Understand the USER'S INTENT, not just match keywords
            2. Classify content conservatively - default to "note" when unsure
            3. Only classify as "reminder" if there's a clear actionable task
            4. Only classify as "event" if there's a time-bound occurrence
            5. Be balanced with sentiment - don't over-detect negativity
            6. Extract meaningful tags that help organize content

            CRITICAL RULES:
            - "I'll need to..." is often just a note, not a reminder (unless explicitly actionable)
            - "should" or "need to" in context of thinking/planning is a note, not a reminder
            - Only use "event" if time is explicitly mentioned or strongly implied
            - Default to "neutral" sentiment unless tone is clearly positive or negative
            - If uncertain, choose "note" and lower confidence score

            Examples:
            - "I'll need to get the snowblower out sometime" → note (vague, no specific action)
            - "Remind me to call mom tomorrow" → reminder (explicit reminder request)
            - "Meeting at 3pm tomorrow" → event (specific time mentioned)
            - "What's the best way to learn Swift?" → question (inquiry)
            - "What if we built an AI that could..." → idea (creative concept)
            - "Password is abc123" → note (information storage)
            """
        }
    }

    private func createPrompt(text: String) -> String {
        """
        Classify this thought: "\(text)"

        Determine:
        - type: reminder/event/note/question/idea (default to "note" if unsure)
        - sentiment: positive/negative/neutral (be balanced, don't over-detect negative)
        - tags: 1-5 relevant keywords (lowercase, no articles)
        - confidence: 0.0-1.0 (how sure are you?)

        Remember: Only use "reminder" if there's a clear actionable task. Only use "event" if time-bound.
        When in doubt, classify as "note" with lower confidence.
        """
    }

    private func convertToInternal(extracted: ExtractedClassification) -> (type: ClassificationType, sentiment: Sentiment, tags: [String], confidence: Double) {
        // Convert string type to enum
        let type: ClassificationType
        switch extracted.type.lowercased() {
        case "reminder":
            type = .reminder
        case "event":
            type = .event
        case "question":
            type = .question
        case "idea":
            type = .idea
        default:
            type = .note  // Default to note for anything else
        }

        // Convert string sentiment to enum
        let sentiment: Sentiment
        switch extracted.sentiment.lowercased() {
        case "positive":
            sentiment = .positive
        case "negative":
            sentiment = .negative
        default:
            sentiment = .neutral  // Default to neutral
        }

        // Clean up tags
        let cleanTags = extracted.tags
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count <= 50 }
            .prefix(5)
            .map { String($0) }

        return (
            type: type,
            sentiment: sentiment,
            tags: Array(cleanTags),
            confidence: extracted.confidence
        )
    }
}

// Note: ClassificationType and SentimentScore are defined in Classification.swift
