//
//  ThoughtConversationViewModel.swift
//  PersonalAI
//
//  ViewModel for thought-specific companion conversations
//

import Foundation

@available(iOS 26.0, *)
@Observable
@MainActor
class ThoughtConversationViewModel {

    // MARK: - Properties

    let thought: Thought
    var currentConversation: ThoughtConversation?
    var selectedPersona: SquirrelPersona
    var isPrivate: Bool
    var messages: [ConversationMessage] = []
    var isLoading: Bool = false
    var error: Error?
    var inputText: String = ""

    private let companionService: CompanionConversationService
    private let thoughtService: ThoughtServiceProtocol
    private let conversationService = ThoughtConversationService.shared
    private let personaService = PersonaService.shared

    var allConversations: [ThoughtConversation] = []
    var conversationCount: Int {
        allConversations.count
    }

    var hasMultipleConversations: Bool {
        allConversations.count > 1
    }

    // MARK: - Initialization

    init(thought: Thought, thoughtService: ThoughtServiceProtocol) {
        self.thought = thought
        self.thoughtService = thoughtService
        self.selectedPersona = personaService.defaultPersona
        self.isPrivate = false
        self.companionService = CompanionConversationService(
            thoughtService: thoughtService,
            semanticSearchService: SemanticSearchService.shared
        )
    }

    // MARK: - Lifecycle

    func initialize() async {
        // Load existing conversations for this thought
        await loadConversations()

        // If we have conversations, load the most recent one
        if let latestConversation = allConversations.sorted(by: { $0.lastActivityTime > $1.lastActivityTime }).first {
            await loadConversation(latestConversation)
        } else {
            // Create a new conversation
            await startNewConversation()
        }
    }

    func loadConversations() async {
        allConversations = await conversationService.getConversations(forThought: thought.id)
    }

    func loadConversation(_ conversation: ThoughtConversation) async {
        currentConversation = conversation
        messages = conversation.messages
        selectedPersona = personaService.getPersona(id: conversation.personaId)
        isPrivate = conversation.isPrivate

        // Start session with existing conversation context
        do {
            try await companionService.startConversation(
                thought: thought,
                persona: selectedPersona,
                isPrivate: isPrivate
            )
        } catch {
            self.error = error
            print("❌ Failed to start conversation: \(error)")
        }
    }

    func startNewConversation() async {
        isLoading = true

        // Create new conversation
        let conversation = await conversationService.createConversation(
            thoughtId: thought.id,
            personaId: selectedPersona.id,
            isPrivate: isPrivate
        )

        currentConversation = conversation
        messages = []

        // Start AI session
        do {
            try await companionService.startConversation(
                thought: thought,
                persona: selectedPersona,
                isPrivate: isPrivate
            )
        } catch {
            self.error = error
            print("❌ Failed to start conversation: \(error)")
        }

        // Reload conversations list
        await loadConversations()

        isLoading = false
    }

    // MARK: - Message Handling

    func sendMessage(_ content: String) async {
        guard let conversation = currentConversation else {
            error = ConversationError.sessionNotInitialized
            return
        }

        // Add user message
        let userMessage = ConversationMessage(
            role: .user,
            content: content
        )
        messages.append(userMessage)

        // Save to conversation
        await conversationService.addMessage(userMessage, toConversation: conversation.id)

        // Set loading state
        isLoading = true
        error = nil

        do {
            // Get AI response
            let response = try await companionService.sendMessage(content)

            // Create assistant message with empty content for streaming
            let assistantMessage = ConversationMessage(
                role: .assistant,
                content: "",
                citations: nil,
                suggestedQuestions: nil
            )
            messages.append(assistantMessage)

            isLoading = false

            // Stream the response character by character
            await streamResponse(response.message, to: assistantMessage.id)

            // Save to conversation with full content (no citations/questions)
            let finalMessage = ConversationMessage(
                role: .assistant,
                content: response.message,
                citations: nil,
                suggestedQuestions: nil
            )
            await conversationService.addMessage(finalMessage, toConversation: conversation.id)

            // Update current conversation reference
            currentConversation = await conversationService.getConversation(id: conversation.id)

        } catch {
            self.error = error
            isLoading = false
            print("❌ Failed to send message: \(error)")
        }
    }

    private func streamResponse(_ fullText: String, to messageId: UUID) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }

        // Stream character by character at faster speed
        var currentText = ""
        for char in fullText {
            currentText.append(char)
            messages[index] = messages[index].settingContent(currentText)

            // Faster delay for better UX (3ms per character, ~200 chars = 0.6 seconds)
            try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000)
        }
    }

    func retry() async {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }

        // Remove the last user message and retry
        if let index = messages.lastIndex(where: { $0.id == lastUserMessage.id }) {
            messages.remove(at: index)
        }

        await sendMessage(lastUserMessage.content)
    }

    // MARK: - Persona Management

    func changePersona(_ persona: SquirrelPersona) async {
        guard let conversation = currentConversation else { return }

        // Save current conversation
        await conversationService.updateConversation(conversation)

        // Create new conversation with new persona
        selectedPersona = persona
        await startNewConversation()
    }

    // MARK: - Privacy Toggle

    func togglePrivacy() async {
        guard let conversation = currentConversation else { return }

        isPrivate.toggle()

        // Update conversation
        let updated = conversation.settingPrivacy(isPrivate)
        await conversationService.updateConversation(updated)
        currentConversation = updated

        // Restart session with new privacy setting
        do {
            try await companionService.startConversation(
                thought: thought,
                persona: selectedPersona,
                isPrivate: isPrivate
            )
        } catch {
            self.error = error
            print("❌ Failed to restart conversation: \(error)")
        }
    }

    // MARK: - Conversation Management

    func switchConversation(_ conversation: ThoughtConversation) async {
        await loadConversation(conversation)
    }

    func deleteConversation(_ conversation: ThoughtConversation) async {
        await conversationService.deleteConversation(id: conversation.id)
        await loadConversations()

        // If we deleted the current conversation, start a new one
        if conversation.id == currentConversation?.id {
            await startNewConversation()
        }
    }

    func renameConversation(_ conversation: ThoughtConversation, title: String) async {
        let updated = conversation.settingTitle(title)
        await conversationService.updateConversation(updated)

        if conversation.id == currentConversation?.id {
            currentConversation = updated
        }

        await loadConversations()
    }
}
