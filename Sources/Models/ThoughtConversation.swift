//
//  ThoughtConversation.swift
//  STASH
//
//  Thought-specific conversation models for companion mode
//

import Foundation

// MARK: - Thought Conversation

/// A conversation attached to a specific thought
struct ThoughtConversation: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let thoughtId: UUID
    let personaId: UUID
    let messages: [ConversationMessage]
    let isPrivate: Bool // "Personal Server" mode - no access to other thoughts
    let title: String // Auto-generated or user-set
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        thoughtId: UUID,
        personaId: UUID,
        messages: [ConversationMessage] = [],
        isPrivate: Bool = false,
        title: String = "Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.thoughtId = thoughtId
        self.personaId = personaId
        self.messages = messages
        self.isPrivate = isPrivate
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Total message count
    var messageCount: Int {
        messages.count
    }

    /// Last message
    var lastMessage: ConversationMessage? {
        messages.last
    }

    /// Last activity time
    var lastActivityTime: Date {
        lastMessage?.timestamp ?? updatedAt
    }

    /// Privacy mode description
    var privacyDescription: String {
        isPrivate ? "🔒 Private conversation" : "🌐 Connected conversation"
    }

    /// Add a message
    func addingMessage(_ message: ConversationMessage) -> ThoughtConversation {
        ThoughtConversation(
            id: id,
            thoughtId: thoughtId,
            personaId: personaId,
            messages: messages + [message],
            isPrivate: isPrivate,
            title: title,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Update privacy mode
    func settingPrivacy(_ isPrivate: Bool) -> ThoughtConversation {
        ThoughtConversation(
            id: id,
            thoughtId: thoughtId,
            personaId: personaId,
            messages: messages,
            isPrivate: isPrivate,
            title: title,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Update title
    func settingTitle(_ title: String) -> ThoughtConversation {
        ThoughtConversation(
            id: id,
            thoughtId: thoughtId,
            personaId: personaId,
            messages: messages,
            isPrivate: isPrivate,
            title: title,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Conversation Service

/// Service for managing thought conversations
actor ThoughtConversationService {
    static let shared = ThoughtConversationService()

    private var conversations: [UUID: [ThoughtConversation]] = [:] // thoughtId -> conversations
    private let persistenceKey = "thought_conversations"

    init() {
        _Concurrency.Task {
            await loadConversations()
        }
    }

    // MARK: - Conversation Management

    /// Get all conversations for a thought
    func getConversations(forThought thoughtId: UUID) -> [ThoughtConversation] {
        conversations[thoughtId] ?? []
    }

    /// Get a specific conversation
    func getConversation(id: UUID) -> ThoughtConversation? {
        conversations.values
            .flatMap { $0 }
            .first { $0.id == id }
    }

    /// Create new conversation
    func createConversation(
        thoughtId: UUID,
        personaId: UUID,
        isPrivate: Bool = false
    ) async -> ThoughtConversation {
        let title = await generateTitle(personaId: personaId)
        let conversation = ThoughtConversation(
            thoughtId: thoughtId,
            personaId: personaId,
            isPrivate: isPrivate,
            title: title
        )

        var thoughtConvos = conversations[thoughtId] ?? []
        thoughtConvos.append(conversation)
        conversations[thoughtId] = thoughtConvos

        saveConversations()

        return conversation
    }

    /// Update conversation
    func updateConversation(_ conversation: ThoughtConversation) {
        guard var thoughtConvos = conversations[conversation.thoughtId] else { return }

        if let index = thoughtConvos.firstIndex(where: { $0.id == conversation.id }) {
            thoughtConvos[index] = conversation
            conversations[conversation.thoughtId] = thoughtConvos

            saveConversations()
        }
    }

    /// Delete conversation
    func deleteConversation(id: UUID) {
        for (thoughtId, convos) in conversations {
            var updatedConvos = convos
            updatedConvos.removeAll { $0.id == id }

            if updatedConvos.isEmpty {
                conversations.removeValue(forKey: thoughtId)
            } else {
                conversations[thoughtId] = updatedConvos
            }
        }

        saveConversations()
    }

    /// Add message to conversation
    func addMessage(
        _ message: ConversationMessage,
        toConversation conversationId: UUID
    ) {
        guard let conversation = getConversation(id: conversationId) else { return }
        let updated = conversation.addingMessage(message)
        updateConversation(updated)
    }

    // MARK: - Helpers

    private func generateTitle(personaId: UUID) async -> String {
        let persona = await MainActor.run {
            PersonaService.shared.getPersona(id: personaId)
        }
        return "\(persona.emoji) \(persona.name)"
    }

    // MARK: - Persistence

    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }

        do {
            let allConversations = try JSONDecoder().decode([ThoughtConversation].self, from: data)

            // Group by thoughtId
            conversations = Dictionary(grouping: allConversations) { $0.thoughtId }

            AppLogger.services.info("Loaded \(allConversations.count) thought conversations")
        } catch {
            AppLogger.services.error("Failed to load thought conversations: \(error)")
        }
    }

    private func saveConversations() {
        let allConversations = conversations.values.flatMap { $0 }

        do {
            let data = try JSONEncoder().encode(allConversations)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            AppLogger.services.error("Failed to save thought conversations: \(error)")
        }
    }
}

// MARK: - Thought Extension

extension Thought {
    /// Whether this thought has any conversations
    var hasConversations: Bool {
        !conversations.isEmpty
    }

    /// Conversations for this thought (loaded from service)
    var conversations: [ThoughtConversation] {
        // Note: This is a synchronous computed property, but the service is async
        // In practice, conversations should be loaded via the service in ViewModels
        // This is here for convenience in UI contexts
        []
    }

    /// Conversation count badge
    var conversationCount: Int {
        conversations.count
    }
}
