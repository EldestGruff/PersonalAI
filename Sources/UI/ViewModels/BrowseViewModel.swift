//
//  BrowseViewModel.swift
//  STASH
//
//  Phase 3A Spec 3: Browse & List ViewModel
//  Manages state for browsing and filtering thoughts
//

import Foundation
import Observation

// MARK: - Sort Types

/// Fields available for sorting thoughts
enum SortField: String, CaseIterable, Sendable {
    case createdAt = "Created"
    case updatedAt = "Updated"
}

/// Sort order direction
enum SortOrder: String, CaseIterable, Sendable {
    case ascending = "Oldest First"
    case descending = "Newest First"

    var symbol: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

// MARK: - Date Range Filter (Issue #4)

/// Predefined date range options for filtering
enum DateRangeFilter: String, CaseIterable, Sendable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case custom = "Custom"

    /// Calculates the start date for this range
    func startDate(from now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .all:
            return nil
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            return calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components)
        case .custom:
            return nil // Handled by custom date properties
        }
    }
}

// MARK: - Browse ViewModel

/// ViewModel for the browse/list screen.
///
/// Manages:
/// - Loading and displaying thoughts
/// - Filtering by status, tags, search text, date range, type, and sentiment
/// - Sorting
/// - Selection for detail view
/// - Archive and delete actions
/// - Bulk selection and actions (Issue #5)
@Observable
@MainActor
final class BrowseViewModel {
    // MARK: - Display State

    /// List of thoughts to display
    var thoughts: [Thought] = []

    /// Whether thoughts are currently loading
    var isLoading: Bool = false

    /// Current error to display
    var error: AppError?

    /// A randomly selected shiny thought to surface as "Today's Shiny"
    var todaysShiny: Thought?

    // MARK: - Filter State

    /// Filter by thought status
    var filterStatus: ThoughtStatus? = .active

    /// Filter by tags (empty = no tag filter)
    var selectedFilterTags: [String] = []

    // MARK: - Search & Advanced Filters (Issue #4)

    /// Text search query (case-insensitive)
    var searchText: String = ""

    /// Date range filter preset
    var dateRangeFilter: DateRangeFilter = .all

    /// Custom start date (when dateRangeFilter is .custom)
    var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

    /// Custom end date (when dateRangeFilter is .custom)
    var customEndDate: Date = Date()

    /// Filter by classification type (nil = all types)
    var filterType: ClassificationType?

    /// Filter by sentiment (nil = all sentiments)
    var filterSentiment: Sentiment?

    // MARK: - Sorting

    /// Field to sort by
    var sortBy: SortField = .createdAt

    /// Sort order
    var sortOrder: SortOrder = .descending

    // MARK: - Selection

    /// Currently selected thought for detail view
    var selectedThought: Thought?

    /// Whether to show the detail view
    var showDetail: Bool = false

    // MARK: - Bulk Selection State (Issue #5)

    /// Whether edit/multi-select mode is active
    var isEditMode: Bool = false

    /// Set of selected thought IDs for bulk actions
    var selectedThoughtIds: Set<UUID> = []

    /// Whether to show the bulk tag addition sheet
    var showBulkTagSheet: Bool = false

    /// Whether to show delete confirmation for bulk delete
    var showBulkDeleteConfirmation: Bool = false

    // MARK: - Services

    let thoughtService: ThoughtService
    let fineTuningService: FineTuningService

    // MARK: - Initialization

    init(
        thoughtService: ThoughtService,
        fineTuningService: FineTuningService
    ) {
        self.thoughtService = thoughtService
        self.fineTuningService = fineTuningService
    }

    // MARK: - Loading

    /// Loads thoughts with current filter/sort settings
    func loadThoughts() async {
        isLoading = true
        error = nil

        do {
            // Build filter based on status
            let filter: ThoughtFilter? = filterStatus.map { ThoughtFilter.byStatus($0) }

            // Fetch from service
            var results = try await thoughtService.list(filter: filter)

            // Apply all filters (Issue #4: Advanced filtering)
            results = applyFilters(to: results)

            // Sort locally
            results = sortThoughts(results)

            self.thoughts = results

            // Promote shinies (throttled to once/day) then pick one to surface
            let allActive = try await thoughtService.list(filter: .active)
            let promoted = await ShinyService.shared.promoteShiniesIfNeeded(
                from: allActive,
                thoughtService: thoughtService
            )
            // Reload if we promoted new shinies so isShiny flags are fresh
            if !promoted.isEmpty {
                let refreshed = try await thoughtService.list(filter: .active)
                self.thoughts = applyFilters(to: sortThoughts(refreshed))
            }

            let shinies = ShinyService.shared.currentShinies(from: self.thoughts)
            self.todaysShiny = shinies.randomElement()
            if todaysShiny != nil {
                AnalyticsService.shared.track(.shinySurfaced)
            }

        } catch {
            self.error = AppError.from(error)
        }

        isLoading = false
    }

    // MARK: - Filter Application (Issue #4)

    /// Applies all active filters to the thought list
    private func applyFilters(to thoughts: [Thought]) -> [Thought] {
        var results = thoughts

        // Text search filter (case-insensitive)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter { thought in
                thought.content.lowercased().contains(query)
            }
        }

        // Tag filter
        if !selectedFilterTags.isEmpty {
            results = results.filter { thought in
                selectedFilterTags.allSatisfy { thought.tags.contains($0) }
            }
        }

        // Date range filter
        if let startDate = effectiveStartDate {
            results = results.filter { $0.createdAt >= startDate }
        }
        if let endDate = effectiveEndDate {
            // Include the full end day
            let calendar = Calendar.current
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
            results = results.filter { $0.createdAt < endOfDay }
        }

        // Classification type filter
        if let filterType = filterType {
            results = results.filter { thought in
                thought.classification?.type == filterType
            }
        }

        // Sentiment filter
        if let filterSentiment = filterSentiment {
            results = results.filter { thought in
                thought.classification?.sentiment == filterSentiment
            }
        }

        return results
    }

    /// Effective start date based on date range filter setting
    private var effectiveStartDate: Date? {
        switch dateRangeFilter {
        case .custom:
            return customStartDate
        default:
            return dateRangeFilter.startDate()
        }
    }

    /// Effective end date based on date range filter setting
    private var effectiveEndDate: Date? {
        switch dateRangeFilter {
        case .all:
            return nil
        case .custom:
            return customEndDate
        default:
            return Date()
        }
    }

    /// Refreshes the thought list
    func refresh() {
        _Concurrency.Task {
            await loadThoughts()
        }
    }

    // MARK: - Filtering

    /// Sets the status filter and reloads
    func setFilterStatus(_ status: ThoughtStatus?) {
        filterStatus = status
        refresh()
    }

    /// Toggles a tag in the filter
    func toggleFilterTag(_ tag: String) {
        if selectedFilterTags.contains(tag) {
            selectedFilterTags.removeAll { $0 == tag }
        } else {
            selectedFilterTags.append(tag)
        }
        refresh()
    }

    /// Clears all filters
    func clearFilters() {
        filterStatus = nil
        selectedFilterTags = []
        searchText = ""
        dateRangeFilter = .all
        filterType = nil
        filterSentiment = nil
        refresh()
    }

    // MARK: - Search (Issue #4)

    /// Sets the search text and reloads
    func setSearchText(_ text: String) {
        searchText = text
        refresh()
    }

    // MARK: - Date Range Filter (Issue #4)

    /// Sets the date range filter and reloads
    func setDateRangeFilter(_ range: DateRangeFilter) {
        dateRangeFilter = range
        refresh()
    }

    /// Sets custom date range and reloads
    func setCustomDateRange(start: Date, end: Date) {
        dateRangeFilter = .custom
        customStartDate = start
        customEndDate = end
        refresh()
    }

    // MARK: - Type Filter (Issue #4)

    /// Sets the classification type filter and reloads
    func setTypeFilter(_ type: ClassificationType?) {
        filterType = type
        refresh()
    }

    // MARK: - Sentiment Filter (Issue #4)

    /// Sets the sentiment filter and reloads
    func setSentimentFilter(_ sentiment: Sentiment?) {
        filterSentiment = sentiment
        refresh()
    }

    // MARK: - Sorting

    /// Sets the sort field and reloads
    func setSortField(_ field: SortField) {
        sortBy = field
        thoughts = sortThoughts(thoughts)
    }

    /// Toggles sort order
    func toggleSortOrder() {
        sortOrder = sortOrder == .ascending ? .descending : .ascending
        thoughts = sortThoughts(thoughts)
    }

    private func sortThoughts(_ thoughts: [Thought]) -> [Thought] {
        thoughts.sorted { lhs, rhs in
            let comparison: Bool
            switch sortBy {
            case .createdAt:
                comparison = lhs.createdAt < rhs.createdAt
            case .updatedAt:
                comparison = lhs.updatedAt < rhs.updatedAt
            }
            return sortOrder == .ascending ? comparison : !comparison
        }
    }

    // MARK: - Selection

    /// Selects a thought and shows detail view
    func selectThought(_ thought: Thought) {
        selectedThought = thought
        showDetail = true

        // Track view for fine-tuning (fire and forget)
        _Concurrency.Task {
            try? await fineTuningService.trackViewed(thought.id)
        }
    }

    /// Deselects and hides detail view
    func deselectThought() {
        selectedThought = nil
        showDetail = false
    }

    // MARK: - Actions

    /// Archives a thought
    func archiveThought(_ thought: Thought) {
        _Concurrency.Task {
            do {
                try await thoughtService.archive([thought.id])
                AnalyticsService.shared.track(.thoughtArchived)
                await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }

    /// Unarchives a thought
    func unarchiveThought(_ thought: Thought) {
        _Concurrency.Task {
            do {
                try await thoughtService.unarchive([thought.id])
                await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }

    /// Deletes a thought
    func deleteThought(_ thought: Thought) {
        _Concurrency.Task {
            do {
                try await thoughtService.delete(thought.id)
                AnalyticsService.shared.track(.thoughtDeleted)
                await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }

    // MARK: - Bulk Selection Actions (Issue #5)

    /// Toggles edit/multi-select mode
    func toggleEditMode() {
        isEditMode.toggle()
        if !isEditMode {
            selectedThoughtIds.removeAll()
        }
    }

    /// Exits edit mode
    func exitEditMode() {
        isEditMode = false
        selectedThoughtIds.removeAll()
    }

    /// Toggles selection of a thought
    func toggleSelection(_ thought: Thought) {
        if selectedThoughtIds.contains(thought.id) {
            selectedThoughtIds.remove(thought.id)
        } else {
            selectedThoughtIds.insert(thought.id)
        }
    }

    /// Selects all visible thoughts
    func selectAll() {
        selectedThoughtIds = Set(thoughts.map { $0.id })
    }

    /// Deselects all thoughts
    func deselectAll() {
        selectedThoughtIds.removeAll()
    }

    /// Whether a thought is selected
    func isSelected(_ thought: Thought) -> Bool {
        selectedThoughtIds.contains(thought.id)
    }

    /// Archives all selected thoughts
    func archiveSelected() {
        let ids = Array(selectedThoughtIds)
        guard !ids.isEmpty else { return }

        _Concurrency.Task {
            do {
                try await thoughtService.archive(ids)
                AnalyticsService.shared.track(.thoughtArchived)
                selectedThoughtIds.removeAll()
                isEditMode = false
                await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }

    /// Deletes all selected thoughts (requires confirmation)
    func deleteSelected() {
        let ids = Array(selectedThoughtIds)
        guard !ids.isEmpty else { return }

        _Concurrency.Task {
            do {
                try await thoughtService.bulkDelete(ids)
                AnalyticsService.shared.track(.thoughtDeleted)
                selectedThoughtIds.removeAll()
                isEditMode = false
                await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }

    /// Adds tags to all selected thoughts
    func addTagsToSelected(_ tags: [String]) {
        let ids = Array(selectedThoughtIds)
        guard !ids.isEmpty, !tags.isEmpty else { return }

        _Concurrency.Task {
            do {
                for id in ids {
                    if let thought = try await thoughtService.fetch(id) {
                        // Merge new tags with existing, avoiding duplicates
                        var updatedTags = thought.tags
                        for tag in tags {
                            let normalizedTag = tag.lowercased()
                                .replacingOccurrences(of: " ", with: "-")
                                .trimmingCharacters(in: .whitespaces)
                            if !updatedTags.contains(normalizedTag) && updatedTags.count < 5 {
                                updatedTags.append(normalizedTag)
                            }
                        }

                        let updatedThought = thought.copying(tags: updatedTags)
                        _ = try await thoughtService.update(updatedThought)
                    }
                }
                selectedThoughtIds.removeAll()
                isEditMode = false
                await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }

    // MARK: - Computed Properties

    /// All unique tags from current thoughts
    var availableTags: [String] {
        Array(Set(thoughts.flatMap { $0.tags })).sorted()
    }

    /// Whether there are active filters
    var hasActiveFilters: Bool {
        filterStatus != nil ||
        !selectedFilterTags.isEmpty ||
        dateRangeFilter != .all ||
        filterType != nil ||
        filterSentiment != nil
    }

    /// Number of selected thoughts
    var selectedCount: Int {
        selectedThoughtIds.count
    }

    /// Whether all visible thoughts are selected
    var allSelected: Bool {
        !thoughts.isEmpty && selectedThoughtIds.count == thoughts.count
    }
}
