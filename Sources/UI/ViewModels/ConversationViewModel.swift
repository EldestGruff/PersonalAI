//
//  ConversationViewModel.swift
//  STASH
//
//  View model for conversational thought exploration
//

import Foundation

@available(iOS 26.0, *)
@Observable
@MainActor
class ConversationViewModel {

    // MARK: - Properties

    let session = ConversationSession()
    private let conversationService: ConversationService
    private let thoughtService: ThoughtServiceProtocol

    var thoughtCount: Int = 0
    var isInitialized: Bool = false

    let starterQuestions = [
        "What did I think about this week?",
        "Show me my most positive thoughts",
        "What patterns do you see?",
        "What am I focused on lately?"
    ]

    // MARK: - Initialization

    init(thoughtService: ThoughtServiceProtocol) {
        self.thoughtService = thoughtService
        self.conversationService = ConversationService(
            thoughtService: thoughtService,
            semanticSearchService: SemanticSearchService.shared
        )
    }

    // MARK: - Lifecycle

    func initialize() async {
        guard !isInitialized else { return }

        // Load thought count
        do {
            let thoughts = try await thoughtService.list(filter: nil)
            thoughtCount = thoughts.count
        } catch {
            AppLogger.ui.error("Failed to load thought count: \(error)")
        }

        // Start conversation session
        await startNewSession()

        isInitialized = true
    }

    func startNewSession() async {
        session.clear()
        session.isLoading = true

        do {
            try await conversationService.startConversation()
            session.isLoading = false
        } catch {
            session.error = error
            session.isLoading = false
            AppLogger.ui.error("Failed to start conversation: \(error)")
        }
    }

    // MARK: - Message Handling

    func sendMessage(_ content: String) async {
        // Add user message
        let userMessage = ConversationMessage(
            role: .user,
            content: content
        )
        session.addMessage(userMessage)

        // Set loading state
        session.isLoading = true
        session.error = nil

        do {
            // Get AI response
            let response = try await conversationService.sendMessage(content)

            // Add assistant message
            let assistantMessage = ConversationMessage(
                role: .assistant,
                content: response.message,
                citations: response.citations,
                suggestedQuestions: response.suggestedQuestions
            )
            session.addMessage(assistantMessage)

            session.isLoading = false
        } catch {
            session.error = error
            session.isLoading = false
            AppLogger.ui.error("Failed to send message: \(error)")
        }
    }

    func retry() async {
        guard let lastUserMessage = session.userMessages.last else { return }
        await sendMessage(lastUserMessage.content)
    }

    // MARK: - Actions

    func clearConversation() {
        session.clear()
    }
}
