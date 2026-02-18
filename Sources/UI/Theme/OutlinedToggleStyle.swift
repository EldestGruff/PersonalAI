//
//  OutlinedToggleStyle.swift
//  STASH
//
//  Custom toggle style for themes where the system off-state track
//  lacks sufficient contrast (e.g. Minimalist on white backgrounds).
//
//  OFF: clear fill + visible border
//  ON:  filled with primaryColor + white thumb
//

import SwiftUI

// MARK: - Outlined Toggle Style

struct OutlinedToggleStyle: ToggleStyle {
    let color: Color

    private let trackWidth: CGFloat = 51
    private let trackHeight: CGFloat = 31
    private let thumbSize: CGFloat = 27
    private let thumbTravel: CGFloat = 10

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            toggle(isOn: configuration.isOn)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }

    private func toggle(isOn: Bool) -> some View {
        ZStack {
            // Track
            Capsule()
                .fill(isOn ? color : Color.clear)
                .overlay(Capsule().stroke(color, lineWidth: 1.5))
                .frame(width: trackWidth, height: trackHeight)

            // Thumb
            Circle()
                .fill(isOn ? Color.white : color)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: isOn ? thumbTravel : -thumbTravel)
                .animation(.easeInOut(duration: 0.2), value: isOn)
        }
        .frame(width: trackWidth, height: trackHeight)
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "on" : "off")
    }
}

// MARK: - View Extension

extension View {
    /// Applies OutlinedToggleStyle when the theme requests it,
    /// otherwise falls back to system toggle with theme tint.
    @ViewBuilder
    func themedToggle(_ theme: any ThemeVariant) -> some View {
        if theme.usesOutlinedToggles {
            self.toggleStyle(OutlinedToggleStyle(color: theme.primaryColor))
        } else {
            self.tint(theme.primaryColor)
        }
    }
}
