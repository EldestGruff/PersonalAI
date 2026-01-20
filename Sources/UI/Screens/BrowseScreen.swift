//
//  BrowseScreen.swift
//  PersonalAI
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
/// - Filter by status and tags
/// - Sort options
/// - Navigation to detail view
/// - Floating action button for new thought
struct BrowseScreen: View {
    @State var viewModel: BrowseViewModel
    @State private var showCaptureSheet = false
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                if viewModel.isLoading && viewModel.thoughts.isEmpty {
                    LoadingView("Loading thoughts...")
                } else if viewModel.thoughts.isEmpty {
                    emptyState
                } else {
                    thoughtList
                }

                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                }
            }
            .navigationTitle("Thoughts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    filterButton
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
        }
    }

    // MARK: - Thought List

    private var thoughtList: some View {
        List {
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
                    HStack {
                        Text("Filtered")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let status = viewModel.filterStatus {
                            Text(status.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }

                        ForEach(viewModel.selectedFilterTags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                    }
                }
            }

            // Thoughts
            Section {
                ForEach(viewModel.thoughts) { thought in
                    ThoughtRowView(thought: thought)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectThought(thought)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteThought(thought)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if thought.status == .archived {
                                Button {
                                    viewModel.unarchiveThought(thought)
                                } label: {
                                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                                }
                                .tint(.blue)
                            } else {
                                Button {
                                    viewModel.archiveThought(thought)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.orange)
                            }
                        }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "brain.head.profile",
            title: "No Thoughts Yet",
            message: "Capture your first thought to get started. Thoughts are automatically organized and enriched with context.",
            actionTitle: "Capture Thought"
        ) {
            showCaptureSheet = true
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        Button {
            showCaptureSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .padding()
        .accessibilityLabel("Add new thought")
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
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
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

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
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
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
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section("Sort Order") {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            if viewModel.sortOrder != order {
                                viewModel.toggleSortOrder()
                            }
                        } label: {
                            HStack {
                                Image(systemName: order.symbol)
                                Text(order.rawValue)
                                Spacer()
                                if viewModel.sortOrder == order {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
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
