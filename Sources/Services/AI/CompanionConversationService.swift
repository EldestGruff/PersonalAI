//
//  CompanionConversationService.swift
//  STASH
//
//  AI service for thought-specific companion conversations
//

import Foundation
import FoundationModels

/// Actor-based service for thought-specific conversational AI
@available(iOS 26.0, *)
actor CompanionConversationService {

    // MARK: - Properties

    private var session: LanguageModelSession?
    private let thoughtService: ThoughtServiceProtocol
    private let semanticSearchService: SemanticSearchService
    private var currentThought: Thought?
    private var currentPersona: SquirrelPersona?
    private var isPrivateMode: Bool = false

    // MARK: - Initialization

    init(thoughtService: ThoughtServiceProtocol, semanticSearchService: SemanticSearchService) {
        self.thoughtService = thoughtService
        self.semanticSearchService = semanticSearchService
    }

    /// Availability of Apple Intelligence
    nonisolated var isAvailable: Bool {
        SystemLanguageModel().availability == .available
    }

    // MARK: - Session Management

    /// Start a new conversation for a specific thought with a persona
    func startConversation(
        thought: Thought,
        persona: SquirrelPersona,
        isPrivate: Bool = false
    ) async throws {
        guard SystemLanguageModel().availability == .available else {
            throw ConversationError.serviceUnavailable
        }

        self.currentThought = thought
        self.currentPersona = persona
        self.isPrivateMode = isPrivate

        // Build system prompt combining persona + thought context
        let systemPrompt = buildSystemPrompt(thought: thought, persona: persona, isPrivate: isPrivate)

        // Create new session
        self.session = LanguageModelSession(instructions: systemPrompt)

        print("✅ Started companion conversation: \(persona.emoji) \(persona.name) | Private: \(isPrivate)")
    }

    /// End the current conversation session
    func endConversation() {
        session = nil
        currentThought = nil
        currentPersona = nil
        print("🔚 Ended companion conversation")
    }

    // MARK: - Message Handling

    /// Send a message and get AI response
    func sendMessage(_ userMessage: String) async throws -> ConversationResponse {
        guard let session = session else {
            throw ConversationError.sessionNotInitialized
        }

        guard let thought = currentThought else {
            throw ConversationError.sessionNotInitialized
        }

        // Build context-aware prompt
        let enrichedPrompt: String
        if isPrivateMode {
            // Private mode: Only current thought + conversation history
            enrichedPrompt = buildPrivatePrompt(userMessage: userMessage, thought: thought)
        } else {
            // Connected mode: Include relevant thoughts from database
            let relevantThoughts = try await findRelevantThoughts(query: userMessage, excluding: thought.id)
            enrichedPrompt = buildConnectedPrompt(
                userMessage: userMessage,
                thought: thought,
                relevantThoughts: relevantThoughts
            )
        }

        do {
            // Get response from Foundation Models
            let response = try await session.respond(to: enrichedPrompt)
            let responseText = response.content

            // Create citations (only in connected mode)
            let citations: [ThoughtCitation]
            if isPrivateMode {
                citations = []
            } else {
                let relevantThoughts = try await findRelevantThoughts(query: userMessage, excluding: thought.id)
                citations = relevantThoughts.prefix(3).map { relatedThought in
                    ThoughtCitation(
                        thoughtId: relatedThought.id,
                        excerpt: String(relatedThought.content.prefix(150)),
                        relevanceScore: 0.85,
                        date: relatedThought.createdAt,
                        tags: relatedThought.tags
                    )
                }
            }

            // Generate suggested questions based on persona
            let suggestions = generateSuggestedQuestions(
                persona: currentPersona ?? .default,
                conversationContext: userMessage
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

    // MARK: - Thought Search (Connected Mode)

    private func findRelevantThoughts(query: String, excluding thoughtId: UUID) async throws -> [Thought] {
        // Get all thoughts except the current one
        let allThoughts = try await thoughtService.list(filter: nil)
        let otherThoughts = allThoughts.filter { $0.id != thoughtId }

        // Use semantic search
        let results = await semanticSearchService.search(query: query, in: otherThoughts)

        return Array(results.prefix(5).map { $0.thought })
    }

    // MARK: - Prompt Engineering

    private func buildSystemPrompt(
        thought: Thought,
        persona: SquirrelPersona,
        isPrivate: Bool
    ) -> String {
        var prompt = persona.systemPrompt
        prompt += "\n\n---\n\n"
        prompt += "THE THOUGHT YOU'RE EXPLORING:\n"
        prompt += "\"\(thought.content)\"\n"

        if !thought.tags.isEmpty {
            prompt += "Tags: \(thought.tags.map { "#\($0)" }.joined(separator: " "))\n"
        }

        prompt += "Captured: \(formatDate(thought.createdAt))\n"

        if isPrivate {
            prompt += "\nPrivacy mode is on — stay focused on this thought only. Do not reference or suggest connections to other thoughts."
        } else {
            prompt += "\nWhen relevant, you'll receive related past thoughts to help you make connections across the user's thinking."
        }

        return prompt
    }

    private func buildPrivatePrompt(userMessage: String, thought: Thought) -> String {
        userMessage
    }

    private func buildConnectedPrompt(
        userMessage: String,
        thought: Thought,
        relevantThoughts: [Thought]
    ) -> String {
        guard !relevantThoughts.isEmpty else {
            return userMessage
        }

        var prompt = userMessage
        prompt += "\n\n[Background context — do not change the subject to these; use only if directly relevant]\n"
        for (index, relatedThought) in relevantThoughts.enumerated() {
            prompt += "\(index + 1). \(formatDate(relatedThought.createdAt)): "
            prompt += String(relatedThought.content.prefix(200))
            if !relatedThought.tags.isEmpty {
                prompt += " [\(relatedThought.tags.joined(separator: ", "))]"
            }
            prompt += "\n"
        }

        return prompt
    }

    // MARK: - Suggested Questions

    private func generateSuggestedQuestions(
        persona: SquirrelPersona,
        conversationContext: String
    ) -> [String] {
        // Persona-specific question templates
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                "How does that make you feel?",
                "Tell me more about that",
                "What else is on your mind?"
            ]

        case SquirrelPersona.socraticQuestioner.id:
            return [
                "Why do you think that?",
                "What evidence supports this?",
                "What if the opposite were true?"
            ]

        case SquirrelPersona.brainstormPartner.id:
            return [
                "What if we took this further?",
                "What wild ideas does this spark?",
                "How could we combine this with something else?"
            ]

        case SquirrelPersona.journalGuide.id:
            return [
                "Where do you feel that in your body?",
                "What triggered this feeling?",
                "What would help right now?"
            ]

        case SquirrelPersona.devilsAdvocate.id:
            return [
                "What could go wrong?",
                "What are the counterarguments?",
                "Have you considered the downsides?"
            ]

        default:
            return [
                "Tell me more",
                "What else comes to mind?",
                "How do you feel about that?"
            ]
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
