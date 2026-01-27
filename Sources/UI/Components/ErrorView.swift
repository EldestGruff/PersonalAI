//
//  ErrorView.swift
//  PersonalAI
//
//  Phase 3A Spec 3: Error Display Components
//  User-friendly error display views
//

import SwiftUI

// MARK: - Error Banner

/// A banner that displays an error at the top of a view.
struct ErrorBanner: View {
    let error: AppError
    let onDismiss: (() -> Void)?

    init(error: AppError, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Error Card

/// A card-style error display for inline errors.
struct ErrorCard: View {
    let error: AppError
    let retryAction: (() -> Void)?

    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundColor(.red)
                .accessibilityHidden(true)

            Text(error.errorDescription ?? "An error occurred")
                .font(.headline)
                .multilineTextAlignment(.center)

            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Empty State View

/// A view displayed when there's no content to show.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Loading View

/// A view displayed while content is loading.
struct LoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Error Banner") {
    VStack {
        ErrorBanner(
            error: .networkError,
            onDismiss: {}
        )

        ErrorBanner(
            error: .permissionDenied("Location"),
            onDismiss: {}
        )
    }
}

#Preview("Error Card") {
    ErrorCard(
        error: .storageError,
        retryAction: {}
    )
    .padding()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "doc.text.magnifyingglass",
        title: "No Thoughts Yet",
        message: "Capture your first thought to get started.",
        actionTitle: "Capture Thought",
        action: {}
    )
}

#Preview("Loading View") {
    LoadingView("Gathering context...")
}
