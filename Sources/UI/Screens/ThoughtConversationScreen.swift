//
//  ThoughtConversationScreen.swift
//  STASH
//
//  Companion conversation screen for thought-specific chats
//

import SwiftUI

@available(iOS 26.0, *)
struct ThoughtConversationScreen: View {
    @State private var viewModel: ThoughtConversationViewModel
    @FocusState private var isInputFocused: Bool
    @State private var showPersonaPicker = false
    @State private var showConversationPicker = false
    @State private var showDeleteConfirmation = false
    @State private var conversationToDelete: ThoughtConversation?
    @State private var themeEngine = ThemeEngine.shared

    init(thought: Thought) {
        _viewModel = State(initialValue: ThoughtConversationViewModel(
            thought: thought,
            thoughtService: ThoughtService.shared
        ))
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        ZStack {
            // Theme background
            theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Collapsed thought header
                thoughtHeaderView

                // Conversation picker (if multiple exist)
                if viewModel.hasMultipleConversations {
                    conversationPickerView
                }

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Messages
                            ForEach(viewModel.messages) { message in
                                CompanionMessageBubbleView(
                                    message: message,
                                    persona: viewModel.selectedPersona
                                )
                                .id(message.id)
                            }

                            // Loading indicator
                            if viewModel.isLoading {
                                CompanionLoadingView(persona: viewModel.selectedPersona)
                            }

                            // Error message
                            if let error = viewModel.error {
                                ErrorMessageView(error: error) {
                                    _Concurrency.Task {
                                        await viewModel.retry()
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input bar
                inputBarView
            }
        }
        .navigationTitle("Companion Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.surfaceColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // Privacy toggle
                    Button {
                        _Concurrency.Task {
                            await viewModel.togglePrivacy()
                        }
                    } label: {
                        Image(systemName: viewModel.isPrivate ? "lock.fill" : "globe")
                            .foregroundColor(viewModel.isPrivate ? theme.warningColor : theme.primaryColor)
                    }
                    .accessibilityLabel(viewModel.isPrivate ? "Private mode" : "Connected mode")

                    // Persona picker
                    Button {
                        showPersonaPicker = true
                    } label: {
                        Image(viewModel.selectedPersona.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    }
                    .accessibilityLabel("Change persona")

                    // Menu
                    Menu {
                        Button {
                            _Concurrency.Task {
                                await viewModel.startNewConversation()
                            }
                        } label: {
                            Label("New Conversation", systemImage: "plus.bubble")
                        }

                        if viewModel.hasMultipleConversations {
                            Button {
                                showConversationPicker = true
                            } label: {
                                Label("Switch Conversation", systemImage: "bubble.left.and.bubble.right")
                            }
                        }

                        Divider()

                        if let conversation = viewModel.currentConversation {
                            Button(role: .destructive) {
                                conversationToDelete = conversation
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Conversation", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPickerSheet(
                selectedPersona: viewModel.selectedPersona,
                onSelect: { persona in
                    _Concurrency.Task {
                        await viewModel.changePersona(persona)
                    }
                    showPersonaPicker = false
                }
            )
        }
        .sheet(isPresented: $showConversationPicker) {
            ConversationPickerSheet(
                conversations: viewModel.allConversations,
                currentConversation: viewModel.currentConversation,
                onSelect: { conversation in
                    _Concurrency.Task {
                        await viewModel.switchConversation(conversation)
                    }
                    showConversationPicker = false
                }
            )
        }
        .confirmationDialog(
            "Delete this conversation?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let conversation = conversationToDelete {
                    _Concurrency.Task {
                        await viewModel.deleteConversation(conversation)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .task {
            await viewModel.initialize()
        }
    }

    // MARK: - Thought Header

    private var thoughtHeaderView: some View {
        let theme = themeEngine.getCurrentTheme()
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exploring:")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)

                    Text(viewModel.thought.content)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundStyle(theme.textColor)

                    if !viewModel.thought.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(viewModel.thought.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(theme.tagBackgroundColor)
                                        .foregroundColor(theme.tagTextColor)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Privacy indicator
                VStack(spacing: 4) {
                    Image(systemName: viewModel.isPrivate ? "lock.fill" : "globe")
                        .font(.title3)
                        .foregroundColor(viewModel.isPrivate ? theme.warningColor : theme.primaryColor)

                    Text(viewModel.isPrivate ? "Private" : "Connected")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
    }

    // MARK: - Conversation Picker

    private var conversationPickerView: some View {
        let theme = themeEngine.getCurrentTheme()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.allConversations.sorted(by: { $0.lastActivityTime > $1.lastActivityTime })) { conversation in
                    Button {
                        _Concurrency.Task {
                            await viewModel.switchConversation(conversation)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(conversation.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(theme.textColor)

                                if conversation.id == viewModel.currentConversation?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(theme.successColor)
                                }
                            }

                            Text("\(conversation.messageCount) messages")
                                .font(.caption2)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            conversation.id == viewModel.currentConversation?.id
                                ? theme.primaryColor.opacity(0.15)
                                : theme.surfaceColor
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Input Bar

    private var inputBarView: some View {
        let theme = themeEngine.getCurrentTheme()
        return VStack(spacing: 0) {
            Divider()
                .background(theme.dividerColor)

            HStack(alignment: .bottom, spacing: 12) {
                // Persona indicator
                Image(viewModel.selectedPersona.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .padding(6)
                    .background(Color(hex: viewModel.selectedPersona.colorHex)?.opacity(0.2) ?? theme.primaryColor.opacity(0.2))
                    .cornerRadius(10)

                TextField("Chat with \(viewModel.selectedPersona.name)...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(theme.inputBackgroundColor)
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? theme.primaryColor : theme.secondaryTextColor)
                }
                .disabled(!canSend)
            }
            .padding()
        }
        .background(theme.surfaceColor)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isLoading
    }

    private func sendMessage() {
        let message = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        viewModel.inputText = ""
        isInputFocused = false

        _Concurrency.Task {
            await viewModel.sendMessage(message)
        }
    }
}

// MARK: - Companion Message Bubble

struct CompanionMessageBubbleView: View {
    let message: ConversationMessage
    let persona: SquirrelPersona
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
            } else {
                roleIcon
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user ? theme.primaryColor : theme.surfaceColor)
                            .shadow(color: theme.shadowColor, radius: 3, y: 1)
                    )
                    .foregroundColor(textColor)

                // Citations
                if let citations = message.citations, !citations.isEmpty {
                    CitationsView(citations: citations)
                }

                // Suggested questions
                if let suggestions = message.suggestedQuestions, !suggestions.isEmpty {
                    SuggestedQuestionsView(questions: suggestions)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryTextColor)
            }
            .frame(maxWidth: message.role == .user ? 280 : .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user {
                Spacer()
            } else {
                roleIcon
            }
        }
    }

    private var roleIcon: some View {
        let theme = themeEngine.getCurrentTheme()
        return Group {
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)
            } else {
                Image(persona.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .padding(4)
                    .background(Color(hex: persona.colorHex)?.opacity(0.2) ?? theme.accentColor.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }

    private var backgroundColor: Color {
        let theme = themeEngine.getCurrentTheme()
        return message.role == .user ? theme.primaryColor : theme.surfaceColor
    }

    private var textColor: Color {
        let theme = themeEngine.getCurrentTheme()
        return message.role == .user ? .white : theme.textColor
    }
}

// MARK: - Companion Loading View

struct CompanionLoadingView: View {
    let persona: SquirrelPersona
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        HStack(spacing: 12) {
            Image(persona.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(4)
                .background(Color(hex: persona.colorHex)?.opacity(0.2) ?? theme.accentColor.opacity(0.2))
                .cornerRadius(10)

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(theme.secondaryTextColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: UUID()
                        )
                }
            }
            .padding(12)
            .background(theme.surfaceColor)
            .cornerRadius(16)

            Spacer()
        }
    }
}

// MARK: - Persona Picker Sheet

struct PersonaPickerSheet: View {
    let selectedPersona: SquirrelPersona
    let onSelect: (SquirrelPersona) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                List {
                    Section {
                        ForEach(SquirrelPersona.builtIn) { persona in
                            Button {
                                onSelect(persona)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(persona.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .padding(6)
                                        .background(Color(hex: persona.colorHex)?.opacity(0.2) ?? theme.primaryColor.opacity(0.2))
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(persona.name)
                                            .font(.headline)
                                            .foregroundColor(theme.textColor)

                                        Text(extractFirstLine(persona.systemPrompt))
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryTextColor)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    if persona.id == selectedPersona.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(theme.successColor)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Built-in Personas")
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .listRowBackground(theme.surfaceColor)

                    let customPersonas = PersonaService.shared.customPersonas
                    if !customPersonas.isEmpty {
                        Section {
                            ForEach(customPersonas) { persona in
                                Button {
                                    onSelect(persona)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(persona.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36, height: 36)
                                            .padding(6)
                                            .background(Color(hex: persona.colorHex)?.opacity(0.2) ?? theme.primaryColor.opacity(0.2))
                                            .cornerRadius(10)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(persona.name)
                                                .font(.headline)
                                                .foregroundColor(theme.textColor)

                                            Text(extractFirstLine(persona.systemPrompt))
                                                .font(.caption)
                                                .foregroundColor(theme.secondaryTextColor)
                                                .lineLimit(2)
                                        }

                                        Spacer()

                                        if persona.id == selectedPersona.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(theme.successColor)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Custom Personas")
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        .listRowBackground(theme.surfaceColor)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(theme.primaryColor)
                }
            }
        }
    }

    private func extractFirstLine(_ text: String) -> String {
        text.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
    }
}

// MARK: - Conversation Picker Sheet

struct ConversationPickerSheet: View {
    let conversations: [ThoughtConversation]
    let currentConversation: ThoughtConversation?
    let onSelect: (ThoughtConversation) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                List {
                    ForEach(conversations.sorted(by: { $0.lastActivityTime > $1.lastActivityTime })) { conversation in
                        Button {
                            onSelect(conversation)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(conversation.title)
                                        .font(.headline)
                                        .foregroundColor(theme.textColor)

                                    Spacer()

                                    if conversation.id == currentConversation?.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(theme.successColor)
                                    }
                                }

                                HStack(spacing: 12) {
                                    Text(conversation.privacyDescription)
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)

                                    Text("\u{2022}")
                                        .foregroundColor(theme.secondaryTextColor)

                                    Text("\(conversation.messageCount) messages")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)

                                    Text("\u{2022}")
                                        .foregroundColor(theme.secondaryTextColor)

                                    Text(conversation.lastActivityTime, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                }

                                if let lastMessage = conversation.lastMessage {
                                    Text(lastMessage.content)
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(theme.surfaceColor)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(theme.primaryColor)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        if #available(iOS 26.0, *) {
            ThoughtConversationScreen(
                thought: Thought(
                    id: UUID(),
                    userId: UUID(),
                    content: "I've been thinking about how to improve my morning routine. Maybe I should wake up earlier and do some meditation?",
                    attributedContent: nil,
                    tags: ["personal", "health", "routine"],
                    status: .active,
                    context: Context(
                        timestamp: Date(),
                        location: nil,
                        timeOfDay: .morning,
                        energy: .medium,
                        focusState: .deep_work,
                        calendar: nil,
                        activity: nil,
                        weather: nil,
                        stateOfMind: nil,
                        energyBreakdown: nil
                    ),
                    createdAt: Date(),
                    updatedAt: Date(),
                    classification: nil,
                    relatedThoughtIds: [],
                    taskId: nil
                )
            )
        } else {
            Text("iOS 26+ required")
        }
    }
}
