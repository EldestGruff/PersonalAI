//
//  ThoughtAppEntity.swift
//  PersonalAI
//
//  Phase 2: iOS 26 Modernization - App Intents
//  App Entity for thoughts - enables Spotlight, Siri, and Shortcuts integration
//
//  NOTE: Named ThoughtAppEntity to avoid conflict with CoreData's ThoughtAppEntity
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
struct ThoughtAppEntity: AppEntity, Identifiable, Sendable {
    // MARK: - App Entity Protocol

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Thought")
    }

    static let defaultQuery = ThoughtQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: content),
            subtitle: LocalizedStringResource(stringLiteral: subtitle),
            image: image
        )
    }

    // MARK: - Properties

    var id: UUID
    var content: String
    var type: ClassificationType?
    var sentiment: Sentiment?
    var tags: [String]
    var createdAt: Date
    var status: ThoughtStatus

    // MARK: - Display Helpers

    private var subtitle: String {
        let typeString = type?.displayName ?? "thought"
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
        case .none:
            symbolName = "bubble.left.and.bubble.right"
        }
        return .init(systemName: symbolName)
    }

    // MARK: - Conversion

    /// Convert from domain model to App Entity
    init(from thought: Thought) {
        self.id = thought.id
        self.content = thought.content
        self.type = thought.classification?.type
        self.sentiment = thought.classification?.sentiment
        self.tags = thought.tags  // Use thought.tags, not classification.tags
        self.createdAt = thought.createdAt
        self.status = thought.status
    }
}

// MARK: - Thought Query

/// Query provider for finding thoughts in Shortcuts and Siri.
struct ThoughtQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ThoughtAppEntity] {
        // Get thoughts from repository
        let repository = ThoughtRepository.shared
        let thoughts = try await repository.list()

        return thoughts
            .filter { identifiers.contains($0.id) }
            .map { ThoughtAppEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ThoughtAppEntity] {
        // Return recent thoughts for suggestions
        let repository = ThoughtRepository.shared
        let thoughts = try await repository.list()

        return thoughts
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
            .map { ThoughtAppEntity(from: $0) }
    }
}

// MARK: - String Search Query

extension ThoughtQuery: EntityStringQuery {
    @MainActor
    func entities(matching string: String) async throws -> [ThoughtAppEntity] {
        // Search thoughts by content
        let repository = ThoughtRepository.shared
        let thoughts = try await repository.search(string)

        return thoughts
            .sorted { $0.createdAt > $1.createdAt }
            .map { ThoughtAppEntity(from: $0) }
    }
}

