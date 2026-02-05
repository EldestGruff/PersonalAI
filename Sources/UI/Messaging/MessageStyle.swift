//
//  MessageStyle.swift
//  PersonalAI
//
//  Communication style definitions for squirrel-sona messaging
//

import Foundation

// MARK: - Message Style Enum

enum MessageStyle: String, Codable, CaseIterable, Identifiable {
    case chatty
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chatty: return "Chatty"
        case .minimal: return "Minimal"
        }
    }

    var emoji: String {
        switch self {
        case .chatty: return "🗣️"
        case .minimal: return "⚡"
        }
    }

    var description: String {
        switch self {
        case .chatty:
            return "Conversational, friendly, encouraging with emoji"
        case .minimal:
            return "Terse, action-focused, no unnecessary words"
        }
    }
}

// MARK: - Message Variant Protocol

protocol MessageVariant {
    var style: MessageStyle { get }

    // Success messages
    func thoughtSaved() -> String
    func reminderCreated() -> String
    func eventScheduled() -> String
    func settingsUpdated() -> String

    // Error messages
    func permissionDenied(framework: String) -> String
    func networkError() -> String
    func validationFailed(reason: String) -> String
    func storageError() -> String

    // Suggestions
    func classificationSuggestion(type: String) -> String
    func dateTimeParsed(date: String) -> String
    func tagSuggestion(tags: [String]) -> String

    // Empty states
    func noThoughtsYet() -> String
    func noSearchResults() -> String
    func noTags() -> String

    // Permission requests
    func requestCalendarAccess() -> String
    func requestHealthKitAccess() -> String
    func requestLocationAccess() -> String
}
