//
//  FlowLayout.swift
//  STASH
//
//  Phase 3A Spec 3: Flow Layout
//  Wrapping layout for tags and chips
//

import SwiftUI

// MARK: - Flow Layout

/// A layout that arranges subviews in a horizontal flow, wrapping to new lines as needed.
///
/// Useful for displaying tags, chips, or other variable-width content that should
/// wrap naturally within the available space.
///
/// Example:
/// ```swift
/// FlowLayout(spacing: 8) {
///     ForEach(tags, id: \.self) { tag in
///         TagChip(tag: tag)
///     }
/// }
/// ```
struct FlowLayout: Layout {
    /// Horizontal and vertical spacing between items
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Check if we need to wrap to next line
            if currentX + size.width > width && currentX > 0 {
                currentY += lineHeight + spacing
                currentX = 0
                lineHeight = 0
            }

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Check if we need to wrap to next line
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview("Flow Layout") {
    FlowLayout(spacing: 8) {
        ForEach(["Swift", "SwiftUI", "iOS", "Personal AI", "Machine Learning", "NLP"], id: \.self) { tag in
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(16)
        }
    }
    .padding()
}
