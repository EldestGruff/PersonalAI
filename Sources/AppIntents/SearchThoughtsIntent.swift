//
//  SearchThoughtsIntent.swift
//  PersonalAI
//
//  Phase 2: iOS 26 Modernization - App Intents
//  Search and filter thoughts via Siri and Shortcuts
//

import AppIntents
import Foundation

/// App Intent for searching thoughts with filters.
///
/// ## Usage Examples
///
/// **Siri:**
/// - "Hey Siri, find thoughts about work"
/// - "Hey Siri, show my ideas from this week"
/// - "Hey Siri, what did I capture yesterday?"
///
/// **Shortcuts:**
/// - Advanced search automation
/// - Daily/weekly summaries
/// - Export filtered thoughts
///
/// ## Features
///
/// - Natural language search
/// - Filter by type, sentiment, date range
/// - Sort by date or relevance
/// - Returns thought entities for further processing
struct SearchThoughtsIntent: AppIntent {
    // MARK: - Intent Metadata

    static let title: LocalizedStringResource = "Search Thoughts"

    static let description = IntentDescription(
        "Find thoughts matching specific criteria",
        categoryName: "Search",
        searchKeywords: ["find", "search", "filter", "query", "look for"]
    )

    static let openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(
        title: "Search Query",
        description: "Keywords to search for",
        inputOptions: .init(capitalizationType: .sentences)
    )
    var query: String?

    @Parameter(
        title: "Type Filter",
        description: "Filter by thought type (optional)"
    )
    var typeFilter: ThoughtTypeEnum?

    @Parameter(
        title: "Date Range",
        description: "Filter by time period"
    )
    var dateRange: DateRangeEnum?

    @Parameter(
        title: "Max Results",
        description: "Maximum number of results to return",
        default: 20,
        controlStyle: .field,
        inclusiveRange: (1, 100)
    )
    var maxResults: Int

    // MARK: - Intent Execution

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ThoughtAppEntity]> {
        // Get repository
        let container = ServiceContainer.shared
        guard let repository = await container.resolveOptional(any ThoughtRepositoryProtocol.Type) as? any ThoughtRepositoryProtocol else {
            throw IntentError.serviceUnavailable
        }

        // Fetch all thoughts
        var thoughts = try await repository.fetchAll()

        // Apply filters
        thoughts = applyFilters(to: thoughts)

        // Convert to entities
        let entities = thoughts
            .prefix(maxResults)
            .map { ThoughtAppEntity(from: $0) }

        // Return results
        let count = entities.count
        let typeString = typeFilter?.rawValue.capitalized ?? "any type"
        let dialog = count == 0
            ? "No thoughts found matching your criteria"
            : "Found \(count) thought\(count == 1 ? "" : "s") of type \(typeString)"

        return .result(
            value: Array(entities),
            dialog: dialog
        )
    }

    // MARK: - Filtering Logic

    private func applyFilters(to thoughts: [Thought]) -> [Thought] {
        var filtered = thoughts

        // Filter by search query
        if let query = query, !query.isEmpty {
            let searchLower = query.lowercased()
            filtered = filtered.filter { thought in
                thought.content.lowercased().contains(searchLower) ||
                thought.tags.contains { $0.lowercased().contains(searchLower) }
            }
        }

        // Filter by type
        if let typeFilter = typeFilter {
            filtered = filtered.filter { $0.classification?.type == typeFilter.toModel() }
        }

        // Filter by date range
        if let dateRange = dateRange {
            let now = Date()
            let calendar = Calendar.current

            filtered = filtered.filter { thought in
                switch dateRange {
                case .today:
                    return calendar.isDateInToday(thought.createdAt)
                case .yesterday:
                    return calendar.isDateInYesterday(thought.createdAt)
                case .thisWeek:
                    return thought.createdAt >= calendar.startOfWeek(for: now)
                case .lastWeek:
                    let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.startOfWeek(for: now))!
                    let thisWeekStart = calendar.startOfWeek(for: now)
                    return thought.createdAt >= lastWeekStart && thought.createdAt < thisWeekStart
                case .thisMonth:
                    let components = calendar.dateComponents([.year, .month], from: now)
                    let monthStart = calendar.date(from: components)!
                    return thought.createdAt >= monthStart
                case .lastMonth:
                    let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now)!
                    let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastMonthDate)
                    let lastMonthStart = calendar.date(from: lastMonthComponents)!
                    let thisMonthComponents = calendar.dateComponents([.year, .month], from: now)
                    let thisMonthStart = calendar.date(from: thisMonthComponents)!
                    return thought.createdAt >= lastMonthStart && thought.createdAt < thisMonthStart
                }
            }
        }

        // Sort by date (newest first)
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Date Range Enum

enum DateRangeEnum: String, AppEnum, Sendable {
    case today
    case yesterday
    case thisWeek = "this week"
    case lastWeek = "last week"
    case thisMonth = "this month"
    case lastMonth = "last month"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Date Range")
    }

    static var caseDisplayRepresentations: [DateRangeEnum: DisplayRepresentation] {
        [
            .today: "Today",
            .yesterday: "Yesterday",
            .thisWeek: "This Week",
            .lastWeek: "Last Week",
            .thisMonth: "This Month",
            .lastMonth: "Last Month"
        ]
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
}
