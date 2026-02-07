//
//  ThoughtTypeEnum.swift
//  STASH
//
//  App Intents enum for thought classification types
//

import AppIntents
import Foundation

/// App Intents compatible enum for thought types
///
/// Used as parameter in Siri commands like:
/// - "Capture a reminder"
/// - "Add an idea"
/// - "Save this as a note"
@available(iOS 26.0, *)
enum ThoughtTypeEnum: String, AppEnum {
    case note
    case idea
    case reminder
    case event
    case question

    // MARK: - AppEnum Conformance

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Thought Type")
    }

    static var caseDisplayRepresentations: [ThoughtTypeEnum: DisplayRepresentation] {
        [
            .note: DisplayRepresentation(
                title: "Note",
                subtitle: "Reference information or observations",
                image: DisplayRepresentation.Image(systemName: "note.text")
            ),
            .idea: DisplayRepresentation(
                title: "Idea",
                subtitle: "Creative thoughts and possibilities",
                image: DisplayRepresentation.Image(systemName: "lightbulb")
            ),
            .reminder: DisplayRepresentation(
                title: "Reminder",
                subtitle: "Tasks and things to do",
                image: DisplayRepresentation.Image(systemName: "bell")
            ),
            .event: DisplayRepresentation(
                title: "Event",
                subtitle: "Scheduled activities and meetings",
                image: DisplayRepresentation.Image(systemName: "calendar")
            ),
            .question: DisplayRepresentation(
                title: "Question",
                subtitle: "Things to research or answer",
                image: DisplayRepresentation.Image(systemName: "questionmark.circle")
            )
        ]
    }

    // MARK: - Model Conversion

    /// Convert to domain model ClassificationType
    func toModel() -> ClassificationType {
        switch self {
        case .note:
            return .note
        case .idea:
            return .idea
        case .reminder:
            return .reminder
        case .event:
            return .event
        case .question:
            return .question
        }
    }

    /// Create from domain model
    init(from type: ClassificationType) {
        switch type {
        case .note:
            self = .note
        case .idea:
            self = .idea
        case .reminder:
            self = .reminder
        case .event:
            self = .event
        case .question:
            self = .question
        }
    }
}
