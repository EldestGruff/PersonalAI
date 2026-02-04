//
//  BrowseViewModelTests.swift
//  PersonalAITests
//
//  Issue #6: Unit tests for BrowseViewModel
//  Tests filtering, sorting, search, and bulk actions
//

import Testing
import Foundation
@testable import PersonalAI

@Suite("BrowseViewModel Tests")
struct BrowseViewModelTests {

    // MARK: - Test Setup Helpers

    private func createMockThoughtService() -> MockThoughtService {
        MockThoughtService()
    }

    private func createMockFineTuningService() -> MockFineTuningService {
        MockFineTuningService()
    }

    private func createTestThought(
        id: UUID = UUID(),
        content: String = "Test thought",
        tags: [String] = [],
        status: ThoughtStatus = .active,
        createdAt: Date = Date(),
        classification: Classification? = nil
    ) -> Thought {
        Thought(
            id: id,
            userId: UUID(),
            content: content,
            tags: tags,
            status: status,
            context: Context.empty(),
            createdAt: createdAt,
            updatedAt: createdAt,
            classification: classification,
            relatedThoughtIds: [],
            taskId: nil
        )
    }

    private func createTestClassification(
        type: ClassificationType = .note,
        sentiment: Sentiment = .neutral
    ) -> Classification {
        Classification(
            id: UUID(),
            type: type,
            confidence: 0.85,
            entities: [],
            suggestedTags: [],
            sentiment: sentiment,
            language: "en",
            processingTime: 0.1,
            model: "test",
            createdAt: Date(),
            parsedDateTime: nil
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default values")
    @MainActor
    func viewModelInitializesWithDefaults() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.thoughts.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.filterStatus == .active)
        #expect(vm.selectedFilterTags.isEmpty)
        #expect(vm.searchText.isEmpty)
        #expect(vm.dateRangeFilter == .all)
        #expect(vm.filterType == nil)
        #expect(vm.filterSentiment == nil)
        #expect(vm.isEditMode == false)
        #expect(vm.selectedThoughtIds.isEmpty)
    }

    // MARK: - Filter State Tests

    @Test("hasActiveFilters returns true when status filter is set")
    @MainActor
    func hasActiveFiltersWithStatusFilter() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.filterStatus = .active
        #expect(vm.hasActiveFilters == true)

        vm.filterStatus = nil
        #expect(vm.hasActiveFilters == false)
    }

    @Test("hasActiveFilters returns true when tags are selected")
    @MainActor
    func hasActiveFiltersWithTags() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.filterStatus = nil
        vm.selectedFilterTags = ["work"]
        #expect(vm.hasActiveFilters == true)

        vm.selectedFilterTags = []
        #expect(vm.hasActiveFilters == false)
    }

    @Test("hasActiveFilters returns true when search text is set")
    @MainActor
    func hasActiveFiltersWithSearchText() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.filterStatus = nil
        vm.searchText = "meeting"
        #expect(vm.hasActiveFilters == true)
    }

    @Test("hasActiveFilters returns true when date range filter is set")
    @MainActor
    func hasActiveFiltersWithDateRange() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.filterStatus = nil
        vm.dateRangeFilter = .today
        #expect(vm.hasActiveFilters == true)
    }

    @Test("hasActiveFilters returns true when type filter is set")
    @MainActor
    func hasActiveFiltersWithTypeFilter() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.filterStatus = nil
        vm.filterType = .reminder
        #expect(vm.hasActiveFilters == true)
    }

    @Test("hasActiveFilters returns true when sentiment filter is set")
    @MainActor
    func hasActiveFiltersWithSentimentFilter() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.filterStatus = nil
        vm.filterSentiment = .positive
        #expect(vm.hasActiveFilters == true)
    }

    // MARK: - Clear Filters Tests

    @Test("clearFilters resets all filter states")
    @MainActor
    func clearFiltersResetsAllStates() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        // Set various filters
        vm.filterStatus = .archived
        vm.selectedFilterTags = ["work", "personal"]
        vm.searchText = "meeting"
        vm.dateRangeFilter = .thisWeek
        vm.filterType = .reminder
        vm.filterSentiment = .positive

        // Clear all
        vm.clearFilters()

        // Verify all reset
        #expect(vm.filterStatus == nil)
        #expect(vm.selectedFilterTags.isEmpty)
        #expect(vm.searchText.isEmpty)
        #expect(vm.dateRangeFilter == .all)
        #expect(vm.filterType == nil)
        #expect(vm.filterSentiment == nil)
    }

    // MARK: - Tag Filter Tests

    @Test("toggleFilterTag adds tag when not present")
    @MainActor
    func toggleFilterTagAddsTag() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.toggleFilterTag("work")
        #expect(vm.selectedFilterTags.contains("work"))
    }

    @Test("toggleFilterTag removes tag when present")
    @MainActor
    func toggleFilterTagRemovesTag() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.selectedFilterTags = ["work", "personal"]
        vm.toggleFilterTag("work")
        #expect(!vm.selectedFilterTags.contains("work"))
        #expect(vm.selectedFilterTags.contains("personal"))
    }

    // MARK: - Sorting Tests

    @Test("setSortField updates sort field")
    @MainActor
    func setSortFieldUpdatesSortField() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.sortBy == .createdAt)
        vm.setSortField(.updatedAt)
        #expect(vm.sortBy == .updatedAt)
    }

    @Test("toggleSortOrder switches between ascending and descending")
    @MainActor
    func toggleSortOrderSwitches() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.sortOrder == .descending)
        vm.toggleSortOrder()
        #expect(vm.sortOrder == .ascending)
        vm.toggleSortOrder()
        #expect(vm.sortOrder == .descending)
    }

    // MARK: - Bulk Selection Tests

    @Test("toggleEditMode enters and exits edit mode")
    @MainActor
    func toggleEditModeWorks() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.isEditMode == false)
        vm.toggleEditMode()
        #expect(vm.isEditMode == true)
        vm.toggleEditMode()
        #expect(vm.isEditMode == false)
    }

    @Test("exitEditMode clears selections")
    @MainActor
    func exitEditModeClearsSelections() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.isEditMode = true
        vm.selectedThoughtIds = [UUID(), UUID()]
        vm.exitEditMode()

        #expect(vm.isEditMode == false)
        #expect(vm.selectedThoughtIds.isEmpty)
    }

    @Test("toggleSelection adds and removes thought from selection")
    @MainActor
    func toggleSelectionWorks() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        let thought = createTestThought()

        #expect(!vm.isSelected(thought))

        vm.toggleSelection(thought)
        #expect(vm.isSelected(thought))
        #expect(vm.selectedCount == 1)

        vm.toggleSelection(thought)
        #expect(!vm.isSelected(thought))
        #expect(vm.selectedCount == 0)
    }

    @Test("selectAll selects all visible thoughts")
    @MainActor
    func selectAllSelectsAllThoughts() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        let thought1 = createTestThought()
        let thought2 = createTestThought()
        let thought3 = createTestThought()
        vm.thoughts = [thought1, thought2, thought3]

        vm.selectAll()

        #expect(vm.selectedCount == 3)
        #expect(vm.allSelected == true)
    }

    @Test("deselectAll clears all selections")
    @MainActor
    func deselectAllClearsSelections() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.selectedThoughtIds = [UUID(), UUID(), UUID()]
        vm.deselectAll()

        #expect(vm.selectedCount == 0)
        #expect(vm.selectedThoughtIds.isEmpty)
    }

    // MARK: - Date Range Filter Tests

    @Test("DateRangeFilter.today returns start of today")
    func dateRangeFilterTodayReturnsStartOfToday() {
        let now = Date()
        let startDate = DateRangeFilter.today.startDate(from: now)

        #expect(startDate != nil)
        let calendar = Calendar.current
        #expect(calendar.isDateInToday(startDate!))
    }

    @Test("DateRangeFilter.all returns nil start date")
    func dateRangeFilterAllReturnsNil() {
        let startDate = DateRangeFilter.all.startDate()
        #expect(startDate == nil)
    }

    @Test("DateRangeFilter.thisWeek returns start of week")
    func dateRangeFilterThisWeekReturnsStartOfWeek() {
        let now = Date()
        let startDate = DateRangeFilter.thisWeek.startDate(from: now)

        #expect(startDate != nil)
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: startDate!)
        let currentWeek = calendar.component(.weekOfYear, from: now)
        #expect(weekOfYear == currentWeek)
    }

    @Test("DateRangeFilter.thisMonth returns start of month")
    func dateRangeFilterThisMonthReturnsStartOfMonth() {
        let now = Date()
        let startDate = DateRangeFilter.thisMonth.startDate(from: now)

        #expect(startDate != nil)
        let calendar = Calendar.current
        let month = calendar.component(.month, from: startDate!)
        let currentMonth = calendar.component(.month, from: now)
        #expect(month == currentMonth)

        // Verify it's the first day
        let day = calendar.component(.day, from: startDate!)
        #expect(day == 1)
    }

    // MARK: - Selection State Tests

    @Test("selectedCount returns correct count")
    @MainActor
    func selectedCountReturnsCorrectCount() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.selectedCount == 0)

        vm.selectedThoughtIds = [UUID()]
        #expect(vm.selectedCount == 1)

        vm.selectedThoughtIds = [UUID(), UUID(), UUID()]
        #expect(vm.selectedCount == 3)
    }

    @Test("allSelected returns true only when all thoughts selected")
    @MainActor
    func allSelectedReturnsCorrectValue() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        let thought1 = createTestThought()
        let thought2 = createTestThought()
        vm.thoughts = [thought1, thought2]

        #expect(vm.allSelected == false)

        vm.selectedThoughtIds = [thought1.id]
        #expect(vm.allSelected == false)

        vm.selectedThoughtIds = [thought1.id, thought2.id]
        #expect(vm.allSelected == true)
    }

    @Test("allSelected returns false when no thoughts")
    @MainActor
    func allSelectedReturnsFalseWhenEmpty() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.thoughts = []
        #expect(vm.allSelected == false)
    }

    // MARK: - Available Tags Tests

    @Test("availableTags returns unique sorted tags from thoughts")
    @MainActor
    func availableTagsReturnsUniqueSortedTags() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        vm.thoughts = [
            createTestThought(tags: ["work", "meeting"]),
            createTestThought(tags: ["personal", "work"]),
            createTestThought(tags: ["health"])
        ]

        let tags = vm.availableTags
        #expect(tags.count == 4)
        #expect(tags == ["health", "meeting", "personal", "work"])
    }

    // MARK: - Search Filter Tests

    @Test("setSearchText updates search text")
    @MainActor
    func setSearchTextUpdatesSearchText() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.searchText.isEmpty)
        vm.setSearchText("meeting")
        #expect(vm.searchText == "meeting")
    }

    // MARK: - Type Filter Tests

    @Test("setTypeFilter updates type filter")
    @MainActor
    func setTypeFilterUpdatesTypeFilter() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.filterType == nil)
        vm.setTypeFilter(.reminder)
        #expect(vm.filterType == .reminder)

        vm.setTypeFilter(nil)
        #expect(vm.filterType == nil)
    }

    // MARK: - Sentiment Filter Tests

    @Test("setSentimentFilter updates sentiment filter")
    @MainActor
    func setSentimentFilterUpdatesSentimentFilter() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.filterSentiment == nil)
        vm.setSentimentFilter(.positive)
        #expect(vm.filterSentiment == .positive)

        vm.setSentimentFilter(nil)
        #expect(vm.filterSentiment == nil)
    }

    // MARK: - Date Range Setter Tests

    @Test("setDateRangeFilter updates date range filter")
    @MainActor
    func setDateRangeFilterUpdatesDateRangeFilter() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        #expect(vm.dateRangeFilter == .all)
        vm.setDateRangeFilter(.today)
        #expect(vm.dateRangeFilter == .today)
    }

    @Test("setCustomDateRange sets custom range and filter mode")
    @MainActor
    func setCustomDateRangeSetsCustomRange() {
        let vm = BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )

        let start = Date().addingTimeInterval(-86400 * 7)
        let end = Date()

        vm.setCustomDateRange(start: start, end: end)

        #expect(vm.dateRangeFilter == .custom)
        #expect(vm.customStartDate == start)
        #expect(vm.customEndDate == end)
    }
}

// MARK: - Mock FineTuning Service for Tests

actor MockFineTuningService: FineTuningServiceProtocol {
    nonisolated var isAvailable: Bool { true }

    func trackThoughtCreated(_ thought: Thought, classification: Classification) async throws {}
    func trackViewed(_ thoughtId: UUID) async throws {}
    func trackDeleted(_ thoughtId: UUID) async throws {}
    func trackArchived(_ thoughtId: UUID) async throws {}
    func trackReminderCreated(_ thoughtId: UUID) async throws {}
    func trackEventCreated(_ thoughtId: UUID) async throws {}
    func trackUserFeedback(_ thoughtId: UUID, _ feedback: UserFeedback) async throws {}
    func getTrainingData(limit: Int) async throws -> [FineTuningData] { [] }
    func exportTrainingData() async throws -> Data { Data() }
    func purgeOldData(olderThan: Date) async throws {}
}
