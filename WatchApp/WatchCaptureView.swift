//
//  WatchCaptureView.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Single-screen Watch UI. Tap the mic → dictate → thought stashed.
//  Shows live partial transcript while recording.
//  Plays a weighted-random acknowledgment animation on capture.
//

import SwiftUI

// MARK: - Acknowledgment Kind

/// Three reward tiers matching the variable-reward philosophy from the iPhone app.
private enum AcknowledgmentKind {
    case common     // 65% — acorn catch
    case uncommon   // 25% — squirrel spin
    case rare       // 10% — sparkle burst

    static func random() -> AcknowledgmentKind {
        switch Double.random(in: 0..<1) {
        case ..<0.65: return .common
        case ..<0.90: return .uncommon
        default:      return .rare
        }
    }

    var emoji: String {
        switch self {
        case .common:   return "🌰"
        case .uncommon: return "🐿️"
        case .rare:     return "✨"
        }
    }

    var label: String {
        switch self {
        case .common:   return "Stashed!"
        case .uncommon: return "Nice one!"
        case .rare:     return "Shiny!"
        }
    }
}

// MARK: - Watch Capture View

struct WatchCaptureView: View {
    @State private var isRecording = false
    @State private var transcript = ""
    @State private var acknowledgment: AcknowledgmentKind?
    @State private var capturedCount = 0
    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let ack = acknowledgment {
                AcknowledgmentView(kind: ack)
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                acknowledgment = nil
                            }
                        }
                    }
            } else {
                mainContent
            }
        }
        .task {
            let granted = await WatchSpeechService.shared.requestPermissions()
            permissionDenied = !granted
            capturedCount = UserDefaults.standard.integer(forKey: "watchCapturedCount")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 6) {
            // Capture count badge (top)
            if capturedCount > 0 {
                Text("\(capturedCount) stashed")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status / transcript
            Group {
                if permissionDenied {
                    Text("Enable speech in Settings")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if isRecording && !transcript.isEmpty {
                    Text(transcript)
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .animation(.default, value: transcript)
                } else if !isRecording {
                    Text("Tap to capture")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Mic button
            Button(action: handleMicTap) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.accentColor)
                        .frame(width: 60, height: 60)
                        .scaleEffect(isRecording ? 1.08 : 1.0)
                        .animation(
                            isRecording
                                ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                                : .default,
                            value: isRecording
                        )

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(permissionDenied)

            Spacer()
        }
        .padding(8)
    }

    // MARK: - Actions

    private func handleMicTap() {
        if isRecording {
            stopCapture()
        } else {
            startCapture()
        }
    }

    private func startCapture() {
        guard !isRecording else { return }
        isRecording = true
        transcript = ""

        Task {
            do {
                let stream = try await WatchSpeechService.shared.startListening()
                for await partial in stream {
                    await MainActor.run { transcript = partial }
                }
            } catch {
                await MainActor.run { isRecording = false }
            }
        }
    }

    private func stopCapture() {
        guard isRecording else { return }
        isRecording = false

        Task {
            let final = await WatchSpeechService.shared.stopListening()
            let text = (!final.isEmpty ? final : transcript)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else {
                await MainActor.run { transcript = "" }
                return
            }

            await WatchQueueManager.shared.enqueue(text)
            WatchConnectivityManager.shared.flushQueue()

            await MainActor.run {
                transcript = ""
                capturedCount += 1
                UserDefaults.standard.set(capturedCount, forKey: "watchCapturedCount")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    acknowledgment = .random()
                }
            }
        }
    }
}

// MARK: - Acknowledgment View

private struct AcknowledgmentView: View {
    let kind: AcknowledgmentKind

    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = 0
    @State private var secondaryScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 6) {
            Text(kind.emoji)
                .font(.system(size: 44))
                .scaleEffect(scale * secondaryScale)
                .rotationEffect(.degrees(rotation))
                .onAppear { animate() }

            Text(kind.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .opacity(scale > 0.5 ? 1 : 0)
        }
    }

    private func animate() {
        // All tiers: pop in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            scale = 1.0
        }
        switch kind {
        case .uncommon:
            withAnimation(.linear(duration: 0.45).delay(0.1)) {
                rotation = 360
            }
        case .rare:
            // Double pulse
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4).delay(0.1)) {
                secondaryScale = 1.25
            }
            withAnimation(.easeInOut(duration: 0.2).delay(0.35)) {
                secondaryScale = 1.0
            }
        case .common:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    WatchCaptureView()
}
