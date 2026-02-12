//
//  CaptureThoughtIntent.swift
//  STASH
//
//  Phase 2: iOS 26 Modernization - App Intents
//  Siri and Shortcuts intent for capturing thoughts
//

import AppIntents
import Foundation

/// App Intent for capturing a new thought via Siri or Shortcuts.
///
/// ## Usage Examples
///
/// **Siri:**
/// - "Hey Siri, capture a thought"
/// - "Hey Siri, save this in Personal AI"
///
/// **Shortcuts:**
/// - Quick capture with voice dictation
/// - Automated capture triggered by location/time
/// - Batch capture from other apps
///
/// ## Features
///
/// - Voice input support via Siri
/// - Optional type specification (note, reminder, event, etc.)
/// - Automatic classification if type not specified
/// - Background execution (no app launch required)
struct CaptureThoughtIntent: AppIntent {
    // MARK: - Intent Metadata

    static let title: LocalizedStringResource = "Capture Thought"

    static let description = IntentDescription(
        "Quickly capture a thought, note, or idea",
        categoryName: "Capture",
        searchKeywords: ["save", "note", "remember", "capture", "thought"]
    )

    static let openAppWhenRun: Bool = false // Run in background

    // MARK: - Parameters

    @Parameter(
        title: "Content",
        description: "What you want to capture",
        inputOptions: .init(
            multiline: true,
            autocorrect: true,
            smartQuotes: true,
            smartDashes: true
        ),
        requestValueDialog: "What's on your mind?"
    )
    var content: String

    @Parameter(
        title: "Type",
        description: "Classification type (optional - auto-detected if not specified)",
        default: nil
    )
    var type: ThoughtTypeEnum?

    @Parameter(
        title: "Auto-classify",
        description: "Use AI to automatically classify the thought",
        default: true
    )
    var autoClassify: Bool

    // MARK: - Parameter Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$content)")
    }

    // MARK: - Intent Execution

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Use ThoughtRepository directly (no protocol)
        let repository = ThoughtRepository.shared

        // Create classification
        let classification: Classification?
        if let explicitType = type {
            // User specified type - use it directly
            classification = Classification(
                id: UUID(),
                type: explicitType.toModel(),
                confidence: 1.0,
                entities: [],
                suggestedTags: [],
                sentiment: .neutral,
                language: "en",
                processingTime: 0.0,
                model: "manual",
                createdAt: Date(),
                parsedDateTime: nil
            )
        } else if autoClassify {
            // TODO: Auto-classify using AI when ClassificationService is accessible
            // For now, default to no classification
            classification = nil
        } else {
            // No classification
            classification = nil
        }

        // Get current user ID (single user in Phase 3A)
        // TODO: Get from actual user session
        let userId = UUID()

        // Create and save thought
        let now = Date()
        let thought = Thought(
            id: UUID(),
            userId: userId,
            content: content,
                    attributedContent: nil,
            tags: classification?.suggestedTags ?? [],
            status: .active,
            context: Context(
                timestamp: now,
                location: nil,
                timeOfDay: TimeOfDay.from(date: now),
                energy: .medium,
                focusState: .scattered,
                calendar: nil,
                activity: nil,
                weather: nil,
                stateOfMind: nil,
                energyBreakdown: nil
            ),
            createdAt: now,
            updatedAt: now,
            classification: classification,
            relatedThoughtIds: [],
            taskId: nil
        )

        _ = try await repository.create(thought)

        // Donate interaction for Siri suggestions
        if let classification = classification {
            donateInteraction(content: content, type: classification.type)
        }

        // Return success with dialog
        let typeString = classification?.type.displayName ?? "thought"
        let dialogString = "Captured as \(typeString): \"\(content)\""
        return .result(
            dialog: IntentDialog(stringLiteral: dialogString)
        )
    }

    // MARK: - Siri Suggestions

    /// Donate this intent execution to Siri for future suggestions.
    private func donateInteraction(content: String, type: ClassificationType) {
        // Intent donations help Siri learn user patterns and suggest shortcuts
        // Donations are automatic through AppIntents framework
        // No manual donation needed - the framework handles this
    }
}

// MARK: - Intent Errors

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case serviceUnavailable
    case invalidInput
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .serviceUnavailable:
            return "STASH services are not available"
        case .invalidInput:
            return "The content provided is invalid"
        case .saveFailed:
            return "Failed to save the thought"
        }
    }
}

// MARK: - App Shortcuts

/// Predefined shortcuts that appear in Shortcuts app.
struct ThoughtAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureThoughtIntent(),
            phrases: [
                "Capture a thought in \(.applicationName)",
                "Save a note in \(.applicationName)",
                "Remember something in \(.applicationName)",
                "Stash a thought in \(.applicationName)",
                "Stash this in \(.applicationName)",
                "Quick thought in \(.applicationName)"
            ],
            shortTitle: "Stash Thought",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: OpenVoiceCaptureIntent(),
            phrases: [
                "Voice capture in \(.applicationName)",
                "Talk to \(.applicationName)",
                "Speak to \(.applicationName)"
            ],
            shortTitle: "Voice Capture",
            systemImageName: "mic.fill"
        )
    }
}
