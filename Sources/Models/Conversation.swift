//
//  Conversation.swift
//  STASH
//
//  Conversational AI data models for thought exploration
//

import Foundation

// MARK: - Conversation Message

/// A message in a conversation session
struct ConversationMessage: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let citations: [ThoughtCitation]?
    let suggestedQuestions: [String]?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        citations: [ThoughtCitation]? = nil,
        suggestedQuestions: [String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.citations = citations
        self.suggestedQuestions = suggestedQuestions
    }

    /// Create a copy with updated content (for streaming)
    func settingContent(_ newContent: String) -> ConversationMessage {
        ConversationMessage(
            id: id,
            role: role,
            content: newContent,
            timestamp: timestamp,
            citations: citations,
            suggestedQuestions: suggestedQuestions
        )
    }
}

/// Role of a message in the conversation
enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system

    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "AI"
        case .system: return "System"
        }
    }
}

// MARK: - Thought Citation

/// A citation linking to a specific thought
struct ThoughtCitation: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let thoughtId: UUID
    let excerpt: String
    let relevanceScore: Double
    let date: Date
    let tags: [String]

    init(
        id: UUID = UUID(),
        thoughtId: UUID,
        excerpt: String,
        relevanceScore: Double,
        date: Date,
        tags: [String]
    ) {
        self.id = id
        self.thoughtId = thoughtId
        self.excerpt = excerpt
        self.relevanceScore = relevanceScore
        self.date = date
        self.tags = tags
    }
}

// MARK: - Conversation Response

/// Response from the conversational AI
struct ConversationResponse: Sendable {
    let message: String
    let citations: [ThoughtCitation]
    let suggestedQuestions: [String]

    init(
        message: String,
        citations: [ThoughtCitation] = [],
        suggestedQuestions: [String] = []
    ) {
        self.message = message
        self.citations = citations
        self.suggestedQuestions = suggestedQuestions
    }
}

// MARK: - Thought Context

/// Aggregated context about user's thoughts for conversation
struct ThoughtContext: Codable, Sendable {
    let recentThoughts: [ThoughtSummary]
    let dateRange: String
    let topTags: [String: Int]
    let summaryStats: String
    let totalCount: Int

    init(
        recentThoughts: [ThoughtSummary],
        dateRange: String,
        topTags: [String: Int],
        summaryStats: String,
        totalCount: Int
    ) {
        self.recentThoughts = recentThoughts
        self.dateRange = dateRange
        self.topTags = topTags
        self.summaryStats = summaryStats
        self.totalCount = totalCount
    }
}

/// Lightweight thought summary for context
struct ThoughtSummary: Identifiable, Codable, Sendable {
    let id: UUID
    let content: String
    let date: Date
    let tags: [String]
    let sentiment: Double?
    let type: String?

    init(from thought: Thought) {
        self.id = thought.id
        self.content = thought.content
        self.date = thought.createdAt
        self.tags = thought.tags
        self.sentiment = thought.classification?.sentiment.numericalValue
        self.type = thought.classification?.type.rawValue
    }

    init(
        id: UUID,
        content: String,
        date: Date,
        tags: [String],
        sentiment: Double?,
        type: String?
    ) {
        self.id = id
        self.content = content
        self.date = date
        self.tags = tags
        self.sentiment = sentiment
        self.type = type
    }
}

// MARK: - Conversation Session

/// Active conversation session
@Observable
class ConversationSession {
    var messages: [ConversationMessage] = []
    var isLoading: Bool = false
    var error: Error?

    /// Add a message to the session
    func addMessage(_ message: ConversationMessage) {
        messages.append(message)
    }

    /// Clear the conversation
    func clear() {
        messages.removeAll()
        error = nil
    }

    /// Get the last assistant message
    var lastAssistantMessage: ConversationMessage? {
        messages.last(where: { $0.role == .assistant })
    }

    /// Get all user messages
    var userMessages: [ConversationMessage] {
        messages.filter { $0.role == .user }
    }

    /// Get conversation history as string for context
    var historyText: String {
        messages.map { message in
            "\(message.role.displayName): \(message.content)"
        }.joined(separator: "\n")
    }
}

// MARK: - Errors

enum ConversationError: LocalizedError {
    case serviceUnavailable
    case noThoughtsFound
    case sessionNotInitialized
    case generationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Conversational AI is not available on this device"
        case .noThoughtsFound:
            return "No thoughts found to chat about. Capture some thoughts first!"
        case .sessionNotInitialized:
            return "Conversation session not initialized"
        case .generationFailed(let error):
            return "Failed to generate response: \(error.localizedDescription)"
        }
    }
}
