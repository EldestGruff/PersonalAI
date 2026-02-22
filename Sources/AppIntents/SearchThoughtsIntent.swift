//
//  SearchThoughtsIntent.swift
//  STASH
//
//  App Intent for searching thoughts via Siri and Shortcuts
//  "Hey Siri, search my thoughts about meetings"
//

import AppIntents
import Foundation

/// Intent for searching thoughts by keyword or semantic meaning
///
/// **Usage:**
/// - "Hey Siri, search my thoughts about work"
/// - "Hey Siri, find thoughts about the project"
/// - "Hey Siri, show my ideas about SwiftUI"
@available(iOS 26.0, *)
struct SearchThoughtsIntent: AppIntent {
    // MARK: - Intent Metadata

    static let title: LocalizedStringResource = "Search Thoughts"

    static let description = IntentDescription(
        "Search your thoughts by keyword or topic",
        categoryName: "Thoughts",
        searchKeywords: ["find", "search", "look", "filter"]
    )

    static let openAppWhenRun: Bool = true // Open app to show results

    // MARK: - Parameters

    @Parameter(title: "Query", description: "What to search for")
    var query: String

    @Parameter(
        title: "Type Filter",
        description: "Optional: filter by thought type",
        default: nil
    )
    var typeFilter: ThoughtTypeEnum?

    @Parameter(
        title: "Use Semantic Search",
        description: "Search by meaning, not just keywords",
        default: true
    )
    var useSemanticSearch: Bool

    // MARK: - Performance

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ThoughtAppEntity]> & ProvidesDialog {
        AnalyticsService.shared.track(.siriShortcutUsed(intent: "search"))
        // Validate input
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw SearchError.emptyQuery
        }

        // Get repository
        let repository = ThoughtRepository.shared

        // Get all thoughts
        let allThoughts = try await repository.list()

        // Apply type filter if specified
        let filteredByType: [Thought]
        if let typeFilter = typeFilter {
            let targetType = typeFilter.toModel()
            filteredByType = allThoughts.filter { thought in
                thought.classification?.type == targetType
            }
        } else {
            filteredByType = allThoughts
        }

        // Perform search
        let results: [Thought]
        if useSemanticSearch {
            // Use semantic search service
            let semanticSearch = SemanticSearchService.shared
            let searchResults = await semanticSearch.search(query: trimmedQuery, in: filteredByType)
            results = searchResults.map { $0.thought }
        } else {
            // Keyword-based search
            results = filteredByType.filter { thought in
                thought.content.localizedCaseInsensitiveContains(trimmedQuery) ||
                thought.tags.contains { $0.localizedCaseInsensitiveContains(trimmedQuery) }
            }
        }

        // Convert to entities
        let entities = results.map { ThoughtAppEntity(from: $0) }

        // Create dialog
        let dialog: IntentDialog
        if entities.isEmpty {
            dialog = IntentDialog("No thoughts found matching '\(trimmedQuery)'")
        } else {
            let count = entities.count
            dialog = IntentDialog("Found \(count) \(count == 1 ? "thought" : "thoughts") about '\(trimmedQuery)'")
        }

        return .result(
            value: entities,
            dialog: dialog
        )
    }

    // MARK: - Parameterized Shortcuts

    static var parameterSummary: some ParameterSummary {
        Summary("Search thoughts for \(\.$query)") {
            \.$typeFilter
            \.$useSemanticSearch
        }
    }
}

// MARK: - Search Errors

enum SearchError: Error, CustomLocalizedStringResourceConvertible {
    case emptyQuery
    case serviceUnavailable

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyQuery:
            return "Please provide a search query"
        case .serviceUnavailable:
            return "Search service unavailable. Please try again."
        }
    }
}
