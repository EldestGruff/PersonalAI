//
//  NLPService.swift
//  STASH
//
//  Phase 3A Spec 2: Natural Language Processing Service
//  Wrapper around Natural Language framework for text analysis
//

import Foundation
import NaturalLanguage

// MARK: - NLP Service Protocol

/// Protocol for NLP services.
///
/// Enables mocking in tests.
protocol NLPServiceProtocol: ServiceProtocol {
    /// Analyzes sentiment of text
    func analyzeSentiment(_ text: String) async -> Sentiment

    /// Detects the dominant language
    func detectLanguage(_ text: String) async -> String

    /// Extracts named entities from text
    func extractEntities(_ text: String) async -> [String]

    /// Lemmatizes text (reduces words to base form)
    func lemmatize(_ text: String) async -> [String]

    /// Tokenizes text into words
    func tokenize(_ text: String) async -> [String]

    /// Extracts tag candidates, joining consecutive nouns as compound phrases.
    ///
    /// For example: "server issues" → ["server-issue"] instead of ["server", "issue"].
    /// Non-noun content words are returned as individual lemmatized tokens.
    func extractTagCandidates(_ text: String) async -> [String]
}

// MARK: - NLP Service

/// Service for text analysis using the Natural Language framework.
///
/// Provides on-device NLP capabilities including:
/// - Sentiment analysis
/// - Language detection
/// - Named entity recognition
/// - Lemmatization
/// - Tokenization
///
/// All operations are synchronous and fast (< 50ms typical).
/// Used by ClassificationService for text analysis.
actor NLPService: NLPServiceProtocol, DomainServiceProtocol {
    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
    }

    // MARK: - Sentiment Analysis

    /// Analyzes the sentiment of text.
    ///
    /// Returns a `Sentiment` value based on the overall tone.
    /// Uses the Natural Language framework's sentiment tagger.
    func analyzeSentiment(_ text: String) async -> Sentiment {
        guard !text.isEmpty else { return .neutral }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let range = text.startIndex..<text.endIndex
        var scores: [Double] = []

        tagger.enumerateTags(in: range, unit: .paragraph, scheme: .sentimentScore, options: [.omitWhitespace]) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                scores.append(score)
            }
            return true
        }

        // Average the scores
        let averageScore: Double
        if scores.isEmpty {
            averageScore = 0.0
        } else {
            averageScore = scores.reduce(0, +) / Double(scores.count)
        }

        return Sentiment.from(score: averageScore)
    }

    // MARK: - Language Detection

    /// Detects the dominant language of text.
    ///
    /// Returns an ISO 639-1 language code (e.g., "en", "es", "fr").
    /// Defaults to "en" if detection fails.
    func detectLanguage(_ text: String) async -> String {
        guard !text.isEmpty else { return "en" }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let language = recognizer.dominantLanguage else {
            return "en"
        }

        return language.rawValue
    }

    // MARK: - Entity Extraction

    /// Extracts named entities from text.
    ///
    /// Identifies:
    /// - Person names
    /// - Place names
    /// - Organization names
    ///
    /// Returns an array of unique entity strings.
    func extractEntities(_ text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let range = text.startIndex..<text.endIndex
        var entities: Set<String> = []

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])
                switch tag {
                case .personalName, .placeName, .organizationName:
                    entities.insert(entity)
                default:
                    break
                }
            }
            return true
        }

        return Array(entities)
    }

    // MARK: - Lemmatization

    /// Lemmatizes text to base word forms.
    ///
    /// For example: "running" -> "run", "better" -> "good"
    /// Returns an array of lemmatized words.
    func lemmatize(_ text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text

        let range = text.startIndex..<text.endIndex
        var lemmas: [String] = []

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange in
            if let lemma = tag?.rawValue {
                lemmas.append(lemma.lowercased())
            } else {
                // Fall back to the original word if no lemma
                lemmas.append(String(text[tokenRange]).lowercased())
            }
            return true
        }

        return lemmas
    }

    // MARK: - Tokenization

    /// Tokenizes text into words.
    ///
    /// Splits text into individual word tokens, removing punctuation.
    func tokenize(_ text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        let range = text.startIndex..<text.endIndex
        var tokens: [String] = []

        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let token = String(text[tokenRange])
            tokens.append(token)
            return true
        }

        return tokens
    }

    // MARK: - Tag Candidates

    /// Extracts tag candidates, joining consecutive nouns as compound phrases.
    ///
    /// Uses a single NLTagger pass with both `.lexicalClass` and `.lemma` schemes.
    /// Consecutive nouns are lemmatized and joined with hyphens (e.g. "server-issue").
    /// Non-noun tokens are returned as individual lemmatized words.
    func extractTagCandidates(_ text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text

        var result: [String] = []
        var currentNounPhrase: [String] = []

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let lemmaTag = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma)
            let word = (lemmaTag?.rawValue ?? String(text[tokenRange])).lowercased()

            if tag == .noun {
                currentNounPhrase.append(word)
            } else {
                if !currentNounPhrase.isEmpty {
                    result.append(currentNounPhrase.count > 1
                        ? currentNounPhrase.joined(separator: "-")
                        : currentNounPhrase[0])
                    currentNounPhrase = []
                }
                result.append(word)
            }
            return true
        }

        if !currentNounPhrase.isEmpty {
            result.append(currentNounPhrase.count > 1
                ? currentNounPhrase.joined(separator: "-")
                : currentNounPhrase[0])
        }

        return result
    }

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        // No cleanup needed
    }
}

// MARK: - Sentiment Extension

extension Sentiment {
    /// Creates a Sentiment from a score (-1.0 to 1.0)
    ///
    /// Thresholds adjusted for Apple's NLTagger which tends to skew negative
    /// for neutral content. Most neutral text scores between -0.5 and 0.3.
    static func from(score: Double) -> Sentiment {
        switch score {
        case ..<(-0.75):
            return .very_negative
        case -0.75..<(-0.5):
            return .negative
        case -0.5..<0.3:
            return .neutral
        case 0.3..<0.7:
            return .positive
        default:
            return .very_positive
        }
    }

    /// Converts to a numeric score (-1.0 to 1.0)
    var score: Double {
        switch self {
        case .very_negative: return -0.8
        case .negative: return -0.4
        case .neutral: return 0.0
        case .positive: return 0.4
        case .very_positive: return 0.8
        }
    }
}

// MARK: - Mock NLP Service

/// Mock NLP service for testing and previews.
actor MockNLPService: NLPServiceProtocol {
    nonisolated var isAvailable: Bool { true }

    var mockSentiment: Sentiment
    var mockLanguage: String
    var mockEntities: [String]
    var mockLemmas: [String]
    var mockTokens: [String]

    init(
        sentiment: Sentiment = .neutral,
        language: String = "en",
        entities: [String] = ["John", "Apple Inc"],
        lemmas: [String] = ["test", "word"],
        tokens: [String] = ["test", "tokens"]
    ) {
        self.mockSentiment = sentiment
        self.mockLanguage = language
        self.mockEntities = entities
        self.mockLemmas = lemmas
        self.mockTokens = tokens
    }

    func analyzeSentiment(_ text: String) async -> Sentiment {
        mockSentiment
    }

    func detectLanguage(_ text: String) async -> String {
        mockLanguage
    }

    func extractEntities(_ text: String) async -> [String] {
        mockEntities
    }

    func lemmatize(_ text: String) async -> [String] {
        mockLemmas
    }

    func tokenize(_ text: String) async -> [String] {
        mockTokens
    }

    func extractTagCandidates(_ text: String) async -> [String] {
        mockLemmas
    }
}
