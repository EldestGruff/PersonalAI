//
//  PersonalityEngine.swift
//  PersonalAI
//
//  Central message variant selector based on user's communication style preference
//

import Foundation

class PersonalityEngine {
    static let shared = PersonalityEngine()

    private let styleKey = "communication_style"

    var currentStyle: MessageStyle {
        get {
            if let savedStyle = UserDefaults.standard.string(forKey: styleKey),
               let style = MessageStyle(rawValue: savedStyle) {
                return style
            }
            return .chatty // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: styleKey)
        }
    }

    private init() {}

    // MARK: - Message Retrieval

    private func getVariant() -> MessageVariant {
        switch currentStyle {
        case .chatty:
            return ChattyMessages()
        case .minimal:
            return MinimalMessages()
        }
    }

    // MARK: - Public API

    func setStyle(_ style: MessageStyle) {
        currentStyle = style
    }

    // Success messages
    func thoughtSaved() -> String {
        getVariant().thoughtSaved()
    }

    func reminderCreated() -> String {
        getVariant().reminderCreated()
    }

    func eventScheduled() -> String {
        getVariant().eventScheduled()
    }

    func settingsUpdated() -> String {
        getVariant().settingsUpdated()
    }

    // Error messages
    func permissionDenied(framework: String) -> String {
        getVariant().permissionDenied(framework: framework)
    }

    func networkError() -> String {
        getVariant().networkError()
    }

    func validationFailed(reason: String) -> String {
        getVariant().validationFailed(reason: reason)
    }

    func storageError() -> String {
        getVariant().storageError()
    }

    // Suggestions
    func classificationSuggestion(type: String) -> String {
        getVariant().classificationSuggestion(type: type)
    }

    func dateTimeParsed(date: String) -> String {
        getVariant().dateTimeParsed(date: date)
    }

    func tagSuggestion(tags: [String]) -> String {
        getVariant().tagSuggestion(tags: tags)
    }

    // Empty states
    func noThoughtsYet() -> String {
        getVariant().noThoughtsYet()
    }

    func noSearchResults() -> String {
        getVariant().noSearchResults()
    }

    func noTags() -> String {
        getVariant().noTags()
    }

    // Permission requests
    func requestCalendarAccess() -> String {
        getVariant().requestCalendarAccess()
    }

    func requestHealthKitAccess() -> String {
        getVariant().requestHealthKitAccess()
    }

    func requestLocationAccess() -> String {
        getVariant().requestLocationAccess()
    }
}
