# Phase 3A Spec 3: UI & ViewModels (SwiftUI MVVM)

**Status:** Ready for Code Generation  
**Target:** Claude Sonnet  
**Output:** SwiftUI screens, ViewModels, reusable components  
**Complexity:** Very High (5 screens, 5 ViewModels, 10+ components)  

---

## Overview

This specification defines the **User Interface and ViewModel Layer** for Phase 3A. Using SwiftUI with Observation pattern for reactive state management.

**Architecture:**
```
SwiftUI View
    ↓ (binds to)
@Observable ViewModel
    ↓ (calls)
Service Layer (async/await)
    ↓ (updates)
@Observable ViewModel (state changes)
    ↓ (automatic refresh)
SwiftUI View
```

All views work offline first, enhance with context when available, and never block the main thread.

---

## Requirements Analysis

### What We're Solving

**Challenge 1:** Reactive UI without @Published boilerplate  
**Solution:** @Observable pattern with automatic binding

**Challenge 2:** Async operations that don't freeze UI  
**Solution:** Task { await ... } for non-blocking operations

**Challenge 3:** Permission flows that are user-friendly  
**Solution:** Graceful degradation when permissions denied

**Challenge 4:** Context-rich UI that works offline  
**Solution:** Layer information: basic offline → enriched with context

**Challenge 5:** Navigation that's predictable  
**Solution:** NavigationStack with programmatic control

### Edge Cases

- App backgrounded mid-capture (graceful save)
- Rapid thought capture (queuing)
- Network lost mid-sync (retry queue)
- Permission denied (fallback UI)
- Search on large dataset (pagination)
- Device rotation (state preservation)
- Orientation lock changes

### Success Criteria

- ✅ Thought capture <5 seconds
- ✅ Never blocks UI (all async)
- ✅ Works 100% offline
- ✅ Responsive on iPhone (Pro Max size)
- ✅ Accessible (VoiceOver tested)
- ✅ Memory efficient (<200MB peak)
- ✅ Battery friendly (minimal background work)

---

## Approach Options

### Option 1: Heavy State Management (Redux-like)
**Pros:** Predictable, time-travel debugging  
**Cons:** Over-engineered for this app size

### Option 2: Light State Per View (@State)
**Pros:** Simple, SwiftUI native  
**Cons:** State scattered, hard to coordinate

### Option 3: ViewModel Per Screen (Recommended) ✅
**Pros:** Clear separation, testable, reusable logic  
**Cons:** Slight indirection

**Decision:** Option 3. One ViewModel per screen, shared services.

---

## ViewModels (State Management)

### 1. CaptureViewModel (Thought Capture)

```swift
@Observable
class CaptureViewModel {
    // Input state
    var thoughtContent: String = ""
    var selectedTags: [String] = []
    var voiceInputMode: Bool = false
    
    // Processing state
    var isCapturing: Bool = false
    var context: Context?
    var contextError: String?
    var classification: Classification?
    var classificationError: String?
    
    // UI state
    var showPermissionAlert: Bool = false
    var permissionAlertMessage: String = ""
    var isContextLoading: Bool = false
    var isClassificationLoading: Bool = false
    
    // Error handling
    var error: AppError?
    
    // Services
    let thoughtService: ThoughtService
    let contextService: ContextService
    let classificationService: ClassificationService
    let fineTuningService: FineTuningService
    
    init(
        thoughtService: ThoughtService = .shared,
        contextService: ContextService = .shared,
        classificationService: ClassificationService = .shared,
        fineTuningService: FineTuningService = .shared
    ) {
        self.thoughtService = thoughtService
        self.contextService = contextService
        self.classificationService = classificationService
        self.fineTuningService = fineTuningService
    }
    
    // MARK: - Input
    
    var isValid: Bool {
        !thoughtContent.trimmingCharacters(in: .whitespaces).isEmpty &&
        thoughtContent.count <= 5000
    }
    
    func toggleVoiceInput() {
        voiceInputMode.toggle()
    }
    
    func addTag(_ tag: String) {
        guard selectedTags.count < 5, !selectedTags.contains(tag) else { return }
        selectedTags.append(tag.lowercased())
    }
    
    func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }
    
    // MARK: - Processing
    
    @MainActor
    func gatherContext() {
        isContextLoading = true
        
        Task {
            do {
                self.context = await contextService.gatherContext()
                self.contextError = nil
            } catch {
                self.contextError = "Failed to gather context"
                self.context = nil
            }
            
            self.isContextLoading = false
        }
    }
    
    @MainActor
    func classifyThought() {
        guard isValid else { return }
        
        isClassificationLoading = true
        
        Task {
            do {
                self.classification = try await classificationService.classify(thoughtContent)
                self.classificationError = nil
                
                // Merge suggested tags
                if let suggested = self.classification?.suggestedTags {
                    for tag in suggested.prefix(5 - selectedTags.count) {
                        addTag(tag)
                    }
                }
            } catch {
                self.classificationError = "Classification failed, proceeding with manual tags"
                self.classification = nil
            }
            
            self.isClassificationLoading = false
        }
    }
    
    @MainActor
    func captureThought() {
        guard isValid else { return }
        
        isCapturing = true
        
        Task {
            do {
                // Ensure we have context (gather if not)
                if context == nil {
                    self.context = await contextService.gatherContext()
                }
                
                // Ensure we have classification (classify if not)
                if classification == nil {
                    self.classification = try await classificationService.classify(thoughtContent)
                }
                
                // Create thought
                let thought = Thought(
                    id: UUID(),
                    userId: UUID(),  // Phase 3A: hardcoded, Phase 4+ from settings
                    content: thoughtContent.trimmingCharacters(in: .whitespaces),
                    tags: selectedTags,
                    status: .active,
                    context: context ?? Context.default(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    classification: classification,
                    relatedThoughtIds: [],
                    taskId: nil
                )
                
                // Save thought
                let saved = try await thoughtService.create(thought)
                
                // Track for fine-tuning
                if let classification = classification {
                    try await fineTuningService.trackThoughtCreated(saved, classification: classification)
                }
                
                // Reset form
                resetForm()
                self.error = nil
                
            } catch {
                self.error = AppError.from(error)
            }
            
            self.isCapturing = false
        }
    }
    
    func resetForm() {
        thoughtContent = ""
        selectedTags = []
        voiceInputMode = false
        context = nil
        classification = nil
    }
}
```

**Key Patterns:**
- `@MainActor` for state mutations (safe on main thread)
- `async/await` for all I/O
- Graceful degradation (proceed if context/classification fails)
- Automatic tag suggestions from classification

---

### 2. BrowseViewModel (List & Browse)

```swift
@Observable
class BrowseViewModel {
    // Display state
    var thoughts: [Thought] = []
    var isLoading: Bool = false
    var error: AppError?
    
    // Filter state
    var filterStatus: ThoughtStatus = .active
    var searchQuery: String = ""
    var selectedTags: [String] = []
    
    // Sorting
    var sortBy: SortField = .createdAt
    var sortOrder: SortOrder = .descending
    
    // Selection
    var selectedThought: Thought?
    var showDetail: Bool = false
    
    // Services
    let thoughtService: ThoughtService
    let fineTuningService: FineTuningService
    
    init(
        thoughtService: ThoughtService = .shared,
        fineTuningService: FineTuningService = .shared
    ) {
        self.thoughtService = thoughtService
        self.fineTuningService = fineTuningService
        
        Task {
            await self.loadThoughts()
        }
    }
    
    // MARK: - Loading
    
    @MainActor
    func loadThoughts() async {
        isLoading = true
        
        do {
            let filter = ThoughtFilter(
                status: filterStatus,
                tags: selectedTags.isEmpty ? nil : selectedTags,
                sortBy: sortBy,
                sortOrder: sortOrder
            )
            
            self.thoughts = try await thoughtService.list(filter: filter)
            self.error = nil
        } catch {
            self.error = AppError.from(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    
    func setFilterStatus(_ status: ThoughtStatus) {
        self.filterStatus = status
        Task { await loadThoughts() }
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
        Task { await loadThoughts() }
    }
    
    // MARK: - Selection
    
    func selectThought(_ thought: Thought) {
        self.selectedThought = thought
        self.showDetail = true
        
        // Track view for fine-tuning
        Task {
            try? await fineTuningService.trackThoughtViewed(thought.id)
        }
    }
    
    func deselectThought() {
        self.selectedThought = nil
        self.showDetail = false
    }
    
    // MARK: - Actions
    
    @MainActor
    func archiveThought(_ thought: Thought) {
        Task {
            do {
                var updated = thought
                updated.status = .archived
                try await thoughtService.update(updated)
                
                try await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }
    
    @MainActor
    func deleteThought(_ thought: Thought) {
        Task {
            do {
                try await thoughtService.delete(thought.id)
                try await loadThoughts()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }
}

enum SortField: String, CaseIterable {
    case createdAt = "Created"
    case updatedAt = "Updated"
    case confidence = "Confidence"
}

enum SortOrder: String, CaseIterable {
    case ascending = "↑"
    case descending = "↓"
}

struct ThoughtFilter {
    let status: ThoughtStatus?
    let tags: [String]?
    let sortBy: SortField
    let sortOrder: SortOrder
}
```

---

### 3. SearchViewModel (Full-Text Search)

```swift
@Observable
class SearchViewModel {
    // Input
    var searchQuery: String = ""
    
    // Results
    var searchResults: [Thought] = []
    var isSearching: Bool = false
    var error: AppError?
    
    // Pagination
    var offset: Int = 0
    var limit: Int = 20
    var hasMore: Bool = false
    
    // Services
    let thoughtService: ThoughtService
    
    init(thoughtService: ThoughtService = .shared) {
        self.thoughtService = thoughtService
    }
    
    // MARK: - Search
    
    @MainActor
    func search() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        offset = 0
        
        Task {
            do {
                self.searchResults = try await thoughtService.search(
                    query: searchQuery,
                    offset: offset,
                    limit: limit
                )
                self.error = nil
                self.hasMore = self.searchResults.count >= limit
            } catch {
                self.error = AppError.from(error)
            }
            
            self.isSearching = false
        }
    }
    
    @MainActor
    func loadMore() {
        guard hasMore else { return }
        
        offset += limit
        
        Task {
            do {
                let more = try await thoughtService.search(
                    query: searchQuery,
                    offset: offset,
                    limit: limit
                )
                
                self.searchResults.append(contentsOf: more)
                self.hasMore = more.count >= limit
                self.error = nil
            } catch {
                self.error = AppError.from(error)
            }
        }
    }
    
    @MainActor
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        offset = 0
    }
}
```

---

### 4. DetailViewModel (Thought Detail)

```swift
@Observable
class DetailViewModel {
    // Thought data
    var thought: Thought
    
    // Context display
    var contextDisplay: ContextDisplay?
    var isLoadingContext: Bool = false
    
    // Fine-tuning
    var userFeedback: UserFeedback?
    
    // Services
    let thoughtService: ThoughtService
    let fineTuningService: FineTuningService
    
    init(
        thought: Thought,
        thoughtService: ThoughtService = .shared,
        fineTuningService: FineTuningService = .shared
    ) {
        self.thought = thought
        self.thoughtService = thoughtService
        self.fineTuningService = fineTuningService
    }
    
    // MARK: - Actions
    
    @MainActor
    func provideFeedback(_ type: UserFeedback.FeedbackType, comment: String? = nil) {
        userFeedback = UserFeedback(
            type: type,
            comment: comment,
            timestamp: Date()
        )
        
        // Track feedback for fine-tuning
        Task {
            try? await fineTuningService.trackUserFeedback(
                thoughtId: thought.id,
                feedback: userFeedback!
            )
        }
    }
    
    @MainActor
    func updateThought(_ updated: Thought) {
        Task {
            do {
                self.thought = try await thoughtService.update(updated)
            } catch {
                // Error handling
            }
        }
    }
}

struct ContextDisplay {
    let timeOfDay: String
    let location: String?
    let energy: String
    let focus: String
    let activity: String?
}
```

---

### 5. SettingsViewModel (Configuration)

```swift
@Observable
class SettingsViewModel {
    // Permissions
    var healthKitAuthorized: Bool = false
    var locationAuthorized: Bool = false
    var eventKitAuthorized: Bool = false
    var speechAuthorized: Bool = false
    var contactsAuthorized: Bool = false
    
    // Settings
    var enableClassification: Bool = true
    var enableContextEnrichment: Bool = true
    var enableAutoTags: Bool = true
    var autoSyncEnabled: Bool = true
    var syncInterval: TimeInterval = 900  // 15 minutes
    
    // User stats
    var totalThoughts: Int = 0
    var thisWeekCount: Int = 0
    var completionRate: Double = 0.0
    
    // Services
    let healthKitService: HealthKitService
    let locationService: LocationService
    let eventKitService: EventKitService
    let speechService: SpeechService
    let contactsService: ContactsService
    let thoughtService: ThoughtService
    
    init(
        healthKitService: HealthKitService = .shared,
        locationService: LocationService = .shared,
        eventKitService: EventKitService = .shared,
        speechService: SpeechService = .shared,
        contactsService: ContactsService = .shared,
        thoughtService: ThoughtService = .shared
    ) {
        self.healthKitService = healthKitService
        self.locationService = locationService
        self.eventKitService = eventKitService
        self.speechService = speechService
        self.contactsService = contactsService
        self.thoughtService = thoughtService
        
        updatePermissionStatus()
        loadStats()
    }
    
    // MARK: - Permissions
    
    @MainActor
    func updatePermissionStatus() {
        self.healthKitAuthorized = healthKitService.permissions == .authorized
        self.locationAuthorized = locationService.permissions == .authorized
        self.eventKitAuthorized = eventKitService.permissions == .authorized
        self.speechAuthorized = speechService.permissions == .authorized
        self.contactsAuthorized = contactsService.permissions == .authorized
    }
    
    @MainActor
    func requestHealthKitPermission() {
        Task {
            _ = await healthKitService.requestPermissions()
            updatePermissionStatus()
        }
    }
    
    @MainActor
    func requestLocationPermission() {
        Task {
            _ = await locationService.requestPermissions()
            updatePermissionStatus()
        }
    }
    
    @MainActor
    func requestEventKitPermission() {
        Task {
            _ = await eventKitService.requestPermissions()
            updatePermissionStatus()
        }
    }
    
    @MainActor
    func requestSpeechPermission() {
        Task {
            _ = await speechService.requestPermissions()
            updatePermissionStatus()
        }
    }
    
    @MainActor
    func requestContactsPermission() {
        Task {
            _ = await contactsService.requestPermissions()
            updatePermissionStatus()
        }
    }
    
    // MARK: - Stats
    
    @MainActor
    func loadStats() {
        Task {
            do {
                let all = try await thoughtService.list(filter: ThoughtFilter(status: nil, tags: nil, sortBy: .createdAt, sortOrder: .descending))
                
                self.totalThoughts = all.count
                
                // This week
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                let thisWeek = all.filter { $0.createdAt >= weekAgo }
                self.thisWeekCount = thisWeek.count
                
                // Completion rate
                let completed = all.filter { $0.status == .completed }.count
                self.completionRate = Double(completed) / Double(max(1, all.count))
            } catch {
                // Silently fail
            }
        }
    }
}
```

---

## SwiftUI Screens

### 1. CaptureScreen

```swift
struct CaptureScreen: View {
    @State var viewModel: CaptureViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Content input
                if viewModel.voiceInputMode {
                    VoiceInputView(
                        onTranscription: { text in
                            viewModel.thoughtContent = text
                            viewModel.classifyThought()
                        },
                        onCancel: { viewModel.toggleVoiceInput() }
                    )
                } else {
                    TextEditor(text: $viewModel.thoughtContent)
                        .focused($isFocused)
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.3))
                        .padding()
                }
                
                // Tags
                TagInputView(
                    tags: $viewModel.selectedTags,
                    onAdd: { viewModel.addTag($0) },
                    onRemove: { viewModel.removeTag($0) }
                )
                
                // Context & Classification
                if let context = viewModel.context {
                    ContextDisplay(context: context)
                }
                
                if let classification = viewModel.classification {
                    ClassificationBadge(classification: classification)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isCapturing)
                    
                    Button("Voice") {
                        viewModel.toggleVoiceInput()
                    }
                    .disabled(viewModel.isCapturing)
                    
                    Button("Capture") {
                        isFocused = false
                        viewModel.captureThought()
                    }
                    .disabled(!viewModel.isValid || viewModel.isCapturing)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .navigationTitle("New Thought")
            .onAppear {
                viewModel.gatherContext()
                viewModel.classifyThought()
            }
        }
    }
}
```

**UX Decisions:**
- Minimal UI (just capture)
- Context gathers in parallel (doesn't block)
- Classification suggests tags automatically
- Voice input as first-class option

---

### 2. BrowseScreen

```swift
struct BrowseScreen: View {
    @State var viewModel: BrowseViewModel
    @State var showCaptureSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filters
                HStack(spacing: 12) {
                    Menu {
                        ForEach(ThoughtStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                viewModel.setFilterStatus(status)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease")
                    }
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortField.allCases, id: \.self) { field in
                            Button(field.rawValue) {
                                viewModel.sortBy = field
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.down")
                    }
                }
                .padding()
                
                // List of thoughts
                List {
                    ForEach(viewModel.thoughts) { thought in
                        ThoughtRowView(thought: thought)
                            .onTapGesture {
                                viewModel.selectThought(thought)
                            }
                            .swipeActions {
                                Button("Archive", systemImage: "archivebox") {
                                    viewModel.archiveThought(thought)
                                }
                                .tint(.blue)
                                
                                Button(role: .destructive, action: {
                                    viewModel.deleteThought(thought)
                                }, label: {
                                    Label("Delete", systemImage: "trash")
                                })
                            }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Thoughts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCaptureSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCaptureSheet) {
                CaptureScreen(viewModel: CaptureViewModel())
            }
            .navigationDestination(isPresented: $viewModel.showDetail) {
                if let thought = viewModel.selectedThought {
                    DetailScreen(viewModel: DetailViewModel(thought: thought))
                }
            }
        }
    }
}

struct ThoughtRowView: View {
    let thought: Thought
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content preview
            Text(thought.content)
                .lineLimit(2)
                .font(.body)
            
            // Classification & Tags
            HStack(spacing: 8) {
                if let classification = thought.classification {
                    Label(classification.type.rawValue, systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                ForEach(thought.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Time & context
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(thought.createdAt.formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let location = thought.context.location?.name {
                    Image(systemName: "location.fill")
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
```

---

### 3. SearchScreen

```swift
struct SearchScreen: View {
    @State var viewModel: SearchViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search thoughts...", text: $viewModel.searchQuery)
                        .onSubmit { viewModel.search() }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                // Results
                if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No results found")
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.searchResults) { thought in
                            ThoughtRowView(thought: thought)
                        }
                        
                        if viewModel.hasMore {
                            Button("Load More") {
                                viewModel.loadMore()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        if viewModel.isSearching {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}
```

---

### 4. DetailScreen

```swift
struct DetailScreen: View {
    @State var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Content
                Text(viewModel.thought.content)
                    .font(.body)
                    .lineLimit(nil)
                
                Divider()
                
                // Classification
                if let classification = viewModel.thought.classification {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Classification")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Label(classification.type.rawValue, systemImage: "tag.fill")
                            
                            Text("\(Int(classification.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Sentiment: \(classification.sentiment.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                
                // Context
                if let contextDisplay = viewModel.contextDisplay {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.headline)
                        
                        Label(contextDisplay.timeOfDay, systemImage: "clock")
                        Label(contextDisplay.energy, systemImage: "bolt.fill")
                        
                        if let location = contextDisplay.location {
                            Label(location, systemImage: "location.fill")
                        }
                    }
                }
                
                Divider()
                
                // Feedback
                VStack(alignment: .leading, spacing: 8) {
                    Text("Was this helpful?")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.provideFeedback(.helpful)
                        }) {
                            Image(systemImage: "hand.thumbsup")
                                .foregroundColor(viewModel.userFeedback?.type == .helpful ? .green : .gray)
                        }
                        
                        Button(action: {
                            viewModel.provideFeedback(.partially_helpful)
                        }) {
                            Image(systemImage: "minus.circle")
                                .foregroundColor(viewModel.userFeedback?.type == .partially_helpful ? .orange : .gray)
                        }
                        
                        Button(action: {
                            viewModel.provideFeedback(.not_helpful)
                        }) {
                            Image(systemSystem: "hand.thumbsdown")
                                .foregroundColor(viewModel.userFeedback?.type == .not_helpful ? .red : .gray)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Thought")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
```

---

### 5. SettingsScreen

```swift
struct SettingsScreen: View {
    @State var viewModel: SettingsViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                // Permissions
                Section("Permissions") {
                    PermissionRow(
                        label: "Health Data",
                        authorized: viewModel.healthKitAuthorized,
                        action: { viewModel.requestHealthKitPermission() }
                    )
                    
                    PermissionRow(
                        label: "Location",
                        authorized: viewModel.locationAuthorized,
                        action: { viewModel.requestLocationPermission() }
                    )
                    
                    PermissionRow(
                        label: "Calendar & Reminders",
                        authorized: viewModel.eventKitAuthorized,
                        action: { viewModel.requestEventKitPermission() }
                    )
                    
                    PermissionRow(
                        label: "Speech Recognition",
                        authorized: viewModel.speechAuthorized,
                        action: { viewModel.requestSpeechPermission() }
                    )
                    
                    PermissionRow(
                        label: "Contacts",
                        authorized: viewModel.contactsAuthorized,
                        action: { viewModel.requestContactsPermission() }
                    )
                }
                
                // Features
                Section("Features") {
                    Toggle("Auto-Classification", isOn: $viewModel.enableClassification)
                    Toggle("Context Enrichment", isOn: $viewModel.enableContextEnrichment)
                    Toggle("Auto-Tagging", isOn: $viewModel.enableAutoTags)
                }
                
                // Sync
                Section("Sync") {
                    Toggle("Auto-Sync", isOn: $viewModel.autoSyncEnabled)
                    
                    if viewModel.autoSyncEnabled {
                        Stepper(
                            "Sync Every \(Int(viewModel.syncInterval / 60)) minutes",
                            value: $viewModel.syncInterval,
                            in: 300...3600,
                            step: 300
                        )
                    }
                }
                
                // Stats
                Section("Stats") {
                    HStack {
                        Text("Total Thoughts")
                        Spacer()
                        Text("\(viewModel.totalThoughts)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("This Week")
                        Spacer()
                        Text("\(viewModel.thisWeekCount)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Completion Rate")
                        Spacer()
                        Text("\(Int(viewModel.completionRate * 100))%")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct PermissionRow: View {
    let label: String
    let authorized: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Label(label, systemImage: authorized ? "checkmark.circle.fill" : "circle")
                .foregroundColor(authorized ? .green : .gray)
            
            Spacer()
            
            if !authorized {
                Button("Enable") { action() }
                    .font(.caption)
            }
        }
    }
}
```

---

## Reusable Components

### TagInputView

```swift
struct TagInputView: View {
    @Binding var tags: [String]
    let onAdd: (String) -> Void
    let onRemove: (String) -> Void
    
    @State private var newTag: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            // Existing tags
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 6) {
                        Text(tag)
                        
                        Button(action: { onRemove(tag) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            
            // Input
            if tags.count < 5 {
                HStack {
                    TextField("Add tag...", text: $newTag)
                    
                    Button(action: {
                        if !newTag.isEmpty {
                            onAdd(newTag)
                            newTag = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newTag.isEmpty)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var currentHeight: CGFloat = 0
        var currentWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentWidth + size.width + spacing > width {
                currentHeight += lineHeight + spacing
                currentWidth = 0
                lineHeight = 0
            }
            
            currentWidth += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return CGSize(width: width, height: currentHeight + lineHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width + spacing > bounds.maxX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
```

---

### ClassificationBadge

```swift
struct ClassificationBadge: View {
    let classification: Classification
    
    var typeColor: Color {
        switch classification.type {
        case .reminder: return .blue
        case .event: return .green
        case .note: return .gray
        case .question: return .orange
        case .idea: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI Classification")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(classification.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 8) {
                Label(classification.type.rawValue, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(typeColor)
                
                Spacer()
                
                Text(classification.sentiment.rawValue)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .padding()
    }
}
```

---

## Navigation Architecture

```swift
@main
struct PersonalAIApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                // Browse tab
                BrowseScreen(viewModel: BrowseViewModel())
                    .tabItem {
                        Label("Thoughts", systemImage: "list.bullet")
                    }
                
                // Search tab
                SearchScreen(viewModel: SearchViewModel())
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                
                // Settings tab
                SettingsScreen(viewModel: SettingsViewModel())
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}
```

---

## Error Handling (User-Friendly)

```swift
enum AppError: LocalizedError {
    case validationFailed(String)
    case permissionDenied(String)
    case networkError
    case storageError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let msg):
            return "Invalid input: \(msg)"
        case .permissionDenied(let framework):
            return "Enable \(framework) in Settings"
        case .networkError:
            return "Network unavailable - offline mode"
        case .storageError:
            return "Storage error - please try again"
        case .unknownError:
            return "Something went wrong"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied(let framework):
            return "Open Settings > Personal AI > \(framework)"
        case .networkError:
            return "Your data will sync when connection resumes"
        default:
            return nil
        }
    }
    
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknownError
    }
}
```

---

## Notes for Sonnet

When generating these UI components:

1. **Use SwiftUI 100%** - No UIKit bridges in Phase 3A
2. **Reactive binding** - @Observable + binding, no @State in ViewModels
3. **Async/await throughout** - No completion handlers
4. **Error handling** - User-facing messages, recovery suggestions
5. **Accessibility** - VoiceOver labels on all interactive elements
6. **Responsive layout** - Adapts to all iPhone sizes
7. **Offline-first UI** - Works without network, enhances with context
8. **Consistent theming** - Use system colors, adaptive to light/dark
9. **Performance** - Lazy loading, pagination for large lists
10. **Testing** - SwiftUI Preview for every screen

Generate production-ready SwiftUI screens with MVVM state management.

---

**Version:** 1.0  
**Status:** Ready for code generation  
**Depends On:** Spec 1 (Models), Spec 2 (Services)  
**Completes Phase 3A UI Layer**  
