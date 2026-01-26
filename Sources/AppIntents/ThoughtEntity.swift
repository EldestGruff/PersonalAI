//
//  ThoughtEntity.swift
//  PersonalAI
//
//  Phase 2: iOS 26 Modernization - App Intents
//  App Entity for thoughts - enables Spotlight, Siri, and Shortcuts integration
//

import AppIntents
import Foundation

/// App Entity representing a thought for use in Shortcuts and Siri.
///
/// Enables:
/// - Spotlight search for thoughts
/// - Siri queries ("Show my thoughts about...")
/// - Shortcuts automation
/// - Focus Filter integration
struct ThoughtEntity: AppEntity, Identifiable, Sendable {
    // MARK: - App Entity Protocol

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Thought")
    }

    static var defaultQuery = ThoughtQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(content)",
            subtitle: subtitle,
            image: image
        )
    }

    // MARK: - Properties

    var id: UUID
    var content: String
    var type: ClassificationType
    var sentiment: Sentiment
    var tags: [String]
    var createdAt: Date
    var isCompleted: Bool

    // MARK: - Display Helpers

    private var subtitle: String {
        let typeString = type.displayName
        let dateString = createdAt.formatted(date: .abbreviated, time: .omitted)
        return "\(typeString) • \(dateString)"
    }

    private var image: DisplayRepresentation.Image? {
        let symbolName: String
        switch type {
        case .reminder:
            symbolName = "checkmark.circle"
        case .event:
            symbolName = "calendar"
        case .note:
            symbolName = "note.text"
        case .question:
            symbolName = "questionmark.circle"
        case .idea:
            symbolName = "lightbulb"
        }
        return .init(systemName: symbolName)
    }

    // MARK: - Conversion

    /// Convert from domain model to App Entity
    init(from thought: Thought) {
        self.id = thought.id
        self.content = thought.content
        self.type = thought.classification.type
        self.sentiment = thought.classification.sentiment
        self.tags = thought.classification.tags
        self.createdAt = thought.createdAt
        self.isCompleted = thought.isCompleted
    }
}

// MARK: - Thought Query

/// Query provider for finding thoughts in Shortcuts and Siri.
struct ThoughtQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ThoughtEntity] {
        // Get thoughts from repository
        let container = await ServiceContainer.shared
        guard let repository = await container.resolveOptional(ThoughtRepositoryProtocol.self) else {
            return []
        }

        let thoughts = try await repository.fetchAll()
        return thoughts
            .filter { identifiers.contains($0.id) }
            .map { ThoughtEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [ThoughtEntity] {
        // Return recent thoughts for suggestions
        let container = await ServiceContainer.shared
        guard let repository = await container.resolveOptional(ThoughtRepositoryProtocol.self) else {
            return []
        }

        let thoughts = try await repository.fetchAll()
        return thoughts
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
            .map { ThoughtEntity(from: $0) }
    }
}

// MARK: - String Search Query

extension ThoughtQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [ThoughtEntity] {
        // Search thoughts by content
        let container = await ServiceContainer.shared
        guard let repository = await container.resolveOptional(ThoughtRepositoryProtocol.self) else {
            return []
        }

        let thoughts = try await repository.fetchAll()
        let searchLower = string.lowercased()

        return thoughts
            .filter { thought in
                thought.content.lowercased().contains(searchLower) ||
                thought.classification.tags.contains { $0.lowercased().contains(searchLower) }
            }
            .sorted { $0.createdAt > $1.createdAt }
            .map { ThoughtEntity(from: $0) }
    }
}

// MARK: - Type Enum for Intent Parameters

/// Classification type enum for use in App Intent parameters.
enum ThoughtTypeEnum: String, AppEnum, Sendable {
    case note
    case reminder
    case event
    case question
    case idea

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Thought Type")
    }

    static var caseDisplayRepresentations: [ThoughtTypeEnum: DisplayRepresentation] {
        [
            .note: DisplayRepresentation(
                title: "Note",
                image: .init(systemName: "note.text")
            ),
            .reminder: DisplayRepresentation(
                title: "Reminder",
                image: .init(systemName: "checkmark.circle")
            ),
            .event: DisplayRepresentation(
                title: "Event",
                image: .init(systemName: "calendar")
            ),
            .question: DisplayRepresentation(
                title: "Question",
                image: .init(systemName: "questionmark.circle")
            ),
            .idea: DisplayRepresentation(
                title: "Idea",
                image: .init(systemName: "lightbulb")
            )
        ]
    }

    /// Convert to domain model type
    func toModel() -> ClassificationType {
        switch self {
        case .note: return .note
        case .reminder: return .reminder
        case .event: return .event
        case .question: return .question
        case .idea: return .idea
        }
    }

    /// Convert from domain model type
    static func from(_ type: ClassificationType) -> ThoughtTypeEnum {
        switch type {
        case .note: return .note
        case .reminder: return .reminder
        case .event: return .event
        case .question: return .question
        case .idea: return .idea
        }
    }
}
