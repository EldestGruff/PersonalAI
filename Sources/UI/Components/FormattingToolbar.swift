//
//  FormattingToolbar.swift
//  STASH
//
//  Rich text formatting toolbar for iOS 26+
//  Provides bold, italic, highlight, link, and list formatting options
//

import SwiftUI

// MARK: - Formatting Toolbar

/// Rich text formatting toolbar for TextEditor
///
/// Features:
/// - Bold, Italic formatting
/// - Highlight colors (Yellow, Blue, Green, Red)
/// - Lists (bullet, numbered)
/// - Links
/// - Liquid Glass design
@available(iOS 26.0, *)
struct FormattingToolbar: View {
    @Binding var attributedText: AttributedString
    @State private var selectedRange: Range<AttributedString.Index>?
    @State private var showHighlightPicker = false
    @State private var showLinkInput = false

    var body: some View {
        HStack(spacing: 16) {
            // Bold
            FormatButton(
                icon: "bold",
                label: "Bold",
                isActive: false
            ) {
                applyFormat(.bold)
            }

            // Italic
            FormatButton(
                icon: "italic",
                label: "Italic",
                isActive: false
            ) {
                applyFormat(.italic)
            }

            // Highlight
            Menu {
                Button {
                    applyHighlight(.yellow)
                } label: {
                    Label("Yellow", systemImage: "highlighter")
                        .foregroundColor(.yellow)
                }

                Button {
                    applyHighlight(.blue)
                } label: {
                    Label("Blue", systemImage: "highlighter")
                        .foregroundColor(.blue)
                }

                Button {
                    applyHighlight(.green)
                } label: {
                    Label("Green", systemImage: "highlighter")
                        .foregroundColor(.green)
                }

                Button {
                    applyHighlight(.red)
                } label: {
                    Label("Red", systemImage: "highlighter")
                        .foregroundColor(.red)
                }

                Divider()

                Button {
                    removeHighlight()
                } label: {
                    Label("Remove Highlight", systemImage: "xmark")
                }
            } label: {
                FormatButton(
                    icon: "highlighter",
                    label: "Highlight",
                    isActive: false
                ) {}
            }

            Spacer()

            // List
            Menu {
                Button {
                    applyList(.bullet)
                } label: {
                    Label("Bullet List", systemImage: "list.bullet")
                }

                Button {
                    applyList(.numbered)
                } label: {
                    Label("Numbered List", systemImage: "list.number")
                }
            } label: {
                FormatButton(
                    icon: "list.bullet",
                    label: "List",
                    isActive: false
                ) {}
            }

            // Link
            FormatButton(
                icon: "link",
                label: "Link",
                isActive: false
            ) {
                showLinkInput = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .sheet(isPresented: $showLinkInput) {
            LinkInputSheet(attributedText: $attributedText)
        }
    }

    // MARK: - Formatting Actions

    private func applyFormat(_ format: TextFormat) {
        // Get current selection or entire text
        let range = selectedRange ?? attributedText.startIndex..<attributedText.endIndex

        switch format {
        case .bold:
            attributedText[range].inlinePresentationIntent = .stronglyEmphasized
        case .italic:
            attributedText[range].inlinePresentationIntent = .emphasized
        case .code:
            attributedText[range].inlinePresentationIntent = .code
        }
    }

    private func applyHighlight(_ color: Color) {
        let range = selectedRange ?? attributedText.startIndex..<attributedText.endIndex
        attributedText[range].backgroundColor = color.opacity(0.3)
    }

    private func removeHighlight() {
        let range = selectedRange ?? attributedText.startIndex..<attributedText.endIndex
        attributedText[range].backgroundColor = nil
    }

    private func applyList(_ listType: ListType) {
        // Note: List formatting requires more complex implementation
        // For now, this is a placeholder
    }

    enum TextFormat {
        case bold
        case italic
        case code
    }

    enum ListType {
        case bullet
        case numbered
    }
}

// MARK: - Format Button

/// Individual format button with icon and accessibility
@available(iOS 26.0, *)
struct FormatButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isActive ? .accentColor : .primary)
                .frame(width: 36, height: 36)
                .background(
                    isActive ?
                    Color.accentColor.opacity(0.1) :
                    Color.clear
                )
                .clipShape(Circle())
        }
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to apply \(label.lowercased()) formatting")
    }
}

// MARK: - Link Input Sheet

/// Sheet for adding hyperlinks
@available(iOS 26.0, *)
struct LinkInputSheet: View {
    @Binding var attributedText: AttributedString
    @State private var urlText = ""
    @State private var linkText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Link Details") {
                    TextField("Display Text", text: $linkText)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                    TextField("URL", text: $urlText)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Link")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        insertLink()
                        dismiss()
                    }
                    .disabled(urlText.isEmpty || linkText.isEmpty)
                }
            }
        }
    }

    private func insertLink() {
        guard let url = URL(string: urlText) else { return }

        var linkString = AttributedString(linkText)
        linkString.link = url
        linkString.foregroundColor = .blue
        linkString.underlineStyle = .single

        // Append to current text
        attributedText.append(linkString)
    }
}

// MARK: - Previews

#Preview("Formatting Toolbar") {
    @Previewable @State var text = AttributedString("Sample text")

    VStack {
        Spacer()

        if #available(iOS 26.0, *) {
            FormattingToolbar(attributedText: $text)
                .padding()
        } else {
            Text("iOS 26.0+ required")
        }
    }
}
