//
//  ConversationScreen.swift
//  PersonalAI
//
//  Chat interface for conversational thought exploration
//

import SwiftUI

@available(iOS 26.0, *)
struct ConversationScreen: View {
    @State private var viewModel: ConversationViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

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
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.purple.gradient)

            Text("Chat with Your Thoughts")
                .font(.title2.bold())

            Text("Ask me anything about your captured thoughts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.thoughtCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("\(viewModel.thoughtCount) thoughts available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

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
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask about your thoughts...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
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
                        .foregroundStyle(canSend ? .blue : .gray)
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

    var body: some View {
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
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)

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
                    .foregroundStyle(.secondary)
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
        Group {
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
        }
    }

    private var backgroundColor: Color {
        message.role == .user ? .blue : Color(.secondarySystemBackground)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
}

// MARK: - Citations View

struct CitationsView: View {
    let citations: [ThoughtCitation]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .font(.caption)
                Text("\(citations.count) related thought\(citations.count == 1 ? "" : "s")")
                    .font(.caption.bold())
            }
            .foregroundStyle(.secondary)

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
                        .foregroundStyle(.secondary)

                        Text(citation.excerpt)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }

            if citations.count > 3 {
                Button("View all \(citations.count) citations") {
                    // TODO: Show all citations
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Suggested Questions View

struct SuggestedQuestionsView: View {
    let questions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("Ask me:")
                    .font(.caption.bold())
            }

            ForEach(questions, id: \.self) { question in
                Button {
                    // TODO: Send suggested question
                } label: {
                    HStack {
                        Text(question)
                            .font(.caption)
                        Spacer()
                        Image(systemName: "arrow.up.circle")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Loading Message View

struct LoadingMessageView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.purple)

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.gray)
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
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            Spacer()
        }
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: onRetry)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
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
