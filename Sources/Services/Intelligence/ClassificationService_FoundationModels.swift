//
//  ClassificationService_FoundationModels.swift
//  STASH
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

// NOTE: FoundationModelsClassifier actor is now in Sources/Services/AI/FoundationModelsClassifier.swift
// This file only contains the ExtractedClassification struct for structured output

// Note: ClassificationType and SentimentScore are defined in Classification.swift
