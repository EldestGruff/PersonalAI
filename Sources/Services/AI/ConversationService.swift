//
//  ConversationService.swift
//  PersonalAI
//
//  Conversational AI service for exploring thoughts using Foundation Models
//

import Foundation
import FoundationModels

/// Actor-based service for conversational thought exploration
@available(iOS 26.0, *)
actor ConversationService {

    // MARK: - Properties

    private var session: LanguageModelSession?
    private let thoughtService: ThoughtServiceProtocol
    private let semanticSearchService: SemanticSearchService
    private var thoughtContext: ThoughtContext?

    // MARK: - Initialization

    init(
        thoughtService: ThoughtServiceProtocol,
        semanticSearchService: SemanticSearchService
    ) {
        self.thoughtService = thoughtService
        self.semanticSearchService = semanticSearchService
    }

    /// Availability of Apple Intelligence
    nonisolated var isAvailable: Bool {
        SystemLanguageModel().availability == .available
    }

    // MARK: - Session Management

    /// Start a new conversation session with user's thought context
    func startConversation() async throws {
        guard SystemLanguageModel().availability == .available else {
            throw ConversationError.serviceUnavailable
        }

        // Load thought context
        let context = try await buildThoughtContext()
        self.thoughtContext = context

        // Create new session with system instructions
        self.session = LanguageModelSession(
            instructions: buildSystemPrompt(context: context)
        )

        print("✅ Conversation session started with \(context.totalCount) thoughts")
    }

    /// End the current conversation session
    func endConversation() {
        session = nil
        thoughtContext = nil
        print("🔚 Conversation session ended")
    }

    // MARK: - Message Handling

    /// Send a message and get AI response
    func sendMessage(_ userMessage: String) async throws -> ConversationResponse {
        guard let session = session else {
            throw ConversationError.sessionNotInitialized
        }

        guard let context = thoughtContext else {
            throw ConversationError.sessionNotInitialized
        }

        // Search for relevant thoughts based on the query
        let relevantThoughts = try await findRelevantThoughts(query: userMessage)

        // Build prompt with relevant thoughts
        let enrichedPrompt = buildUserPrompt(
            userMessage: userMessage,
            relevantThoughts: relevantThoughts
        )

        do {
            // Get response from Foundation Models
            let response = try await session.respond(to: enrichedPrompt)
            let responseText = response.content

            // Create citations from relevant thoughts
            let citations = relevantThoughts.prefix(5).map { thought in
                ThoughtCitation(
                    thoughtId: thought.id,
                    excerpt: String(thought.content.prefix(150)),
                    relevanceScore: 0.85, // TODO: Get actual score from semantic search
                    date: thought.createdAt,
                    tags: thought.tags
                )
            }

            // Generate suggested follow-up questions
            let suggestions = generateSuggestedQuestions(
                userMessage: userMessage,
                context: context
            )

            return ConversationResponse(
                message: responseText,
                citations: citations,
                suggestedQuestions: suggestions
            )

        } catch {
            throw ConversationError.generationFailed(underlying: error)
        }
    }

    /// Stream message response for real-time display
    /// Note: FoundationModels does not support streaming, so this simulates streaming
    func streamMessage(_ userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        guard session != nil else {
            throw ConversationError.sessionNotInitialized
        }

        // Use the non-streaming sendMessage and simulate streaming
        return AsyncThrowingStream { continuation in
            _Concurrency.Task {
                do {
                    let response = try await self.sendMessage(userMessage)
                    // Simulate streaming by yielding word by word
                    let words = response.message.split(separator: " ")
                    for word in words {
                        continuation.yield(String(word) + " ")
                        try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Thought Search

    private func findRelevantThoughts(query: String) async throws -> [Thought] {
        // Get all thoughts for semantic search
        let allThoughts = try await thoughtService.list(filter: nil)

        // Use semantic search to find relevant thoughts
        let results = await semanticSearchService.search(
            query: query,
            in: allThoughts
        )

        return Array(results.prefix(10).map { $0.thought })
    }

    // MARK: - Context Building

    private func buildThoughtContext() async throws -> ThoughtContext {
        // Get recent thoughts (last 50)
        let allThoughts = try await thoughtService.list(filter: nil)

        guard !allThoughts.isEmpty else {
            throw ConversationError.noThoughtsFound
        }

        let recentThoughts = Array(allThoughts.prefix(50))

        // Calculate date range
        let oldestDate = recentThoughts.last?.createdAt ?? Date()
        let newestDate = recentThoughts.first?.createdAt ?? Date()
        let dateRange = formatDateRange(from: oldestDate, to: newestDate)

        // Get top tags
        var tagCounts: [String: Int] = [:]
        for thought in recentThoughts {
            for tag in thought.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        let topTags = Dictionary(
            uniqueKeysWithValues: tagCounts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
        )

        // Build summary stats
        let summaryStats = """
        Total thoughts: \(allThoughts.count)
        Recent thoughts: \(recentThoughts.count)
        Time range: \(dateRange)
        Top tags: \(topTags.keys.joined(separator: ", "))
        """

        return ThoughtContext(
            recentThoughts: recentThoughts.map { ThoughtSummary(from: $0) },
            dateRange: dateRange,
            topTags: topTags,
            summaryStats: summaryStats,
            totalCount: allThoughts.count
        )
    }

    // MARK: - Prompt Engineering

    private func buildSystemPrompt(context: ThoughtContext) -> String {
        return """
        You are a personal AI assistant helping the user explore their captured thoughts.

        GUIDELINES:
        - Reference specific thoughts with dates and excerpts
        - Identify patterns across multiple thoughts
        - Suggest follow-up questions to deepen exploration
        - Be empathetic and supportive in tone
        - Respect privacy - never suggest sharing externally
        - Use natural, conversational language

        USER'S THOUGHT DATABASE:
        - Total thoughts: \(context.totalCount)
        - Date range: \(context.dateRange)
        - Top tags: \(context.topTags.keys.joined(separator: ", "))

        When answering questions:
        1. Search through provided thoughts for relevant information
        2. Cite specific thoughts with dates
        3. Identify patterns or themes
        4. Suggest related questions the user might want to explore

        Be concise but insightful. Focus on helping the user discover patterns and insights
        from their own captured thoughts.
        """
    }

    private func buildUserPrompt(userMessage: String, relevantThoughts: [Thought]) -> String {
        var prompt = "User question: \(userMessage)\n\n"

        if !relevantThoughts.isEmpty {
            prompt += "RELEVANT THOUGHTS:\n"
            for (index, thought) in relevantThoughts.prefix(10).enumerated() {
                let dateStr = formatDate(thought.createdAt)
                let contentPreview = String(thought.content.prefix(200))
                let tags = thought.tags.isEmpty ? "" : " [Tags: \(thought.tags.joined(separator: ", "))]"

                prompt += "\n\(index + 1). \(dateStr): \(contentPreview)\(tags)\n"
            }
            prompt += "\n"
        }

        prompt += "Please answer the user's question based on these thoughts."

        return prompt
    }

    // MARK: - Suggested Questions

    private func generateSuggestedQuestions(
        userMessage: String,
        context: ThoughtContext
    ) -> [String] {
        // Generate contextual follow-up questions
        let suggestions: [String] = [
            "What patterns do you see in my thoughts?",
            "How has my mood been trending?",
            "What am I most focused on lately?",
            "Show me thoughts related to \(context.topTags.keys.first ?? "work")"
        ]

        return Array(suggestions.prefix(3))
    }

    // MARK: - Formatting Helpers

    private func formatDateRange(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if daysDiff == 0 {
            return "Today"
        } else if daysDiff < 7 {
            return "Last \(daysDiff + 1) days"
        } else if daysDiff < 30 {
            return "Last \(daysDiff / 7) weeks"
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mock Service

/// Mock conversation service for testing and previews
@available(iOS 26.0, *)
actor MockConversationService {

    private let thoughtService: ThoughtServiceProtocol

    init(thoughtService: ThoughtServiceProtocol) {
        self.thoughtService = thoughtService
    }

    nonisolated var isAvailable: Bool {
        true
    }

    func startConversation() async throws {
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
    }

    func endConversation() {
        // Mock end
    }

    func sendMessage(_ userMessage: String) async throws -> ConversationResponse {
        try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)

        return ConversationResponse(
            message: "I found 5 thoughts about '\(userMessage)'. Your main themes were productivity and planning. You seem most focused on work-related tasks lately.",
            citations: [
                ThoughtCitation(
                    thoughtId: UUID(),
                    excerpt: "Need to finish the project proposal by Friday...",
                    relevanceScore: 0.92,
                    date: Date().addingTimeInterval(-86400),
                    tags: ["work", "planning"]
                )
            ],
            suggestedQuestions: [
                "What patterns do you see in my thoughts?",
                "How has my mood been trending?",
                "What am I most focused on lately?"
            ]
        )
    }

    func streamMessage(_ userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            _Concurrency.Task {
                let response = "I found several thoughts about '\(userMessage)'..."
                for word in response.split(separator: " ") {
                    try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
                    continuation.yield(String(word) + " ")
                }
                continuation.finish()
            }
        }
    }
}
