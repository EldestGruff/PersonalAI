//
//  SearchScreen.swift
//  PersonalAI
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

    init(viewModel: SearchViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Search")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search thoughts...", text: $viewModel.searchQuery)
                .focused($isSearchFocused)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                #endif
                .autocorrectionDisabled()
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
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    // MARK: - Initial State

    private var initialState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Search Your Thoughts")
                .font(.headline)

            Text("Find thoughts by content, tags, or context")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Recent searches could go here in future

            Spacer()
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Results")
                .font(.headline)

            Text("No thoughts match \"\(viewModel.searchQuery)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Clear Search") {
                viewModel.clearSearch()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }

    // MARK: - Search Results

    private var searchResults: some View {
        List {
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

            // Results count
            Section {
                Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Results
            Section {
                ForEach(viewModel.searchResults) { thought in
                    NavigationLink {
                        DetailScreen(
                            viewModel: DetailViewModel(
                                thought: thought,
                                thoughtService: ThoughtService.shared,
                                fineTuningService: FineTuningService.shared
                            )
                        )
                    } label: {
                        SearchResultRow(
                            thought: thought,
                            searchQuery: viewModel.searchQuery
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
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSearching)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
    }
}

// MARK: - Search Result Row

/// A row displaying a search result with query highlighting.
struct SearchResultRow: View {
    let thought: Thought
    let searchQuery: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content with highlighted query
            highlightedContent

            // Classification
            if let classification = thought.classification {
                ClassificationBadgeCompact(classification: classification)
            }

            // Metadata
            HStack(spacing: 8) {
                Text(thought.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !thought.tags.isEmpty {
                    ForEach(thought.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var highlightedContent: some View {
        // Simple highlighting - in production could use AttributedString
        Text(thought.content)
            .font(.body)
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
}
