//
//  SquirrelGreetingCard.swift
//  STASH
//
//  Squirrelsona greeting card showing the current emotional state
//  and a persona-voiced line from the string tables (no AI inference).
//

import SwiftUI

/// Displays the squirrelsona's current emotional state and a greeting line.
///
/// Used in ConversationScreen's header. Refreshes greeting on each `.onAppear`.
struct SquirrelGreetingCard: View {
    let persona: SquirrelPersona
    @Environment(\.themeEngine) private var themeEngine
    @State private var greeting: String = ""

    private let stateEngine = SquirrelStateEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        let state = stateEngine.currentState

        VStack(spacing: 10) {
            // Persona emoji + state indicator
            HStack(spacing: 8) {
                Text(persona.emoji)
                    .font(.system(size: 48))

                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.name)
                        .font(.headline)
                        .foregroundStyle(theme.textColor)

                    HStack(spacing: 4) {
                        Text(state.emoji)
                            .font(.caption)
                        Text(state.label)
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }

                Spacer()
            }

            // Greeting line
            if !greeting.isEmpty {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(theme.textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceColor)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceColor.opacity(0.5))
        )
        .onAppear {
            greeting = stateEngine.greetingLine(for: persona)
        }
    }
}
