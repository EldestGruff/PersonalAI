//
//  ThoughtEntity.swift
//  PersonalAI
//
//  App Intents entity representation of a Thought
//  Enables Siri, Shortcuts, and Focus Filter integration
//

import AppIntents
import Foundation

/// App Intents representation of a Thought
///
/// Makes thoughts accessible to Siri, Shortcuts, and other system features
@available(iOS 26.0, *)
struct ThoughtEntity: AppEntity {
    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// The thought content
    var content: String

    /// Classification type
    var type: ClassificationType

    /// Tags associated with the thought
    var tags: [String]

    /// When the thought was created
    var createdAt: Date

    /// Sentiment score
    var sentiment: Sentiment

    // MARK: - AppEntity Conformance

    /// Display representation for Siri and system UI
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(LocalizedStringResource(stringLiteral: content.prefix(60).trimmingCharacters(in: .whitespacesAndNewlines)))",
            subtitle: "\(type.rawValue.capitalized) • \(createdAt.formatted(.relative(presentation: .named)))",
            image: DisplayRepresentation.Image(systemName: type.iconName)
        )
    }

    /// Entity type name
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Thought")
    }

    /// Default query for finding thoughts
    static var defaultQuery = ThoughtEntityQuery()

    // MARK: - Initialization

    init(id: UUID, content: String, type: ClassificationType, tags: [String], createdAt: Date, sentiment: Sentiment) {
        self.id = id
        self.content = content
        self.type = type
        self.tags = tags
        self.createdAt = createdAt
        self.sentiment = sentiment
    }

    /// Initialize from domain model
    init(from thought: Thought) {
        self.id = thought.id
        self.content = thought.content
        self.type = thought.classification?.type ?? .note
        self.tags = thought.tags
        self.createdAt = thought.createdAt
        self.sentiment = thought.classification?.sentiment ?? .neutral
    }
}

// MARK: - Entity Query

/// Query implementation for finding thoughts
@available(iOS 26.0, *)
struct ThoughtEntityQuery: EntityQuery {

    /// Find thoughts matching a string query
    func entities(matching string: String) async throws -> [ThoughtEntity] {
        // Use ThoughtRepository directly
        let repository = ThoughtRepository.shared

        // Search thoughts by content
        let thoughts = try await repository.fetchAll()

        let filtered = thoughts.filter { thought in
            thought.content.localizedCaseInsensitiveContains(string) ||
            thought.tags.contains { $0.localizedCaseInsensitiveContains(string) }
        }

        return filtered.map { ThoughtEntity(from: $0) }
    }

    /// Find a specific thought by ID
    func entities(for identifiers: [UUID]) async throws -> [ThoughtEntity] {
        let repository = ThoughtRepository.shared

        var result: [ThoughtEntity] = []

        for id in identifiers {
            if let thought = try? await repository.fetch(id) {
                result.append(ThoughtEntity(from: thought))
            }
        }

        return result
    }

    /// Suggested thoughts (for disambiguation)
    func suggestedEntities() async throws -> [ThoughtEntity] {
        let repository = ThoughtRepository.shared

        // Return recent thoughts (last 10)
        let thoughts = try await repository.fetchAll()
        let recent = thoughts.sorted { $0.createdAt > $1.createdAt }.prefix(10)

        return recent.map { ThoughtEntity(from: $0) }
    }
}

// MARK: - Classification Type Extensions

extension ClassificationType {
    /// SF Symbol icon name for this type
    var iconName: String {
        switch self {
        case .note:
            return "note.text"
        case .idea:
            return "lightbulb"
        case .reminder:
            return "bell"
        case .event:
            return "calendar"
        case .question:
            return "questionmark.circle"
        }
    }
}
