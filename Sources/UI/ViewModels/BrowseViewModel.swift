//
//  BrowseViewModel.swift
//  PersonalAI
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

// MARK: - Browse ViewModel

/// ViewModel for the browse/list screen.
///
/// Manages:
/// - Loading and displaying thoughts
/// - Filtering by status and tags
/// - Sorting
/// - Selection for detail view
/// - Archive and delete actions
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

    // MARK: - Filter State

    /// Filter by thought status
    var filterStatus: ThoughtStatus? = .active

    /// Filter by tags (empty = no tag filter)
    var selectedFilterTags: [String] = []

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

            // Apply tag filter locally if needed (service doesn't support multi-tag filter)
            if !selectedFilterTags.isEmpty {
                results = results.filter { thought in
                    selectedFilterTags.allSatisfy { thought.tags.contains($0) }
                }
            }

            // Sort locally
            results = sortThoughts(results)

            self.thoughts = results

        } catch {
            self.error = AppError.from(error)
        }

        isLoading = false
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
        filterStatus != nil || !selectedFilterTags.isEmpty
    }
}
