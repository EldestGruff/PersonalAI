//
//  ClassificationPatterns.swift
//  STASH
//
//  Keyword patterns used for NLP-based thought classification.
//  Single source of truth — edit patterns here, not inline in ClassificationService.
//

import Foundation

enum ClassificationPatterns {

    // MARK: - Reminder Patterns

    enum Reminder {
        /// Unambiguous phrases that signal reminder intent.
        /// These take highest priority and bypass the bias correction store.
        static let highSignal: [String] = [
            "remind me",
            "don't forget",
            "remember to"
        ]

        /// Action-oriented phrases that suggest a reminder.
        static let general: [String] = [
            "need to",
            "have to",
            "should",
            "must",
            "todo",
            "to-do",
            "to do",
            "pick up",
            "buy",
            "call",
            "email",
            "text",
            "send",
            "follow up"
        ]
    }

    // MARK: - Event Patterns

    enum Event {
        /// Unambiguous phrases that signal a calendar event.
        /// These take highest priority and bypass the bias correction store.
        static let highSignal: [String] = [
            "meeting",
            "appointment"
        ]

        /// Temporal phrases that suggest a scheduled event.
        static let general: [String] = [
            "schedule",
            "calendar",
            "at ",
            "on monday",
            "on tuesday",
            "on wednesday",
            "on thursday",
            "on friday",
            "on saturday",
            "on sunday",
            "next week",
            "tomorrow",
            "tonight",
            "this evening",
            "this afternoon",
            "o'clock"
        ]
    }

    // MARK: - Idea Patterns

    enum Idea {
        /// Unambiguous phrases that signal an idea.
        /// These take highest priority and bypass the bias correction store.
        static let highSignal: [String] = [
            "what if",
            "idea:"
        ]

        /// Creative or speculative phrases that suggest an idea.
        static let general: [String] = [
            "i think",
            "maybe we could",
            "we should consider",
            "it would be cool",
            "imagine",
            "concept:",
            "brainstorm",
            "could we",
            "how about"
        ]
    }

    // MARK: - Sentiment Markers

    enum Sentiment {
        /// Emotional language indicating genuine distress.
        /// Used to prevent spurious negative sentiment on logistical thought types
        /// such as reminders and events. (#65)
        static let negativeMarkers: [String] = [
            "stressed", "anxious", "worried", "scared",
            "hate", "dread", "dreading", "overwhelmed",
            "terrible", "awful"
        ]
    }

    // MARK: - Question Starters

    /// Words that, when appearing as the first word of a thought, suggest a question.
    static let questionStarters: [String] = [
        "what", "who", "where", "when", "why", "how",
        "is", "are", "can", "could", "would", "should",
        "do", "does"
    ]
}
