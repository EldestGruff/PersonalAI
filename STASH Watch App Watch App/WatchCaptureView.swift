//
//  WatchCaptureView.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Single-screen Watch UI. Tap → record → audio sent to iPhone for transcription.
//  Waveform animation provides live recording feedback.
//  Acknowledgment animation plays immediately after recording stops.
//

import SwiftUI
import WatchKit

// MARK: - Acknowledgment Kind

private enum AcknowledgmentKind {
    case common     // 65% — acorn
    case uncommon   // 25% — squirrel
    case rare       // 10% — sparkle

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
        case .common:   return "Sent!"
        case .uncommon: return "Nice one!"
        case .rare:     return "Shiny!"
        }
    }
}

// MARK: - Watch Capture View

struct WatchCaptureView: View {
    @State private var isRecording = false
    @State private var acknowledgment: AcknowledgmentKind?
    @State private var capturedCount = 0
    @State private var permissionDenied = false
    @State private var audioLevel: Float = 0
    @State private var levelTimer: Timer?
    @ObservedObject private var connectivity = WatchConnectivityManager.shared

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
        VStack(spacing: 8) {
            if capturedCount > 0 {
                Text("\(capturedCount) captured")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            if connectivity.pendingCount > 0 {
                Text("↑ \(connectivity.pendingCount) syncing")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
            }

            Spacer()

            Group {
                if permissionDenied {
                    Text("Enable microphone in Settings")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if isRecording {
                    WaveformView(level: audioLevel)
                        .frame(height: 24)
                        .padding(.horizontal, 12)
                } else {
                    Text("Tap to capture")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

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
        if isRecording { stopCapture() } else { startCapture() }
    }

    private func startCapture() {
        guard !isRecording else { return }
        Task {
            do {
                try await WatchSpeechService.shared.startRecording()
                await MainActor.run {
                    WKInterfaceDevice.current().play(.start)
                    isRecording = true
                    startLevelPolling()
                }
            } catch {
                // Permission or hardware error
            }
        }
    }

    private func stopCapture() {
        guard isRecording else { return }
        stopLevelPolling()
        WKInterfaceDevice.current().play(.stop)
        isRecording = false

        Task {
            guard let url = await WatchSpeechService.shared.stopRecording() else { return }
            WatchConnectivityManager.shared.sendAudio(fileURL: url)

            await MainActor.run {
                capturedCount += 1
                UserDefaults.standard.set(capturedCount, forKey: "watchCapturedCount")
                WKInterfaceDevice.current().play(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    acknowledgment = .random()
                }
            }
        }
    }

    // MARK: - Level Polling

    private func startLevelPolling() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task {
                let level = await WatchSpeechService.shared.currentPower()
                await MainActor.run { audioLevel = level }
            }
        }
    }

    private func stopLevelPolling() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }
}

// MARK: - Waveform View

private struct WaveformView: View {
    let level: Float
    private let barCount = 9

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 4, height: barHeight(index: i))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let center = barCount / 2
        let distance = abs(index - center)
        let peak = CGFloat(level) * 20
        return max(4, peak - CGFloat(distance) * 3)
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { scale = 1.0 }
        switch kind {
        case .uncommon:
            withAnimation(.linear(duration: 0.45).delay(0.1)) { rotation = 360 }
        case .rare:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4).delay(0.1)) { secondaryScale = 1.25 }
            withAnimation(.easeInOut(duration: 0.2).delay(0.35)) { secondaryScale = 1.0 }
        case .common:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    WatchCaptureView()
}
