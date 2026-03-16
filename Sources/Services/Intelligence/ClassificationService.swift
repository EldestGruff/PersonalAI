//
//  ClassificationService.swift
//  STASH
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
    private let foundationModelsClassifier: FoundationModelsClassifier

    // MARK: - Cache

    private var cache: [String: Classification] = [:]
    private var cacheInsertionOrder: [String] = []
    private let maxCacheSize = AppConstants.Classification.maxCacheSize

    // MARK: - Initialization

    init(
        nlpService: NLPServiceProtocol,
        dateTimeParser: DateTimeParsingServiceProtocol,
        configuration: ServiceConfiguration = .shared
    ) {
        self.nlpService = nlpService
        self.dateTimeParser = dateTimeParser
        self.configuration = configuration
        self.foundationModelsClassifier = FoundationModelsClassifier()
    }

    /// Convenience initializer that creates its own services
    init(configuration: ServiceConfiguration = .shared) {
        self.nlpService = NLPService(configuration: configuration)
        self.dateTimeParser = DateTimeParsingService(configuration: configuration)
        self.configuration = configuration
        self.foundationModelsClassifier = FoundationModelsClassifier()
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
        let result = await ConcurrencyUtilities.withTimeout(timeout) {
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

    // MARK: - Classification Paths

    /// Coordinator: attempts Foundation Models path, falls back to NLP heuristics.
    private func performClassification(_ content: String) async -> Classification {
        let startTime = Date()

        let classificationResult: (ClassificationType, Sentiment, [String], Double, String)
        if let fmResult = await classifyViaFoundationModels(content) {
            classificationResult = fmResult
        } else {
            classificationResult = await classifyViaNLPHeuristics(content)
        }
        var (type, sentiment, tags, confidence, model) = classificationResult

        sentiment = postProcessSentiment(type: type, sentiment: sentiment, content: content)

        async let languageResult = nlpService.detectLanguage(content)
        async let dateTimeResult = dateTimeParser.parseDateTime(content, referenceDate: Date())
        let entities = await nlpService.extractEntities(content)
        let language = await languageResult
        let parsedDateTime = await dateTimeResult

        // Issue #8: threshold lowered from 0.7 → 0.6 to catch more valid dates
        let finalParsedDateTime = parsedDateTime.confidence >= AppConstants.Classification.parsedDateTimeMinConfidence
            ? parsedDateTime.toModel()
            : nil

        return Classification(
            id: UUID(),
            type: type,
            confidence: confidence,
            entities: entities,
            suggestedTags: Array(tags.prefix(AppConstants.Classification.maxSuggestedTags)),
            sentiment: sentiment,
            language: language,
            processingTime: Date().timeIntervalSince(startTime),
            model: model,
            createdAt: Date(),
            parsedDateTime: finalParsedDateTime
        )
    }

    /// Attempts classification using Foundation Models. Returns nil if unavailable or failed.
    private func classifyViaFoundationModels(_ content: String) async
        -> (ClassificationType, Sentiment, [String], Double, String)?
    {
        do {
            let result = try await foundationModelsClassifier.classify(content)
            AppLogger.info(
                "Foundation Models classification: type=\(result.type), confidence=\(result.confidence)",
                category: .classification
            )
            return (result.type, result.sentiment, result.tags, result.confidence, "foundation-models-v1")
        } catch {
            AppLogger.warning(
                "Foundation Models unavailable, using keyword-based fallback. Reason: \(error.localizedDescription)",
                category: .classification
            )
            return nil
        }
    }

    /// NLP heuristic classification path. Always succeeds — never returns nil.
    private func classifyViaNLPHeuristics(_ content: String) async
        -> (ClassificationType, Sentiment, [String], Double, String)
    {
        async let typeResult = classifyType(content)
        async let sentimentResult = nlpService.analyzeSentiment(content)
        async let entitiesResult = nlpService.extractEntities(content)

        let type = await typeResult
        let sentiment = await sentimentResult
        let entities = await entitiesResult
        let tags = await generateTags(content: content, entities: entities)
        let confidence = calculateConfidence(type: type, content: content)
        return (type, sentiment, tags, confidence, "nlp-heuristic-v1")
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

            if let entry = bias.correction(for: pattern, type: type.rawValue),
               entry.weight >= bias.applyThreshold {
                // Type is penalized — return explicit preferred type if known
                if let preferredRaw = entry.preferredType,
                   let preferred = ClassificationType(rawValue: preferredRaw) {
                    AppLogger.infoPublic("Bias correction: \(type.rawValue) → \(preferred.rawValue)", category: .classification)
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
        (ClassificationPatterns.Reminder.highSignal + ClassificationPatterns.Reminder.general)
            .contains { text.contains($0) }
    }

    private func containsEventIndicators(_ text: String) -> Bool {
        (ClassificationPatterns.Event.highSignal + ClassificationPatterns.Event.general)
            .contains { text.contains($0) }
    }

    private func isQuestion(_ text: String) -> Bool {
        if text.trimmingCharacters(in: .whitespaces).hasSuffix("?") { return true }
        let firstWord = text.split(separator: " ").first?.lowercased() ?? ""
        return ClassificationPatterns.questionStarters.contains(String(firstWord))
    }

    /// Returns a type when a high-confidence keyword pattern matches, bypassing the bias store.
    /// Only the strongest unambiguous signals qualify — user corrections cannot override these.
    private func highSignalType(_ text: String) -> ClassificationType? {
        if ClassificationPatterns.Reminder.highSignal.contains(where: { text.contains($0) }) { return .reminder }
        if ClassificationPatterns.Event.highSignal.contains(where: { text.contains($0) }) { return .event }
        if ClassificationPatterns.Idea.highSignal.contains(where: { text.contains($0) }) { return .idea }
        return nil
    }

    private func containsIdeaIndicators(_ text: String) -> Bool {
        (ClassificationPatterns.Idea.highSignal + ClassificationPatterns.Idea.general)
            .contains { text.contains($0) }
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
        return ClassificationPatterns.Sentiment.negativeMarkers
            .contains(where: { lowercased.contains($0) }) ? sentiment : .neutral
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
        if cache[key] == nil {
            cacheInsertionOrder.append(key)
        }
        if cache.count >= maxCacheSize {
            // Evict oldest half by insertion order
            let evictCount = maxCacheSize / 2
            let toEvict = Array(cacheInsertionOrder.prefix(evictCount))
            toEvict.forEach { cache.removeValue(forKey: $0) }
            cacheInsertionOrder.removeFirst(min(evictCount, cacheInsertionOrder.count))
        }
        cache[key] = value
    }

    /// Clears the classification cache
    func clearCache() {
        cache.removeAll()
        cacheInsertionOrder.removeAll()
    }

    /// Pre-warm Foundation Models for faster first classification
    /// Call this when user opens capture screen for optimal performance
    func prewarm() async {
        await foundationModelsClassifier.prewarm()
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
