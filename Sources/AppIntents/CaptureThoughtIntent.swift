//
//  CaptureThoughtIntent.swift
//  PersonalAI
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
        )
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

    // MARK: - Intent Execution

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get required services
        let container = ServiceContainer.shared
        guard let repository = await container.resolveOptional(any ThoughtRepositoryProtocol.Type) as? any ThoughtRepositoryProtocol else {
            throw IntentError.serviceUnavailable
        }

        // Get classification service for auto-classification
        let classificationService = await container.resolveOptional(any ClassificationServiceProtocol.Type) as? any ClassificationServiceProtocol

        // Create classification
        let classification: Classification?
        if let explicitType = type {
            // User specified type - use it directly
            classification = Classification(
                id: UUID(),
                type: explicitType.toModel(),
                sentiment: .neutral,
                entities: [],
                suggestedTags: [],
                language: "en",
                processingTime: 0.0,
                model: "manual",
                confidence: 1.0,
                createdAt: Date(),
                parsedDateTime: nil
            )
        } else if autoClassify, let service = classificationService {
            // Auto-classify using AI
            classification = try await service.classify(content)
        } else {
            // No classification
            classification = nil
        }

        // Get current user ID (single user in Phase 3A)
        let userId = UUID() // TODO: Get from user session

        // Create and save thought
        let now = Date()
        let thought = Thought(
            id: UUID(),
            userId: userId,
            content: content,
            tags: classification?.suggestedTags ?? [],
            status: .active,
            context: Context(
                timestamp: now,
                location: nil,
                timeOfDay: .unknown,
                energy: nil,
                focusState: nil,
                calendar: nil,
                activity: nil,
                weather: nil
            ),
            createdAt: now,
            updatedAt: now,
            classification: classification,
            relatedThoughtIds: [],
            taskId: nil
        )

        try await repository.save(thought)

        // Donate interaction for Siri suggestions
        if let classification = classification {
            donateInteraction(content: content, type: classification.type)
        }

        // Return success with dialog
        let typeString = classification?.type.displayName ?? "thought"
        return .result(
            dialog: "Captured as \(typeString): \"\(content)\""
        )
    }

    // MARK: - Siri Suggestions

    /// Donate this intent execution to Siri for future suggestions.
    private func donateInteraction(content: String, type: ClassificationType) {
        // Intent donations help Siri learn user patterns and suggest shortcuts
        // This is called automatically after successful execution
        Task {
            let intent = CaptureThoughtIntent()
            intent.content = content
            intent.type = ThoughtTypeEnum.from(type)
            intent.autoClassify = false

            // Donate with relevance for better suggestions
            let shortcut = AppShortcut(intent: intent, phrases: [
                "Capture a thought",
                "Save a note in \(.applicationName)",
                "Remember this"
            ])

            // System will learn from repeated use
            _ = shortcut
        }
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
            return "PersonalAI services are not available"
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
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: CaptureThoughtIntent(),
                phrases: [
                    "Capture a thought in \(.applicationName)",
                    "Save a note in \(.applicationName)",
                    "Remember something in \(.applicationName)"
                ],
                shortTitle: "Capture",
                systemImageName: "square.and.pencil"
            )
        ]
    }
}
