//
//  MinimalMessages.swift
//  STASH
//
//  Minimal communication style: Terse, action-focused, no emoji
//

import Foundation

struct MinimalMessages: MessageVariant {
    let style = MessageStyle.minimal

    // MARK: - Success Messages

    func thoughtSaved() -> String {
        "Saved"
    }

    func reminderCreated() -> String {
        "Reminder created"
    }

    func eventScheduled() -> String {
        "Event scheduled"
    }

    func settingsUpdated() -> String {
        "Settings updated"
    }

    // MARK: - Error Messages

    func permissionDenied(framework: String) -> String {
        "Enable \(framework) in Settings"
    }

    func networkError() -> String {
        "Network error. Retry?"
    }

    func validationFailed(reason: String) -> String {
        "Invalid: \(reason)"
    }

    func storageError() -> String {
        "Save failed. Retry?"
    }

    // MARK: - Suggestions

    func classificationSuggestion(type: String) -> String {
        "→ \(type)"
    }

    func dateTimeParsed(date: String) -> String {
        "Date found: \(date)"
    }

    func tagSuggestion(tags: [String]) -> String {
        "Tags: \(tags.joined(separator: ", "))"
    }

    // MARK: - Empty States

    func noThoughtsYet() -> String {
        "No thoughts yet"
    }

    func noSearchResults() -> String {
        "No results"
    }

    func noTags() -> String {
        "No tags"
    }

    // MARK: - Permission Requests

    func requestCalendarAccess() -> String {
        "Calendar access required"
    }

    func requestHealthKitAccess() -> String {
        "HealthKit access required"
    }

    func requestLocationAccess() -> String {
        "Location access required"
    }
}
