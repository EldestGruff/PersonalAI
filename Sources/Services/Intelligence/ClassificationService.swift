//
//  ClassificationService.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Classification Service
//  On-device ML classification for thoughts
//

import Foundation
import FoundationModels

// MARK: - Classification Service Protocol

/// Protocol for classification services.
///
/// Enables mocking in tests.
protocol ClassificationServiceProtocol: ServiceProtocol {
    /// Classifies thought content
    func classify(_ content: String) async throws -> Classification

    /// Suggests tags for content
    func suggestTags(_ content: String) async -> [String]
}

// MARK: - Classification Service

/// Service for on-device ML classification of thoughts.
///
/// Uses NLP analysis and heuristic rules to determine:
/// - Thought type (reminder, event, note, question, idea)
/// - Sentiment
/// - Suggested tags
/// - Named entities
///
/// ## Performance Target
///
/// Classification should complete in <200ms.
///
/// ## Classification Logic
///
/// Type classification uses a combination of:
/// - Keyword patterns (e.g., "remind me", "schedule", "what if")
/// - Sentence structure (questions end with "?")
/// - Entity detection (dates/times suggest events)
///
/// In future phases, this can be enhanced with:
/// - Core ML models
/// - Foundation Models (iOS 18+)
/// - Fine-tuned models from user data
actor ClassificationService: ClassificationServiceProtocol, DomainServiceProtocol {
    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Dependencies

    private let nlpService: NLPServiceProtocol
    private let dateTimeParser: DateTimeParsingServiceProtocol
    private let configuration: ServiceConfiguration
    private var foundationModelsClassifier: FoundationModelsClassifier?

    // MARK: - Cache

    private var cache: [String: Classification] = [:]
    private let maxCacheSize = 100

    // MARK: - Initialization

    init(
        nlpService: NLPServiceProtocol,
        dateTimeParser: DateTimeParsingServiceProtocol,
        configuration: ServiceConfiguration = .shared
    ) {
        self.nlpService = nlpService
        self.dateTimeParser = dateTimeParser
        self.configuration = configuration
    }

    /// Convenience initializer that creates its own services
    init(configuration: ServiceConfiguration = .shared) {
        self.nlpService = NLPService(configuration: configuration)
        self.dateTimeParser = DateTimeParsingService(configuration: configuration)
        self.configuration = configuration
    }

    // MARK: - Classification

    /// Classifies thought content.
    ///
    /// Returns a `Classification` containing type, sentiment, entities,
    /// and suggested tags. Results are cached for identical inputs.
    ///
    /// - Parameter content: The thought content to classify
    /// - Returns: Classification result
    /// - Throws: `ServiceError.timeout` if classification exceeds 200ms
    func classify(_ content: String) async throws -> Classification {
        // Check cache
        let cacheKey = content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[cacheKey] {
            return cached
        }

        let startTime = Date()
        let timeout = configuration.timeouts.classification

        // Run classification with timeout
        let result = await withTimeoutOrThrow(timeout) {
            await self.performClassification(content)
        }

        guard let classification = result else {
            throw ServiceError.timeout(
                operation: "classification",
                elapsedMs: Int(Date().timeIntervalSince(startTime) * 1000),
                limitMs: Int(timeout * 1000)
            )
        }

        // Update cache
        updateCache(key: cacheKey, value: classification)

        return classification
    }

    private func performClassification(_ content: String) async -> Classification {
        let startTime = Date()

        // PRIMARY (iOS 26): Use Foundation Models for intelligent classification
        // This replaces hardcoded keyword patterns with AI that understands intent
        if foundationModelsClassifier == nil {
            foundationModelsClassifier = FoundationModelsClassifier()
        }

        var type: ClassificationType
        var sentiment: Sentiment
        var tags: [String]
        var confidence: Double
        var model: String

        if let classifier = foundationModelsClassifier {
            do {
                let result = try await classifier.classify(content)
                type = result.type
                sentiment = result.sentiment
                tags = result.tags
                confidence = result.confidence
                model = "foundation-models-v1"

                NSLog("✅ Foundation Models classification: type=\(type), sentiment=\(sentiment), confidence=\(confidence)")
            } catch {
                // Fallback to keyword-based classification (Issue #8: improved logging)
                NSLog("⚠️  Foundation Models unavailable, using keyword-based fallback")
                NSLog("   Reason: \(error.localizedDescription)")
                async let typeResult = classifyType(content)
                async let sentimentResult = nlpService.analyzeSentiment(content)
                async let entitiesResult = nlpService.extractEntities(content)

                type = await typeResult
                sentiment = await sentimentResult
                let entities = await entitiesResult
                tags = await generateTags(content: content, entities: entities)
                confidence = calculateConfidence(type: type, content: content)
                model = "nlp-heuristic-v1"
            }
        } else {
            // No Foundation Models available, use keyword-based fallback
            async let typeResult = classifyType(content)
            async let sentimentResult = nlpService.analyzeSentiment(content)
            async let entitiesResult = nlpService.extractEntities(content)

            type = await typeResult
            sentiment = await sentimentResult
            let entities = await entitiesResult
            tags = await generateTags(content: content, entities: entities)
            confidence = calculateConfidence(type: type, content: content)
            model = "nlp-heuristic-v1"
        }

        // Run language detection and date/time parsing in parallel (still needed)
        async let languageResult = nlpService.detectLanguage(content)
        async let dateTimeResult = dateTimeParser.parseDateTime(content, referenceDate: Date())

        let language = await languageResult
        let parsedDateTime = await dateTimeResult

        // Extract entities if not already done (for metadata)
        let entities = await nlpService.extractEntities(content)

        // Only include parsed date/time if it has reasonable confidence
        // Convert from internal detailed version to model version
        // Issue #8: Lowered threshold from 0.7 to 0.6 to catch more valid dates
        let finalParsedDateTime: ParsedDateTime?
        if parsedDateTime.confidence >= 0.6 {
            finalParsedDateTime = parsedDateTime.toModel()
        } else {
            finalParsedDateTime = nil
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return Classification(
            id: UUID(),
            type: type,
            confidence: confidence,
            entities: entities,
            suggestedTags: Array(tags.prefix(5)),
            sentiment: sentiment,
            language: language,
            processingTime: processingTime,
            model: model,
            createdAt: Date(),
            parsedDateTime: finalParsedDateTime
        )
    }

    // MARK: - Type Classification

    private func classifyType(_ content: String) async -> ClassificationType {
        let lowercased = content.lowercased()

        // Check for reminder indicators
        if containsReminderIndicators(lowercased) {
            return .reminder
        }

        // Check for event indicators
        if containsEventIndicators(lowercased) {
            return .event
        }

        // Check for question indicators
        if isQuestion(lowercased) {
            return .question
        }

        // Check for idea indicators
        if containsIdeaIndicators(lowercased) {
            return .idea
        }

        // Default to note
        return .note
    }

    private func containsReminderIndicators(_ text: String) -> Bool {
        let reminderPatterns = [
            "remind me",
            "don't forget",
            "remember to",
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

        return reminderPatterns.contains { text.contains($0) }
    }

    private func containsEventIndicators(_ text: String) -> Bool {
        let eventPatterns = [
            "meeting",
            "appointment",
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
            "o'clock",
            "am",
            "pm"
        ]

        return eventPatterns.contains { text.contains($0) }
    }

    private func isQuestion(_ text: String) -> Bool {
        // Ends with question mark
        if text.trimmingCharacters(in: .whitespaces).hasSuffix("?") {
            return true
        }

        // Starts with question words
        let questionStarters = ["what", "who", "where", "when", "why", "how", "is", "are", "can", "could", "would", "should", "do", "does"]

        let firstWord = text.split(separator: " ").first?.lowercased() ?? ""
        return questionStarters.contains(String(firstWord))
    }

    private func containsIdeaIndicators(_ text: String) -> Bool {
        let ideaPatterns = [
            "what if",
            "idea:",
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

        return ideaPatterns.contains { text.contains($0) }
    }

    // MARK: - Confidence Calculation

    private func calculateConfidence(type: ClassificationType, content: String) -> Double {
        let lowercased = content.lowercased()

        switch type {
        case .reminder:
            // High confidence if explicit reminder language
            if lowercased.contains("remind me") || lowercased.contains("don't forget") {
                return 0.95
            }
            // Medium confidence for action verbs
            if lowercased.contains("need to") || lowercased.contains("have to") {
                return 0.85
            }
            return 0.75

        case .event:
            // High confidence if time mentioned
            if lowercased.contains("meeting") || lowercased.contains("appointment") {
                return 0.90
            }
            // Medium confidence for day mentions
            if lowercased.contains("tomorrow") || lowercased.contains("next week") {
                return 0.80
            }
            return 0.70

        case .question:
            // High confidence if ends with ?
            if lowercased.trimmingCharacters(in: .whitespaces).hasSuffix("?") {
                return 0.95
            }
            return 0.80

        case .idea:
            // Medium-high confidence for idea patterns
            if lowercased.contains("what if") || lowercased.contains("idea:") {
                return 0.85
            }
            return 0.70

        case .note:
            // Default confidence for notes
            return 0.65
        }
    }

    // MARK: - Tag Generation

    /// Suggests tags for content.
    ///
    /// Combines entity extraction with keyword analysis.
    func suggestTags(_ content: String) async -> [String] {
        let entities = await nlpService.extractEntities(content)
        return await generateTags(content: content, entities: entities)
    }

    private func generateTags(content: String, entities: [String]) async -> [String] {
        var tags: Set<String> = []

        // Add entities as tags (normalized)
        for entity in entities {
            let normalized = normalizeTag(entity)
            if !normalized.isEmpty && normalized.count <= 50 {
                tags.insert(normalized)
            }
        }

        // Extract keywords
        let lemmas = await nlpService.lemmatize(content)
        let keywords = extractKeywords(from: lemmas)

        for keyword in keywords {
            let normalized = normalizeTag(keyword)
            if !normalized.isEmpty && normalized.count <= 50 {
                tags.insert(normalized)
            }
        }

        // Sort by length (shorter tags first) and limit to 5
        return Array(tags)
            .sorted { $0.count < $1.count }
            .prefix(5)
            .map { $0 }
    }

    private func extractKeywords(from lemmas: [String]) -> [String] {
        // Filter out common stop words
        let stopWords = Set([
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
            "be", "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "must", "shall", "can", "need", "dare", "ought",
            "used", "i", "me", "my", "myself", "we", "our", "ours", "you", "your",
            "he", "him", "his", "she", "her", "it", "its", "they", "them", "their",
            "what", "which", "who", "whom", "this", "that", "these", "those", "am",
            "being", "doing", "having", "getting"
        ])

        return lemmas
            .filter { !stopWords.contains($0) }
            .filter { $0.count > 2 } // At least 3 characters
            .filter { $0.allSatisfy { $0.isLetter } } // Letters only
    }

    private func normalizeTag(_ tag: String) -> String {
        // Lowercase, remove special characters, replace spaces with hyphens
        let normalized = tag
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        // Remove consecutive hyphens
        return normalized.replacingOccurrences(
            of: "--+",
            with: "-",
            options: .regularExpression
        )
    }

    // MARK: - Cache Management

    private func updateCache(key: String, value: Classification) {
        // Simple LRU-ish eviction: clear half the cache when full
        if cache.count >= maxCacheSize {
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 2))
            for k in keysToRemove {
                cache.removeValue(forKey: k)
            }
        }
        cache[key] = value
    }

    /// Clears the classification cache
    func clearCache() {
        cache.removeAll()
    }

    /// Pre-warm Foundation Models for faster first classification
    /// Call this when user opens capture screen for optimal performance
    func prewarm() async {
        if let classifier = foundationModelsClassifier {
            await classifier.prewarm()
        }
    }

    // MARK: - Timeout Helper

    private func withTimeoutOrThrow<T: Sendable>(_ timeout: TimeInterval, operation: @Sendable @escaping () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }

            for await result in group {
                if result != nil {
                    group.cancelAll()
                    return result
                }
            }

            return nil
        }
    }

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        clearCache()
    }
}

// MARK: - Mock Classification Service

/// Mock classification service for testing and previews.
actor MockClassificationService: ClassificationServiceProtocol {
    nonisolated var isAvailable: Bool { true }

    var mockClassification: Classification?
    var mockTags: [String]

    init(
        classification: Classification? = nil,
        tags: [String] = ["mock", "test"]
    ) {
        self.mockClassification = classification
        self.mockTags = tags
    }

    func classify(_ content: String) async throws -> Classification {
        if let mock = mockClassification {
            return mock
        }

        return Classification(
            id: UUID(),
            type: .note,
            confidence: 0.85,
            entities: [],
            suggestedTags: mockTags,
            sentiment: .neutral,
            language: "en",
            processingTime: 0.05,
            model: "mock-v1",
            createdAt: Date(),
            parsedDateTime: nil
        )
    }

    func suggestTags(_ content: String) async -> [String] {
        mockTags
    }
}
