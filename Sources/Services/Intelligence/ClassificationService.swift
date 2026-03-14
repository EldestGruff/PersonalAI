//
//  ClassificationService.swift
//  STASH
//
//  Phase 3A Spec 2: Classification Service
//  On-device ML classification for thoughts
//

import Foundation
import FoundationModels
import OSLog

// MARK: - Classification Service Protocol

/// Protocol for classification services.
///
/// Enables mocking in tests.
protocol ClassificationServiceProtocol: ServiceProtocol {
    /// Classifies thought content
    func classify(_ content: String) async throws -> Classification

    /// Suggests tags for content
    func suggestTags(_ content: String) async -> [String]

    /// Pre-warms the underlying model to reduce first-classification latency
    func prewarm() async
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
            AnalyticsService.shared.track(.classificationFailed)
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
        // Holds entities extracted on fallback paths so we don't re-extract below.
        var fallbackEntities: [String]? = nil

        if let classifier = foundationModelsClassifier {
            do {
                let result = try await classifier.classify(content)
                type = result.type
                sentiment = result.sentiment
                tags = result.tags
                confidence = result.confidence
                model = "foundation-models-v1"

                AppLogger.services.info("Foundation Models classification: type=\(type), sentiment=\(sentiment), confidence=\(confidence)")
            } catch {
                // Fallback to keyword-based classification (Issue #8: improved logging)
                AppLogger.services.warning("Foundation Models unavailable, using keyword-based fallback")
                AppLogger.services.warning("Reason: \(error.localizedDescription)")
                async let typeResult = classifyType(content)
                async let sentimentResult = nlpService.analyzeSentiment(content)
                async let entitiesResult = nlpService.extractEntities(content)

                type = await typeResult
                sentiment = await sentimentResult
                let entities = await entitiesResult
                fallbackEntities = entities
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
            fallbackEntities = entities
            tags = await generateTags(content: content, entities: entities)
            confidence = calculateConfidence(type: type, content: content)
            model = "nlp-heuristic-v1"
        }

        // Post-process: cap reminder/event sentiment at Neutral unless genuinely emotional (#65)
        sentiment = postProcessSentiment(type: type, sentiment: sentiment, content: content)

        // Run language detection and date/time parsing in parallel (still needed)
        async let languageResult = nlpService.detectLanguage(content)
        async let dateTimeResult = dateTimeParser.parseDateTime(content, referenceDate: Date())

        let language = await languageResult
        let parsedDateTime = await dateTimeResult

        // Reuse entities from fallback path if already extracted; otherwise extract now
        // (FM success path doesn't extract entities during classification).
        let entities = fallbackEntities ?? (await nlpService.extractEntities(content))

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

        // High-signal short-circuit: top-tier keyword matches bypass the bias store (#66)
        if let highSignal = highSignalType(lowercased) {
            return highSignal
        }

        let pattern = ClassificationBiasStore.extractPattern(from: lowercased)
        let bias = ClassificationBiasStore.shared

        // Ordered candidates matching original heuristic priority.
        // The bias store can skip a penalized type and jump to the next match,
        // or return an explicit preferred type if the user recorded one via a type edit.
        let candidates: [(ClassificationType, Bool)] = [
            (.reminder, containsReminderIndicators(lowercased)),
            (.event, containsEventIndicators(lowercased)),
            (.question, isQuestion(lowercased)),
            (.idea, containsIdeaIndicators(lowercased)),
            (.note, true)
        ]

        for (type, matches) in candidates {
            guard matches else { continue }

            if bias.penaltyWeight(for: pattern, type: type.rawValue) >= bias.applyThreshold {
                // Type is penalized — return explicit preferred type if known
                if let preferredRaw = bias.preferredType(for: pattern, penalizedType: type.rawValue),
                   let preferred = ClassificationType(rawValue: preferredRaw) {
                    AppLogger.services.debug("Bias correction: \(type.rawValue) → \(preferred.rawValue) for '\(pattern)'")
                    return preferred
                }
                // No preferred type recorded yet — skip to next candidate
                continue
            }

            return type
        }

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

    /// Returns a type when a high-confidence keyword pattern matches, bypassing the bias store.
    /// Only the strongest unambiguous signals qualify — user corrections cannot override these.
    private func highSignalType(_ text: String) -> ClassificationType? {
        let highSignalReminders = ["remind me", "don't forget", "remember to"]
        if highSignalReminders.contains(where: { text.contains($0) }) { return .reminder }

        let highSignalEvents = ["meeting", "appointment"]
        if highSignalEvents.contains(where: { text.contains($0) }) { return .event }

        let highSignalIdeas = ["what if", "idea:"]
        if highSignalIdeas.contains(where: { text.contains($0) }) { return .idea }

        return nil
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

    /// Corrects spurious negative sentiment on reminder and event thoughts.
    ///
    /// NLP reads transactional words ("pay", "rent", "dentist") as negative. Only
    /// genuine emotional language (e.g. "stressed", "dreading") should keep the
    /// negative classification on logistical thought types. (#65)
    private func postProcessSentiment(
        type: ClassificationType,
        sentiment: Sentiment,
        content: String
    ) -> Sentiment {
        guard type == .reminder || type == .event else { return sentiment }
        guard sentiment == .negative || sentiment == .very_negative else { return sentiment }

        let lowercased = content.lowercased()
        let emotionalMarkers = [
            "stressed", "anxious", "worried", "scared",
            "hate", "dread", "dreading", "overwhelmed",
            "terrible", "awful"
        ]
        return emotionalMarkers.contains(where: { lowercased.contains($0) }) ? sentiment : .neutral
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

        // Extract tag candidates — consecutive nouns are compounded (e.g. "server-issue")
        let candidates = await nlpService.extractTagCandidates(content)
        let keywords = extractKeywords(from: candidates)

        for keyword in keywords {
            let normalized = normalizeTag(keyword)
            if !normalized.isEmpty && normalized.count <= 50 {
                tags.insert(normalized)
            }
        }

        // Cross-reference against existing tag library — prefer canonical stored forms
        let canonical = await canonicalizeTags(Array(tags))

        // Sort by length (shorter tags first) and limit to 5
        return canonical
            .sorted { $0.count < $1.count }
            .prefix(5)
            .map { $0 }
    }

    /// Maps generated tags to canonical forms from the user's existing tag library.
    /// If a generated tag is similar to a stored tag, the stored form wins.
    private func canonicalizeTags(_ tags: [String]) async -> [String] {
        let existingTags = (try? await ThoughtRepository.shared.fetchAllUniqueTags()) ?? []
        guard !existingTags.isEmpty else { return tags }
        return tags.map { TagNormalizationService.canonicalize($0, from: existingTags) }
    }

    private func extractKeywords(from candidates: [String]) -> [String] {
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

        return candidates.filter { candidate in
            if candidate.contains("-") {
                // Compound noun phrase — validate each component
                let parts = candidate.components(separatedBy: "-")
                return parts.count >= 2
                    && parts.allSatisfy { !stopWords.contains($0) && $0.count > 2 && $0.allSatisfy { $0.isLetter } }
            }
            // Single word — standard filters
            return !stopWords.contains(candidate)
                && candidate.count > 2
                && candidate.allSatisfy { $0.isLetter }
        }
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

    func prewarm() async {
        // No-op for mock
    }
}
