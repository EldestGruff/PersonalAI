//
//  BrowseScreen.swift
//  STASH
//
//  Phase 3A Spec 3: Browse & List Screen
//  Main screen for viewing and managing thoughts
//

import SwiftUI

// MARK: - Browse Screen

/// The main browse/list screen for thoughts.
///
/// Features:
/// - List of thoughts with swipe actions
/// - Filter by status, tags, date range, type, and sentiment (Issue #4)
/// - Text search with .searchable() modifier (Issue #4)
/// - Sort options
/// - Navigation to detail view
/// - Floating action button for new thought
/// - Multi-select mode with bulk actions (Issue #5)
struct BrowseScreen: View {
    @State var viewModel: BrowseViewModel
    @State private var showCaptureSheet = false
    @State private var showFilterSheet = false
    @State private var thoughtToDelete: Thought?
    @State private var bulkTagInput: String = ""
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ZStack {
                // Theme background color
                theme.backgroundColor
                    .ignoresSafeArea()

                // Main content
                if viewModel.isLoading && viewModel.thoughts.isEmpty {
                    LoadingView("Loading thoughts...")
                } else if viewModel.thoughts.isEmpty {
                    emptyState
                } else {
                    thoughtList
                }

                // Floating action button (hidden in edit mode)
                if !viewModel.isEditMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            floatingActionButton
                        }
                    }
                }

                // Bulk action toolbar (Issue #5)
                if viewModel.isEditMode && viewModel.selectedCount > 0 {
                    VStack {
                        Spacer()
                        bulkActionToolbar
                    }
                }
            }
            .navigationTitle("Thoughts")
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.setSearchText($0) }
                ),
                prompt: "Search thoughts"
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        editButton
                        filterButton
                    }
                }
            }
            .sheet(isPresented: $showCaptureSheet, onDismiss: {
                viewModel.refresh()
            }) {
                CaptureScreen(
                    viewModel: CaptureViewModel(
                        thoughtService: viewModel.thoughtService,
                        contextService: ContextService.shared,
                        classificationService: ClassificationService.shared,
                        fineTuningService: viewModel.fineTuningService,
                        taskService: TaskService.shared
                    )
                )
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .navigationDestination(isPresented: $viewModel.showDetail) {
                if let thought = viewModel.selectedThought {
                    DetailScreen(
                        viewModel: DetailViewModel(
                            thought: thought,
                            thoughtService: viewModel.thoughtService,
                            fineTuningService: viewModel.fineTuningService,
                            taskService: TaskService.shared
                        )
                    )
                    .onDisappear {
                        // Refresh list when returning from detail view
                        // in case thought was deleted or modified
                        _Concurrency.Task {
                            await viewModel.loadThoughts()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadThoughts()
            }
            .task {
                await viewModel.loadThoughts()
            }
            .confirmationDialog(
                "Delete this thought?",
                isPresented: Binding(
                    get: { thoughtToDelete != nil },
                    set: { if !$0 { thoughtToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let thought = thoughtToDelete {
                        viewModel.deleteThought(thought)
                        thoughtToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    thoughtToDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
            // Bulk delete confirmation (Issue #5)
            .confirmationDialog(
                "Delete \(viewModel.selectedCount) thoughts?",
                isPresented: $viewModel.showBulkDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(viewModel.selectedCount) Thoughts", role: .destructive) {
                    viewModel.deleteSelected()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            // Bulk tag sheet (Issue #5)
            .sheet(isPresented: $viewModel.showBulkTagSheet) {
                bulkTagSheet
            }
        }
    }

    // MARK: - Thought List

    private var thoughtList: some View {
        let theme = themeEngine.getCurrentTheme()

        return List {
            // Error banner if present
            if let error = viewModel.error {
                Section {
                    ErrorBanner(error: error) {
                        viewModel.error = nil
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Active filter indicator
            if viewModel.hasActiveFilters {
                Section {
                    activeFilterBanner
                }
            }

            // Select all / Deselect all in edit mode (Issue #5)
            if viewModel.isEditMode {
                Section {
                    HStack {
                        Button(viewModel.allSelected ? "Deselect All" : "Select All") {
                            if viewModel.allSelected {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }
                        .font(.subheadline)

                        Spacer()

                        Text("\(viewModel.selectedCount) selected")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }

            // Thoughts
            Section {
                ForEach(viewModel.thoughts) { thought in
                    HStack(spacing: 12) {
                        // Checkbox in edit mode (Issue #5)
                        if viewModel.isEditMode {
                            Button {
                                viewModel.toggleSelection(thought)
                            } label: {
                                Image(systemName: viewModel.isSelected(thought) ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(viewModel.isSelected(thought) ? theme.primaryColor : theme.secondaryTextColor)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(viewModel.isSelected(thought) ? "Selected" : "Not selected")
                            .accessibilityHint("Double tap to \(viewModel.isSelected(thought) ? "deselect" : "select")")
                        }

                        ThoughtRowView(thought: thought)
                            .contentShape(Rectangle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.isEditMode {
                            viewModel.toggleSelection(thought)
                        } else {
                            viewModel.selectThought(thought)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !viewModel.isEditMode {
                            Button(role: .destructive) {
                                thoughtToDelete = thought
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if !viewModel.isEditMode {
                            if thought.status == .archived {
                                Button {
                                    viewModel.unarchiveThought(thought)
                                } label: {
                                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                                }
                                .tint(theme.primaryColor)
                            } else {
                                Button {
                                    viewModel.archiveThought(thought)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(theme.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.backgroundColor)
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
    }

    // MARK: - Active Filter Banner (Issue #4)

    private var activeFilterBanner: some View {
        let theme = themeEngine.getCurrentTheme()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Filtered:")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)

                if let status = viewModel.filterStatus {
                    filterChip(status.rawValue.capitalized, chipColor: theme.primaryColor)
                }

                ForEach(viewModel.selectedFilterTags, id: \.self) { tag in
                    filterChip("#\(tag)", chipColor: theme.successColor)
                }

                if viewModel.dateRangeFilter != .all {
                    filterChip(viewModel.dateRangeFilter.rawValue, chipColor: theme.warningColor)
                }

                if let type = viewModel.filterType {
                    filterChip(type.rawValue.capitalized, chipColor: typeColor(type))
                }

                if let sentiment = viewModel.filterSentiment {
                    filterChip(sentimentDisplayName(sentiment), chipColor: theme.infoColor)
                }

                if !viewModel.searchText.isEmpty {
                    filterChip("\"\(viewModel.searchText)\"", chipColor: theme.secondaryTextColor)
                }

                Spacer()

                Button("Clear") {
                    viewModel.clearFilters()
                }
                .font(.caption)
                .foregroundColor(theme.errorColor)
            }
            .padding(.vertical, 4)
        }
    }

    private func filterChip(_ text: String, chipColor: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(
                .regular.tint(chipColor.opacity(0.4)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .foregroundColor(chipColor)
    }

    private func sentimentDisplayName(_ sentiment: Sentiment) -> String {
        switch sentiment {
        case .very_positive: return "Very Positive"
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        case .very_negative: return "Very Negative"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "brain.head.profile",
            title: "No Thoughts Yet",
            message: PersonalityEngine.shared.noThoughtsYet(),
            actionTitle: "Capture Thought"
        ) {
            showCaptureSheet = true
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        let theme = themeEngine.getCurrentTheme()

        return Button {
            showCaptureSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(theme.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: theme.shadowRadius, y: 2)
        }
        .padding()
        .accessibilityLabel("Add new thought")
        .accessibilityHint("Double tap to open capture screen")
        .accessibilityIdentifier("addThoughtButton")
    }

    // MARK: - Edit Button (Issue #5)

    private var editButton: some View {
        Button {
            viewModel.toggleEditMode()
        } label: {
            Text(viewModel.isEditMode ? "Done" : "Edit")
        }
        .accessibilityLabel(viewModel.isEditMode ? "Exit edit mode" : "Enter edit mode")
        .accessibilityHint("Double tap to \(viewModel.isEditMode ? "exit" : "enter") multi-select mode")
        .accessibilityIdentifier("editButton")
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(viewModel.hasActiveFilters ? "Filter thoughts (active filters)" : "Filter thoughts")
        .accessibilityHint("Double tap to open filter and sort options")
        .accessibilityIdentifier("filterButton")
    }

    // MARK: - Bulk Action Toolbar (Issue #5)

    private var bulkActionToolbar: some View {
        let theme = themeEngine.getCurrentTheme()

        return HStack(spacing: 20) {
            // Archive button
            Button {
                viewModel.archiveSelected()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "archivebox")
                        .font(.title2)
                    Text("Archive")
                        .font(.caption)
                }
            }
            .foregroundColor(theme.primaryColor)
            .accessibilityLabel("Archive selected thoughts")
            .accessibilityIdentifier("bulkArchiveButton")

            // Add tags button
            Button {
                viewModel.showBulkTagSheet = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.title2)
                    Text("Add Tags")
                        .font(.caption)
                }
            }
            .foregroundColor(theme.primaryColor)
            .accessibilityLabel("Add tags to selected thoughts")
            .accessibilityIdentifier("bulkTagButton")

            // Delete button
            Button(role: .destructive) {
                viewModel.showBulkDeleteConfirmation = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("Delete")
                        .font(.caption)
                }
            }
            .accessibilityLabel("Delete selected thoughts")
            .accessibilityIdentifier("bulkDeleteButton")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Bulk Tag Sheet (Issue #5)

    private var bulkTagSheet: some View {
        let theme = themeEngine.getCurrentTheme()

        return NavigationStack {
            Form {
                Section("Add Tags to \(viewModel.selectedCount) Thoughts") {
                    TextField("Enter tag (e.g., work, personal)", text: $bulkTagInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Tag input")
                        .accessibilityIdentifier("bulkTagInput")

                    if !bulkTagInput.isEmpty {
                        Text("Will add: #\(bulkTagInput.lowercased().replacingOccurrences(of: " ", with: "-"))")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }

                Section("Quick Tags") {
                    let suggestedTags = ["important", "follow-up", "review", "personal", "work"]
                    ForEach(suggestedTags, id: \.self) { tag in
                        Button {
                            bulkTagInput = tag
                        } label: {
                            HStack {
                                Text("#\(tag)")
                                Spacer()
                                if bulkTagInput == tag {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                    }
                }
            }
            .navigationTitle("Add Tags")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        bulkTagInput = ""
                        viewModel.showBulkTagSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Tag") {
                        if !bulkTagInput.isEmpty {
                            viewModel.addTagsToSelected([bulkTagInput])
                            bulkTagInput = ""
                            viewModel.showBulkTagSheet = false
                        }
                    }
                    .disabled(bulkTagInput.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        let theme = themeEngine.getCurrentTheme()

        return NavigationStack {
            Form {
                // Status filter
                Section("Status") {
                    ForEach([ThoughtStatus.active, .archived, .completed], id: \.self) { status in
                        Button {
                            if viewModel.filterStatus == status {
                                viewModel.setFilterStatus(nil)
                            } else {
                                viewModel.setFilterStatus(status)
                            }
                        } label: {
                            HStack {
                                Text(status.rawValue.capitalized)
                                Spacer()
                                if viewModel.filterStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                        .accessibilityValue(viewModel.filterStatus == status ? "Selected" : "Not selected")
                        .accessibilityHint("Double tap to \(viewModel.filterStatus == status ? "deselect" : "select") \(status.rawValue) status")
                    }
                }
                .accessibilitySortPriority(7)

                // Date Range filter (Issue #4)
                Section("Date Range") {
                    ForEach(DateRangeFilter.allCases.filter { $0 != .custom }, id: \.self) { range in
                        Button {
                            if viewModel.dateRangeFilter == range {
                                viewModel.setDateRangeFilter(.all)
                            } else {
                                viewModel.setDateRangeFilter(range)
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                Spacer()
                                if viewModel.dateRangeFilter == range {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                        .accessibilityValue(viewModel.dateRangeFilter == range ? "Selected" : "Not selected")
                        .accessibilityIdentifier("dateRange_\(range.rawValue)")
                    }

                    // Custom date range
                    DisclosureGroup("Custom Range") {
                        DatePicker(
                            "From",
                            selection: Binding(
                                get: { viewModel.customStartDate },
                                set: { newValue in
                                    viewModel.setCustomDateRange(start: newValue, end: viewModel.customEndDate)
                                }
                            ),
                            displayedComponents: .date
                        )
                        .accessibilityIdentifier("customStartDate")

                        DatePicker(
                            "To",
                            selection: Binding(
                                get: { viewModel.customEndDate },
                                set: { newValue in
                                    viewModel.setCustomDateRange(start: viewModel.customStartDate, end: newValue)
                                }
                            ),
                            displayedComponents: .date
                        )
                        .accessibilityIdentifier("customEndDate")
                    }
                }
                .accessibilitySortPriority(6)

                // Classification Type filter (Issue #4)
                Section("Type") {
                    Button {
                        viewModel.setTypeFilter(nil)
                    } label: {
                        HStack {
                            Text("All Types")
                            Spacer()
                            if viewModel.filterType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primaryColor)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .foregroundColor(theme.textColor)
                    .accessibilityIdentifier("typeFilter_all")

                    ForEach(ClassificationType.allCases, id: \.self) { type in
                        Button {
                            if viewModel.filterType == type {
                                viewModel.setTypeFilter(nil)
                            } else {
                                viewModel.setTypeFilter(type)
                            }
                        } label: {
                            HStack {
                                Image(systemName: typeIcon(type))
                                    .foregroundColor(typeColor(type))
                                    .frame(width: 24)
                                Text(type.rawValue.capitalized)
                                Spacer()
                                if viewModel.filterType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                        .accessibilityValue(viewModel.filterType == type ? "Selected" : "Not selected")
                        .accessibilityIdentifier("typeFilter_\(type.rawValue)")
                    }
                }
                .accessibilitySortPriority(5)

                // Sentiment filter (Issue #4)
                Section("Sentiment") {
                    Button {
                        viewModel.setSentimentFilter(nil)
                    } label: {
                        HStack {
                            Text("All Sentiments")
                            Spacer()
                            if viewModel.filterSentiment == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primaryColor)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .foregroundColor(theme.textColor)
                    .accessibilityIdentifier("sentimentFilter_all")

                    ForEach(Sentiment.allCases, id: \.self) { sentiment in
                        Button {
                            if viewModel.filterSentiment == sentiment {
                                viewModel.setSentimentFilter(nil)
                            } else {
                                viewModel.setSentimentFilter(sentiment)
                            }
                        } label: {
                            HStack {
                                Text(sentimentEmoji(sentiment))
                                    .frame(width: 24)
                                Text(sentimentDisplayName(sentiment))
                                Spacer()
                                if viewModel.filterSentiment == sentiment {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                        .accessibilityValue(viewModel.filterSentiment == sentiment ? "Selected" : "Not selected")
                        .accessibilityIdentifier("sentimentFilter_\(sentiment.rawValue)")
                    }
                }
                .accessibilitySortPriority(4)

                // Tag filter
                if !viewModel.availableTags.isEmpty {
                    Section("Tags") {
                        ForEach(viewModel.availableTags, id: \.self) { tag in
                            Button {
                                viewModel.toggleFilterTag(tag)
                            } label: {
                                HStack {
                                    Text("#\(tag)")
                                    Spacer()
                                    if viewModel.selectedFilterTags.contains(tag) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(theme.primaryColor)
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                            .foregroundColor(theme.textColor)
                            .accessibilityValue(viewModel.selectedFilterTags.contains(tag) ? "Selected" : "Not selected")
                            .accessibilityHint("Double tap to \(viewModel.selectedFilterTags.contains(tag) ? "deselect" : "select") tag")
                        }
                    }
                    .accessibilitySortPriority(3)
                }

                // Sort options
                Section("Sort By") {
                    ForEach(SortField.allCases, id: \.self) { field in
                        Button {
                            viewModel.setSortField(field)
                        } label: {
                            HStack {
                                Text(field.rawValue)
                                Spacer()
                                if viewModel.sortBy == field {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                        .accessibilityValue(viewModel.sortBy == field ? "Selected" : "Not selected")
                        .accessibilityHint("Double tap to sort by \(field.rawValue)")
                    }
                }
                .accessibilitySortPriority(2)

                Section("Sort Order") {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            if viewModel.sortOrder != order {
                                viewModel.toggleSortOrder()
                            }
                        } label: {
                            HStack {
                                Image(systemName: order.symbol)
                                    .accessibilityHidden(true)
                                Text(order.rawValue)
                                Spacer()
                                if viewModel.sortOrder == order {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundColor(theme.textColor)
                        .accessibilityValue(viewModel.sortOrder == order ? "Selected" : "Not selected")
                        .accessibilityHint("Double tap to sort in \(order.rawValue) order")
                    }
                }
                .accessibilitySortPriority(1)
            }
            .navigationTitle("Filter & Sort")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Filter Sheet Helpers

    private func typeIcon(_ type: ClassificationType) -> String {
        switch type {
        case .reminder: return "bell"
        case .event: return "calendar"
        case .note: return "note.text"
        case .question: return "questionmark.circle"
        case .idea: return "lightbulb"
        }
    }

    private func typeColor(_ type: ClassificationType) -> Color {
        let theme = themeEngine.getCurrentTheme()

        switch type {
        case .reminder: return theme.warningColor
        case .event: return theme.primaryColor
        case .note: return theme.secondaryTextColor
        case .question: return theme.infoColor
        case .idea: return theme.accentColor
        }
    }

    private func sentimentEmoji(_ sentiment: Sentiment) -> String {
        switch sentiment {
        case .very_positive: return "😄"
        case .positive: return "🙂"
        case .neutral: return "😐"
        case .negative: return "😕"
        case .very_negative: return "😢"
        }
    }
}

// MARK: - Shared Service Instances

extension ContextService {
    static let shared = ContextService(
        locationService: LocationService(),
        healthKitService: HealthKitService(),
        motionService: MotionService(),
        eventKitService: EventKitService(),
        configuration: .shared
    )
}

extension ClassificationService {
    static let shared = ClassificationService(configuration: .shared)
}

extension ThoughtService {
    static let shared: ThoughtService = {
        let repo = ThoughtRepository.shared
        let classService = ClassificationService.shared
        let syncService = SyncService.shared
        let ftService = FineTuningService.shared
        return ThoughtService(
            repository: repo,
            classificationService: classService,
            syncService: syncService,
            fineTuningService: ftService,
            configuration: .shared
        )
    }()
}

extension SyncService {
    static let shared = SyncService(
        repository: .shared,
        networkMonitor: NetworkMonitor(),
        configuration: .shared
    )
}

extension FineTuningService {
    static let shared = FineTuningService(
        repository: .shared,
        syncService: SyncService.shared,
        configuration: .shared
    )
}

// MARK: - Previews

#Preview("Browse Screen") {
    BrowseScreen(
        viewModel: BrowseViewModel(
            thoughtService: ThoughtService.shared,
            fineTuningService: FineTuningService.shared
        )
    )
}
