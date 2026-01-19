//
//  SearchViewModel.swift
//  PersonalAI
//
//  Phase 3A Spec 3: Search ViewModel
//  Manages state for full-text search with pagination
//

import Foundation
import Observation

// MARK: - Search ViewModel

/// ViewModel for the search screen.
///
/// Manages:
/// - Search query input
/// - Debounced search execution
/// - Paginated results
/// - Loading and error states
@Observable
@MainActor
final class SearchViewModel {
    // MARK: - Input State

    /// Current search query
    var searchQuery: String = "" {
        didSet {
            // Debounce search
            scheduleSearch()
        }
    }

    // MARK: - Results State

    /// Search results
    var searchResults: [Thought] = []

    /// Whether a search is in progress
    var isSearching: Bool = false

    /// Current error to display
    var error: AppError?

    // MARK: - Pagination

    /// Current offset for pagination
    private var offset: Int = 0

    /// Number of results per page
    private let limit: Int = 20

    /// Whether more results are available
    var hasMore: Bool = false

    // MARK: - Debounce

    private var searchTask: _Concurrency.Task<Void, Never>?
    private let debounceInterval: TimeInterval = 0.3

    // MARK: - Services

    private let thoughtService: ThoughtService

    // MARK: - Initialization

    init(thoughtService: ThoughtService) {
        self.thoughtService = thoughtService
    }

    // MARK: - Search

    /// Schedules a debounced search
    private func scheduleSearch() {
        // Cancel previous search
        searchTask?.cancel()

        // Schedule new search
        searchTask = _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))

            // Check if cancelled
            if _Concurrency.Task.isCancelled { return }

            await search()
        }
    }

    /// Executes the search
    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            hasMore = false
            return
        }

        isSearching = true
        error = nil
        offset = 0

        do {
            let results = try await thoughtService.search(query: query)

            self.searchResults = results
            self.hasMore = false  // Service doesn't support pagination yet

        } catch {
            self.error = AppError.from(error)
            self.searchResults = []
        }

        isSearching = false
    }

    /// Loads more results (pagination)
    /// Note: Currently a no-op as service doesn't support pagination
    func loadMore() {
        // Service doesn't support pagination yet
        // This is a placeholder for future implementation
    }

    /// Clears the search
    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        offset = 0
        hasMore = false
        error = nil
    }

    // MARK: - Computed Properties

    /// Whether to show the empty state
    var showEmptyState: Bool {
        !searchQuery.isEmpty && searchResults.isEmpty && !isSearching
    }

    /// Whether to show the initial state (no query)
    var showInitialState: Bool {
        searchQuery.isEmpty && searchResults.isEmpty
    }
}
