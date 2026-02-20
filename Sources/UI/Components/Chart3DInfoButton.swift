//
//  Chart3DInfoButton.swift
//  STASH
//
//  Issue #25: 3D Visualizations - Info Button Component
//  Reusable info button and description sheet for 3D charts
//

import SwiftUI

// MARK: - Chart 3D Info Button

/// Info button that reveals chart explanation when tapped
struct Chart3DInfoButton: View {
    let metadata: Chart3DMetadata
    @State private var showInfo = false
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(theme.primaryColor)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showInfo) {
            Chart3DInfoSheet(metadata: metadata)
        }
    }
}

// MARK: - Chart 3D Info Sheet

/// Full-screen sheet explaining what the 3D chart represents
struct Chart3DInfoSheet: View {
    let metadata: Chart3DMetadata
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What This Shows")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            Text(metadata.description)
                                .font(.body)
                                .foregroundStyle(theme.secondaryTextColor)
                        }

                        Divider()
                            .background(theme.dividerColor)

                        // Axes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Axes")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            AxisLabel(axis: "X", label: metadata.xAxisLabel, theme: theme)
                            AxisLabel(axis: "Y", label: metadata.yAxisLabel, theme: theme)
                            AxisLabel(axis: "Z", label: metadata.zAxisLabel, theme: theme)
                        }

                        Divider()
                            .background(theme.dividerColor)

                        // Key Insights
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Insights")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            ForEach(Array(metadata.insights.enumerated()), id: \.offset) { _, insight in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(theme.primaryColor)
                                    Text(insight)
                                        .font(.body)
                                        .foregroundStyle(theme.textColor)
                                }
                            }
                        }

                        Divider()
                            .background(theme.dividerColor)

                        // How to Read
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to Read This Chart")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            Text(metadata.interpretation)
                                .font(.body)
                                .foregroundStyle(theme.secondaryTextColor)
                        }

                        // Interaction Tips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interaction Tips")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            VStack(alignment: .leading, spacing: 6) {
                                InteractionTip(icon: "hand.draw.fill", text: "Drag to rotate the view", theme: theme)
                                InteractionTip(icon: "arrow.up.and.down", text: "Pinch to zoom in/out", theme: theme)
                                InteractionTip(icon: "hand.tap.fill", text: "Tap points for details", theme: theme)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(metadata.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(theme.primaryColor)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct AxisLabel: View {
    let axis: String
    let label: String
    let theme: any ThemeVariant

    var body: some View {
        HStack(spacing: 12) {
            Text(axis)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(theme.primaryColor)
                )

            Text(label)
                .font(.body)
                .foregroundStyle(theme.textColor)
        }
    }
}

private struct InteractionTip: View {
    let icon: String
    let text: String
    let theme: any ThemeVariant

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(theme.primaryColor)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
        }
    }
}

// MARK: - Previews

#Preview("Info Button") {
    Chart3DInfoButton(metadata: .thoughtSpace)
}

#Preview("Info Sheet") {
    Chart3DInfoSheet(metadata: .thoughtSpace)
}
