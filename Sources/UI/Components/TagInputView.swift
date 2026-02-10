//
//  TagInputView.swift
//  STASH
//
//  Phase 3A Spec 3: Tag Input Component
//  Reusable tag input with flow layout
//

import SwiftUI

// MARK: - Tag Input View

/// A view for managing a list of tags with add/remove functionality.
///
/// Features:
/// - Displays existing tags in a flow layout
/// - Removable tags with X button
/// - Text field for adding new tags
/// - Maximum tag limit (default 5)
struct TagInputView: View {
    /// Binding to the list of tags
    @Binding var tags: [String]

    /// Callback when a tag is added
    let onAdd: (String) -> Void

    /// Callback when a tag is removed
    let onRemove: (String) -> Void

    /// Maximum number of tags allowed
    var maxTags: Int

    /// State for the new tag input
    @State private var newTagText: String = ""

    /// Whether the input field is focused
    @SwiftUI.FocusState private var isInputFocused: Bool

    @Environment(\.themeEngine) private var themeEngine

    init(
        tags: Binding<[String]>,
        onAdd: @escaping (String) -> Void,
        onRemove: @escaping (String) -> Void,
        maxTags: Int = 5
    ) {
        self._tags = tags
        self.onAdd = onAdd
        self.onRemove = onRemove
        self.maxTags = maxTags
    }

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 12) {
            // Existing tags
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(
                            tag: tag,
                            isRemovable: true,
                            onRemove: { onRemove(tag) }
                        )
                    }
                }
            }

            // Add tag input
            if tags.count < maxTags {
                HStack(spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundColor(theme.secondaryTextColor)
                        .accessibilityHidden(true)

                    TextField("Add tag...", text: $newTagText)
                        .focused($isInputFocused)
                        .foregroundColor(theme.textColor)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("addTagTextField")
                        .onSubmit {
                            addTag()
                        }

                    if !newTagText.isEmpty {
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.primaryColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add tag")
                        .accessibilityIdentifier("addTagButton")
                    }
                }
                .padding(10)
                .background(theme.inputBackgroundColor)
                .cornerRadius(8)
            } else {
                Text("Maximum \(maxTags) tags")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
    }

    private func addTag() {
        let trimmed = newTagText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        guard !trimmed.isEmpty else { return }

        onAdd(trimmed)
        newTagText = ""
    }
}

// MARK: - Tag Chip

/// A single tag chip with optional remove button.
struct TagChip: View {
    let tag: String
    var isRemovable: Bool = false
    var onRemove: (() -> Void)?
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline)

            if isRemovable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.tagBackgroundColor)
        .foregroundColor(theme.tagTextColor)
        .cornerRadius(16)
    }
}

// MARK: - Tag Display View

/// A read-only view for displaying tags in a flow layout.
struct TagDisplayView: View {
    let tags: [String]

    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Tag Input - Empty") {
    TagInputPreviewWrapper(initialTags: [])
}

#Preview("Tag Input - With Tags") {
    TagInputPreviewWrapper(initialTags: ["swift", "ios", "ai"])
}

#Preview("Tag Display") {
    TagDisplayView(tags: ["swift", "swiftui", "machine-learning"])
        .padding()
}

// Preview helper
private struct TagInputPreviewWrapper: View {
    @State var tags: [String]

    init(initialTags: [String]) {
        _tags = State(initialValue: initialTags)
    }

    var body: some View {
        TagInputView(
            tags: $tags,
            onAdd: { tag in
                if !tags.contains(tag) {
                    tags.append(tag)
                }
            },
            onRemove: { tag in
                tags.removeAll { $0 == tag }
            }
        )
        .padding()
    }
}
