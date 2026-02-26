//
//  SearchScreen.swift
//  STASH
//
//  Phase 3A Spec 3: Search Screen
//  Full-text search for thoughts
//

import SwiftUI

// MARK: - Search Screen

/// The search screen for finding thoughts.
///
/// Features:
/// - Search bar with debounced input
/// - Paginated results
/// - Empty and initial states
/// - Navigation to thought detail
struct SearchScreen: View {
    @State var viewModel: SearchViewModel
    @SwiftUI.FocusState private var isSearchFocused: Bool
    @State private var themeEngine = ThemeEngine.shared

    init(viewModel: SearchViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                // Theme background color
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Content
                    if viewModel.showInitialState {
                        initialState
                    } else if viewModel.showEmptyState {
                        emptyState
                    } else {
                        searchResults
                    }
                }
            }
            .navigationTitle("Search")
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                AnalyticsService.shared.track(.screenViewed(.search))
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        let theme = themeEngine.getCurrentTheme()

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.secondaryTextColor)
                .accessibilityHidden(true)

            TextField("Dig through the hoard...", text: $viewModel.searchQuery)
                .focused($isSearchFocused)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                #endif
                .autocorrectionDisabled()
                .accessibilityIdentifier("searchTextField")
                .accessibilityHint("Search by content, tags, or context")
                .onSubmit {
                    _Concurrency.Task {
                        await viewModel.search()
                    }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.secondaryTextColor)
                }
                .accessibilityLabel("Clear search")
                .accessibilityHint("Double tap to clear search query")
                .accessibilityIdentifier("clearSearchButton")
            }

            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(theme.inputBackgroundColor)
        .cornerRadius(theme.cornerRadius)
        .padding()
    }

    // MARK: - Initial State

    private var initialState: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 16) {
            Spacer()

            Image("squirrel-base")
                .resizable()
                .scaledToFit()
                .frame(height: 90)

            Text("What are you looking for?")
                .font(.headline)
                .foregroundColor(theme.textColor)

            Text("Dig through your hoard by content, tags, or context")
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryTextColor)
                .accessibilityHidden(true)

            Text("No Results")
                .font(.headline)
                .foregroundColor(theme.textColor)

            Text("No thoughts match \"\(viewModel.searchQuery)\"")
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Button("Clear Search") {
                viewModel.clearSearch()
            }
            .buttonStyle(.bordered)
            .tint(theme.primaryColor)

            Spacer()
        }
        .padding()
    }

    // MARK: - Search Results

    private var searchResults: some View {
        let theme = themeEngine.getCurrentTheme()

        return List {
            // Error if present
            if let error = viewModel.error {
                Section {
                    ErrorCard(error: error) {
                        _Concurrency.Task {
                            await viewModel.search()
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Results count and search mode
            Section {
                HStack {
                    Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)

                    Spacer()

                    if viewModel.isSemanticSearchAvailable {
                        Label("Semantic", systemImage: "brain")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    } else {
                        Label("Keyword", systemImage: "text.magnifyingglass")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }

            // Results
            Section {
                ForEach(viewModel.searchResults) { result in
                    NavigationLink {
                        DetailScreen(
                            viewModel: DetailViewModel(
                                thought: result.thought,
                                thoughtService: ThoughtService.shared,
                                fineTuningService: FineTuningService.shared,
                                taskService: TaskService.shared
                            )
                        )
                    } label: {
                        SearchResultRow(
                            result: result,
                            searchQuery: viewModel.searchQuery,
                            themeEngine: themeEngine
                        )
                    }
                }
            }

            // Load more
            if viewModel.hasMore {
                Section {
                    Button {
                        viewModel.loadMore()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSearching {
                                ProgressView()
                            } else {
                                Text("Load More")
                                    .foregroundColor(theme.primaryColor)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSearching)
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
}

// MARK: - Search Result Row

/// A row displaying a search result with relevance scoring.
struct SearchResultRow: View {
    let result: SearchResult
    let searchQuery: String
    var themeEngine: ThemeEngine

    private var thought: Thought {
        result.thought
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 8) {
            // Content with highlighted query
            highlightedContent

            // Classification and relevance
            HStack(spacing: 8) {
                if let classification = thought.classification {
                    ClassificationBadgeCompact(classification: classification)
                }

                // Show relevance score for semantic search (not perfect keyword matches)
                if result.score < 1.0 {
                    HStack(spacing: 4) {
                        Image(systemName: result.isHighConfidence ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(result.isHighConfidence ? theme.successColor : theme.warningColor)
                            .accessibilityHidden(true)

                        Text("\(result.relevancePercentage)%")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }

            // Metadata
            HStack(spacing: 8) {
                Text(thought.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)

                if !thought.tags.isEmpty {
                    ForEach(thought.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(theme.tagTextColor)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var highlightedContent: some View {
        let theme = themeEngine.getCurrentTheme()

        // Simple highlighting - in production could use AttributedString
        return Text(thought.content)
            .font(.body)
            .foregroundColor(theme.textColor)
            .lineLimit(3)
    }
}

// MARK: - Previews

#Preview("Search Screen - Initial") {
    SearchScreen(
        viewModel: SearchViewModel(
            thoughtService: ThoughtService.shared
        )
    )
    .environment(\.themeEngine, ThemeEngine.shared)
}
