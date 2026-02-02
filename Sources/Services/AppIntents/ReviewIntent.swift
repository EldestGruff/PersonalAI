//
//  ReviewIntent.swift
//  PersonalAI
//
//  App Intent for reviewing thoughts from a time period
//  "Hey Siri, review my thoughts from today"
//

import AppIntents
import Foundation

/// Intent for reviewing thoughts from a specific time period
///
/// **Usage:**
/// - "Hey Siri, review my thoughts from today"
/// - "Hey Siri, show this week's thoughts"
/// - "Hey Siri, what did I think about yesterday?"
@available(iOS 26.0, *)
struct ReviewIntent: AppIntent {
    // MARK: - Intent Metadata

    static var title: LocalizedStringResource = "Review Thoughts"

    static var description = IntentDescription(
        "Review your thoughts from a specific time period",
        categoryName: "Thoughts",
        searchKeywords: ["review", "show", "recent", "today", "week"]
    )

    static var openAppWhenRun: Bool = true // Open app to show results

    // MARK: - Parameters

    @Parameter(
        title: "Time Period",
        description: "Which time period to review",
        default: .today
    )
    var timePeriod: TimePeriodEnum

    @Parameter(
        title: "Type Filter",
        description: "Optional: filter by thought type",
        default: nil
    )
    var typeFilter: ThoughtTypeEnum?

    // MARK: - Performance

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ThoughtEntity]> & ProvidesDialog {
        // Get repository
        let repository = ThoughtRepository.shared

        // Get all thoughts
        let allThoughts = try await repository.fetchAll()

        // Calculate date range
        let calendar = Calendar.current
        let now = Date()
        let dateRange: (start: Date, end: Date)

        switch timePeriod {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            dateRange = (startOfDay, now)

        case .yesterday:
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            let endOfYesterday = calendar.startOfDay(for: now)
            dateRange = (startOfYesterday, endOfYesterday)

        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            dateRange = (startOfWeek, now)

        case .lastWeek:
            let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek)!
            dateRange = (startOfLastWeek, startOfThisWeek)

        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            dateRange = (startOfMonth, now)

        case .lastSevenDays:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            dateRange = (sevenDaysAgo, now)
        }

        // Filter by date range
        var results = allThoughts.filter { thought in
            thought.createdAt >= dateRange.start && thought.createdAt <= dateRange.end
        }

        // Apply type filter if specified
        if let typeFilter = typeFilter {
            let targetType = typeFilter.toModel()
            results = results.filter { thought in
                thought.classification?.type == targetType
            }
        }

        // Sort by most recent first
        results.sort { $0.createdAt > $1.createdAt }

        // Convert to entities
        let entities = results.map { ThoughtEntity(from: $0) }

        // Create dialog
        let periodName = timePeriod.displayName
        let dialog: IntentDialog
        if entities.isEmpty {
            dialog = IntentDialog("No thoughts from \(periodName)")
        } else {
            let count = entities.count
            let typeString = typeFilter?.rawValue.capitalized ?? "thought"
            dialog = IntentDialog("Found \(count) \(typeString)\(count == 1 ? "" : "s") from \(periodName)")
        }

        return .result(
            value: entities,
            dialog: dialog
        )
    }

    // MARK: - Parameterized Shortcuts

    static var parameterSummary: some ParameterSummary {
        Summary("Review thoughts from \(\.$timePeriod)") {
            \.$typeFilter
        }
    }
}

// MARK: - Time Period Enum

@available(iOS 26.0, *)
enum TimePeriodEnum: String, AppEnum {
    case today
    case yesterday
    case thisWeek = "this_week"
    case lastWeek = "last_week"
    case thisMonth = "this_month"
    case lastSevenDays = "last_seven_days"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Time Period")
    }

    static var caseDisplayRepresentations: [TimePeriodEnum: DisplayRepresentation] {
        [
            .today: "Today",
            .yesterday: "Yesterday",
            .thisWeek: "This Week",
            .lastWeek: "Last Week",
            .thisMonth: "This Month",
            .lastSevenDays: "Last 7 Days"
        ]
    }

    var displayName: String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case .thisWeek: return "this week"
        case .lastWeek: return "last week"
        case .thisMonth: return "this month"
        case .lastSevenDays: return "the last 7 days"
        }
    }
}
