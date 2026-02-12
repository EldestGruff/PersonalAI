//
//  OpenVoiceCaptureIntent.swift
//  STASH
//
//  Phase 3B: Voice Capture Intent
//  App Intent that opens STASH to voice capture screen (for Back Tap)
//

import AppIntents
import Foundation

/// App Intent for opening the app directly to voice capture.
///
/// ## Usage
///
/// **Back Tap:**
/// - Settings → Accessibility → Touch → Back Tap → Double Tap → Shortcuts → Voice Capture
///
/// **Action Button (iPhone 15 Pro+):**
/// - Settings → Action Button → Shortcut → Voice Capture
///
/// **Control Center (Future):**
/// - Control Center widget triggers this intent
///
/// ## How It Works
///
/// 1. Intent sets `pendingVoiceCapture` flag in shared UserDefaults (app group)
/// 2. `openAppWhenRun = true` launches the app (or brings to foreground)
/// 3. App checks flag when scene becomes active
/// 4. App presents `VoiceCaptureScreen` as full-screen cover
/// 5. App clears flag after presenting
///
/// This pattern works across all app states (terminated, background, foreground).
struct OpenVoiceCaptureIntent: AppIntent {
    // MARK: - Intent Metadata

    static let title: LocalizedStringResource = "Voice Capture"

    static let description = IntentDescription(
        "Open STASH and start voice capture",
        categoryName: "Capture",
        searchKeywords: ["voice", "microphone", "speak", "talk", "dictate", "record"]
    )

    static let openAppWhenRun: Bool = true // Required for Back Tap

    // MARK: - Intent Execution

    @MainActor
    func perform() async throws -> some IntentResult {
        // Set flag in shared UserDefaults (app group)
        let defaults = UserDefaults(suiteName: "group.com.withershins.stash")
        defaults?.set(true, forKey: "pendingVoiceCapture")
        defaults?.synchronize()

        // App will check this flag and present VoiceCaptureScreen
        return .result()
    }
}
