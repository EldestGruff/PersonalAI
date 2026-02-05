//
//  ChattyMessages.swift
//  PersonalAI
//
//  Chatty communication style: Conversational, friendly, emoji-rich
//

import Foundation

struct ChattyMessages: MessageVariant {
    let style = MessageStyle.chatty

    // MARK: - Success Messages

    func thoughtSaved() -> String {
        "Nice! Your thought is saved ✨"
    }

    func reminderCreated() -> String {
        "Got it! I'll remind you about that 🎯"
    }

    func eventScheduled() -> String {
        "All set! Your event is on the calendar 📅"
    }

    func settingsUpdated() -> String {
        "Perfect! Your preferences are saved 💾"
    }

    // MARK: - Error Messages

    func permissionDenied(framework: String) -> String {
        "Oops! I need permission to access \(framework). Mind enabling it in Settings? 🔒"
    }

    func networkError() -> String {
        "Hmm, looks like there's a network hiccup. Want to try again? 🌐"
    }

    func validationFailed(reason: String) -> String {
        "Hold on! \(reason). Can you fix that? 🤔"
    }

    func storageError() -> String {
        "Uh oh! I couldn't save that. Let's try again? 💾"
    }

    // MARK: - Suggestions

    func classificationSuggestion(type: String) -> String {
        "This looks like a \(type)! Want me to handle it? 🎯"
    }

    func dateTimeParsed(date: String) -> String {
        "I spotted a date: \(date)! Should I create a reminder? 📅"
    }

    func tagSuggestion(tags: [String]) -> String {
        let tagList = tags.joined(separator: ", ")
        return "How about these tags: \(tagList)? 🏷️"
    }

    // MARK: - Empty States

    func noThoughtsYet() -> String {
        "Your thought collection is empty! Let's capture your first idea ✨"
    }

    func noSearchResults() -> String {
        "Hmm, I couldn't find anything matching that. Try different words? 🔍"
    }

    func noTags() -> String {
        "No tags yet! They'll appear as you capture more thoughts 🏷️"
    }

    // MARK: - Permission Requests

    func requestCalendarAccess() -> String {
        "Hey! To create reminders and events, I'll need access to your Calendar. Want to enable it? 🎯"
    }

    func requestHealthKitAccess() -> String {
        "To help you understand your patterns, I'd love access to your health data. Sound good? ❤️"
    }

    func requestLocationAccess() -> String {
        "For location-based reminders, I'll need to know where you are. Is that okay? 📍"
    }
}
