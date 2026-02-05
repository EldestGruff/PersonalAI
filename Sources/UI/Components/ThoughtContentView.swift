//
//  ThoughtContentView.swift
//  PersonalAI
//
//  Reusable component for rendering thought content
//  Supports both plain text and rich text (AttributedString)
//

import SwiftUI

// MARK: - Thought Content View

/// Renders thought content with automatic fallback from rich text to plain text
///
/// Features:
/// - Displays AttributedString if available (preserves formatting)
/// - Falls back to plain text content
/// - Consistent styling across app
/// - Backwards compatible with existing thoughts
struct ThoughtContentView: View {
    let thought: Thought
    let font: Font
    let color: Color
    let lineLimit: Int?

    init(
        thought: Thought,
        font: Font = .body,
        color: Color = .primary,
        lineLimit: Int? = nil
    ) {
        self.thought = thought
        self.font = font
        self.color = color
        self.lineLimit = lineLimit
    }

    var body: some View {
        Group {
            if let attributedContent = thought.attributedContent {
                // Rich text display
                Text(attributedContent)
                    .font(font)
            } else {
                // Plain text display (backwards compatible)
                Text(thought.content)
                    .font(font)
                    .foregroundColor(color)
            }
        }
        .lineLimit(lineLimit)
    }
}

// MARK: - Previews

#Preview("Plain Text Thought") {
    ThoughtContentView(
        thought: Thought(
            id: UUID(),
            userId: UUID(),
            content: "This is a plain text thought without any formatting.",
            attributedContent: nil,
            tags: ["test"],
            status: .active,
            context: Context.empty(),
            createdAt: Date(),
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )
    )
    .padding()
}

#Preview("Rich Text Thought") {
    var attributed = AttributedString("This has bold and italic formatting!")
    if let boldRange = attributed.range(of: "bold") {
        attributed[boldRange].inlinePresentationIntent = .stronglyEmphasized
    }
    if let italicRange = attributed.range(of: "italic") {
        attributed[italicRange].inlinePresentationIntent = .emphasized
    }

    return ThoughtContentView(
        thought: Thought(
            id: UUID(),
            userId: UUID(),
            content: "This has bold and italic formatting!",
            attributedContent: attributed,
            tags: ["test"],
            status: .active,
            context: Context.empty(),
            createdAt: Date(),
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )
    )
    .padding()
}
