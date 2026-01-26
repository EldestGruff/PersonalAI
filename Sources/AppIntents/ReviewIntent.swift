//
//  ReviewIntent.swift
//  PersonalAI
//
//  Phase 2: iOS 26 Modernization - App Intents
//  Review thoughts with specific filters
//

import AppIntents
import Foundation

/// App Intent for reviewing thoughts.
///
/// ## Usage Examples
///
/// **Siri:**
/// - "Hey Siri, review my thoughts from today"
/// - "Hey Siri, show my recent reminders"
/// - "Hey Siri, what ideas did I have this week?"
///
/// **Shortcuts:**
/// - Morning review routine
/// - Weekly summary
/// - Daily standup preparation
///
/// ## Features
///
/// - Opens app with filtered view
/// - Configurable filters (type, date range)
/// - Dialog summary of what will be shown
struct ReviewIntent: AppIntent {
    // MARK: - Intent Metadata

    static let title: LocalizedStringResource = "Review Thoughts"

    static let description = IntentDescription(
        "Review thoughts with optional filters",
        categoryName: "Review",
        searchKeywords: ["review", "show", "display", "view", "check"]
    )

    static let openAppWhenRun: Bool = true // Opens app for review

    // MARK: - Parameters

    @Parameter(
        title: "Type Filter",
        description: "Show only specific type of thoughts"
    )
    var typeFilter: ThoughtTypeEnum?

    @Parameter(
        title: "Date Range",
        description: "Time period to review"
    )
    var dateRange: DateRangeEnum?

    @Parameter(
        title: "Show Completed",
        description: "Include completed thoughts and tasks",
        default: false
    )
    var showCompleted: Bool

    // MARK: - Intent Execution

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & OpensIntent {
        // Get repository for count
        let container = ServiceContainer.shared
        guard let repository = await container.resolveOptional(any ThoughtRepositoryProtocol.Type) as? any ThoughtRepositoryProtocol else {
            throw IntentError.serviceUnavailable
        }

        // Get count for dialog
        var thoughts = try await repository.fetchAll()

        // Apply filters (same logic as SearchIntent)
        thoughts = applyFilters(to: thoughts)

        let count = thoughts.count
        let typeString = typeFilter?.rawValue.capitalized ?? "thoughts"
        let dateString = dateRange?.rawValue ?? "all time"
        let dialog = "Showing \(count) \(typeString) from \(dateString)"

        // Return result that opens app
        // App will use URL scheme or notification to show filtered view
        return .result(dialog: dialog)
    }

    // MARK: - Filtering Logic

    private func applyFilters(to thoughts: [Thought]) -> [Thought] {
        var filtered = thoughts

        // Filter by completion status
        if !showCompleted {
            // Filter out completed thoughts based on status
            filtered = filtered.filter { $0.status != .completed }
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

        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
}
