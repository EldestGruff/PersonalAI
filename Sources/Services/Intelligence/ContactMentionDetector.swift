//
//  ContactMentionDetector.swift
//  STASH
//
//  Issue #67: Contacts enrichment
//  Detects contact name mentions in thought text.
//

import Foundation

/// Detects contact name mentions in thought text.
///
/// Matching strategy:
/// - Full names (≥2 tokens): case-insensitive substring match — always accepted.
/// - First names (1 token): accepted only when a social context word appears
///   within ±3 words of the name in the tokenised text.
///
/// Returns deduplicated results. When both a full name ("Sarah Johnson") and
/// a first-name-only entry ("Sarah") match the same text, the full name wins.
///
/// Purely synchronous — no external dependencies, fully testable without mocks.
enum ContactMentionDetector {

    /// Social context words that make a lone first-name mention credible.
    private static let socialContextWords: Set<String> = [
        "with", "call", "email", "meet", "meeting", "lunch", "from",
        "ask", "tell", "text", "message", "contact", "remind", "talk",
        "spoke", "ping", "dm", "see", "invite", "for", "and", "or",
        "called", "emailed", "texted", "met"
    ]

    /// Detects which known contact names appear in the given text.
    static func detect(in text: String, knownNames: [String]) -> [String] {
        guard !text.isEmpty, !knownNames.isEmpty else { return [] }

        let lowercasedText = text.lowercased()
        let words = tokens(from: lowercasedText)

        var matched: [String: String] = [:]

        for name in knownNames {
            let nameLower = name.lowercased()
            let nameTokens = tokens(from: nameLower)
            guard !nameTokens.isEmpty else { continue }

            if nameTokens.count >= 2 {
                if lowercasedText.contains(nameLower) {
                    let key = nameTokens[0]
                    matched[key] = name
                }
            } else {
                let firstName = nameTokens[0]
                if let existing = matched[firstName],
                   tokens(from: existing.lowercased()).count >= 2 {
                    continue
                }
                if firstNameHasSocialContext(firstName, in: words) {
                    matched[firstName] = name
                }
            }
        }

        return Array(matched.values)
    }

    private static func tokens(from text: String) -> [String] {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func firstNameHasSocialContext(_ firstName: String, in words: [String]) -> Bool {
        guard let index = words.firstIndex(of: firstName) else { return false }
        let lower = max(0, index - 3)
        let upper = min(words.count - 1, index + 3)
        return words[lower...upper].contains { socialContextWords.contains($0) }
    }
}
