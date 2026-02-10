//
//  ConversationScreen.swift
//  STASH
//
//  Chat interface for conversational thought exploration
//

import SwiftUI

@available(iOS 26.0, *)
struct ConversationScreen: View {
    @State private var viewModel: ConversationViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.themeEngine) private var themeEngine

    init(thoughtService: ThoughtServiceProtocol) {
        _viewModel = State(initialValue: ConversationViewModel(thoughtService: thoughtService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header
                        headerView

                        // Messages
                        ForEach(viewModel.session.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }

                        // Loading indicator
                        if viewModel.session.isLoading {
                            LoadingMessageView()
                        }

                        // Error message
                        if let error = viewModel.session.error {
                            ErrorMessageView(error: error) {
                                _Concurrency.Task {
                                    await viewModel.retry()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.session.messages.count) { _, _ in
                    if let lastMessage = viewModel.session.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            inputBar
        }
        .navigationTitle("Chat with Thoughts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Clear Conversation", role: .destructive) {
                        viewModel.clearConversation()
                    }
                    Button("Start New Session") {
                        _Concurrency.Task {
                            await viewModel.startNewSession()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.initialize()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(theme.accentColor.gradient)

            Text("Chat with Your Thoughts")
                .font(.title2.bold())
                .foregroundColor(theme.textColor)

            Text("Ask me anything about your captured thoughts")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            if viewModel.thoughtCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(theme.warningColor)
                    Text("\(viewModel.thoughtCount) thoughts available")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.surfaceColor)
                .cornerRadius(12)
            }

            // Starter questions
            if viewModel.session.messages.isEmpty {
                starterQuestionsView
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Starter Questions

    private var starterQuestionsView: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.caption.bold())
                .foregroundStyle(theme.secondaryTextColor)

            ForEach(viewModel.starterQuestions, id: \.self) { question in
                Button {
                    inputText = question
                    isInputFocused = true
                } label: {
                    HStack {
                        Image(systemName: "bubble.left")
                            .font(.caption)
                        Text(question)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(theme.textColor)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(theme.inputBackgroundColor)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 0) {
            Divider()
                .background(theme.dividerColor)

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask about your thoughts...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundColor(theme.textColor)
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
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.session.isLoading
    }

    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        inputText = ""
        isInputFocused = false

        _Concurrency.Task {
            await viewModel.sendMessage(message)
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ConversationMessage
    @Environment(\.themeEngine) private var themeEngine

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
                    .glassEffect(
                        .regular.tint((message.role == .user ? theme.primaryColor : theme.accentColor).opacity(0.5)),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .foregroundColor(message.role == .user ? .white : theme.textColor)

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
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(theme.accentColor)
            }
        }
    }
}

// MARK: - Citations View

struct CitationsView: View {
    let citations: [ThoughtCitation]
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .font(.caption)
                Text("\(citations.count) related thought\(citations.count == 1 ? "" : "s")")
                    .font(.caption.bold())
            }
            .foregroundStyle(theme.secondaryTextColor)

            ForEach(citations.prefix(3)) { citation in
                NavigationLink {
                    // TODO: Navigate to thought detail
                    Text("Thought Detail: \(citation.thoughtId)")
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(citation.date, style: .date)
                                .font(.caption2)
                            if !citation.tags.isEmpty {
                                Text("•")
                                Text(citation.tags.prefix(2).joined(separator: ", "))
                                    .font(.caption2)
                            }
                        }
                        .foregroundStyle(theme.secondaryTextColor)

                        Text(citation.excerpt)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(theme.textColor)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.inputBackgroundColor)
                    .cornerRadius(8)
                }
            }

            if citations.count > 3 {
                Button("View all \(citations.count) citations") {
                    // TODO: Show all citations
                }
                .font(.caption)
                .foregroundColor(theme.primaryColor)
            }
        }
        .padding(12)
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }
}

// MARK: - Suggested Questions View

struct SuggestedQuestionsView: View {
    let questions: [String]
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(theme.warningColor)
                Text("Ask me:")
                    .font(.caption.bold())
                    .foregroundColor(theme.textColor)
            }

            ForEach(questions, id: \.self) { question in
                Button {
                    // TODO: Send suggested question
                } label: {
                    HStack {
                        Text(question)
                            .font(.caption)
                            .foregroundColor(theme.textColor)
                        Spacer()
                        Image(systemName: "arrow.up.circle")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    }
                    .padding(8)
                    .background(theme.inputBackgroundColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(theme.surfaceColor.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Loading Message View

struct LoadingMessageView: View {
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(theme.accentColor)

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

// MARK: - Error Message View

struct ErrorMessageView: View {
    let error: Error
    let onRetry: () -> Void
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(theme.warningColor)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Button("Try Again", action: onRetry)
                .buttonStyle(.bordered)
                .tint(theme.primaryColor)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        if #available(iOS 26.0, *) {
            ConversationScreen(thoughtService: ThoughtService.shared)
        } else {
            Text("iOS 26+ required")
        }
    }
}
