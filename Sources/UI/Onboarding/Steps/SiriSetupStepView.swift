//
//  SiriSetupStepView.swift
//  STASH
//
//  Onboarding step: teaches user the Siri phrases for voice capture.
//

import SwiftUI

struct SiriSetupStepView: View {
    let persona: SquirrelPersona
    let onContinue: () -> Void

    private let phrases = [
        "Hey Siri, stash a thought",
        "Hey Siri, stash a thought in STASH",
        "Hey Siri, save a note in STASH",
        "Hey Siri, remember something in STASH",
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(.purple)

            // Persona-voiced intro
            VStack(spacing: 8) {
                Text("Talk to Siri")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(OnboardingCopy.siriSetupIntro(for: persona))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Phrase chips
            VStack(alignment: .leading, spacing: 0) {
                Text("Pick whichever feels natural — all of them work.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(phrases, id: \.self) { phrase in
                        HStack {
                            Image(systemName: "mic.fill")
                                .font(.caption)
                                .foregroundStyle(.purple)
                            Text(phrase)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // CTA
            Button(action: onContinue) {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    SiriSetupStepView(
        persona: SquirrelPersona.supportiveListener,
        onContinue: {}
    )
}
