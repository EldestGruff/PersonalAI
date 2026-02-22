//
//  AnalyticsEvent.swift
//  STASH
//
//  All trackable analytics events in one place.
//  To adjust granularity: add, remove, or rename cases here.
//  Call sites use: AnalyticsService.shared.track(.caseName)
//

import Foundation

enum AnalyticsEvent {

    // MARK: - Screen Events

    case screenViewed(Screen)

    // MARK: - Capture Events

    case thoughtCaptured(method: CaptureMethod)
    case thoughtDeleted
    case thoughtArchived
    case classificationOverridden(from: String, to: String)

    // MARK: - Search Events

    case searchPerformed(resultCount: Int)
    case searchZeroResults

    // MARK: - Insights Events

    case aiInsightsGenerated

    // MARK: - Gamification Events

    case shinyPromoted(count: Int)
    case shinySurfaced
    case acornEarned(amount: Int)
    case acornSpent(amount: Int)
    case badgeUnlocked(badgeId: String)
    case achievementEarned(achievementId: String)

    // MARK: - Personalization Events

    case themeChanged(theme: String)
    case personaSelected(persona: String)

    // MARK: - Lifecycle Events

    case onboardingCompleted(stepsCompleted: Int)
    case onboardingAbandoned(atStep: Int)
    case siriShortcutUsed(intent: String)

    // MARK: - Error Events

    case classificationFailed
    case aiUnavailable
    case contextEnrichmentFailed(component: ContextComponent)

    // MARK: - Supporting Types

    enum Screen: String {
        case browse, search, insights, settings, achievements, detail, capture
    }

    enum CaptureMethod: String {
        case text, voice
    }

    enum ContextComponent: String {
        case location
        case healthKit = "healthkit"
        case calendar
    }

    // MARK: - Signal Name

    var signalName: String {
        switch self {
        case .screenViewed:              return "screenViewed"
        case .thoughtCaptured:           return "thoughtCaptured"
        case .thoughtDeleted:            return "thoughtDeleted"
        case .thoughtArchived:           return "thoughtArchived"
        case .classificationOverridden:  return "classificationOverridden"
        case .searchPerformed:           return "searchPerformed"
        case .searchZeroResults:         return "searchZeroResults"
        case .aiInsightsGenerated:       return "aiInsightsGenerated"
        case .shinyPromoted:             return "shinyPromoted"
        case .shinySurfaced:             return "shinySurfaced"
        case .acornEarned:               return "acornEarned"
        case .acornSpent:                return "acornSpent"
        case .badgeUnlocked:             return "badgeUnlocked"
        case .achievementEarned:         return "achievementEarned"
        case .themeChanged:              return "themeChanged"
        case .personaSelected:           return "personaSelected"
        case .onboardingCompleted:       return "onboardingCompleted"
        case .onboardingAbandoned:       return "onboardingAbandoned"
        case .siriShortcutUsed:          return "siriShortcutUsed"
        case .classificationFailed:      return "classificationFailed"
        case .aiUnavailable:             return "aiUnavailable"
        case .contextEnrichmentFailed:   return "contextEnrichmentFailed"
        }
    }

    // MARK: - Metadata (non-personal only)

    var metadata: [String: String] {
        switch self {
        case .screenViewed(let screen):
            return ["screen": screen.rawValue]
        case .thoughtCaptured(let method):
            return ["method": method.rawValue]
        case .classificationOverridden(let from, let to):
            return ["from": from, "to": to]
        case .searchPerformed(let resultCount):
            return ["resultCount": String(resultCount)]
        case .shinyPromoted(let count):
            return ["count": String(count)]
        case .acornEarned(let amount):
            return ["amount": String(amount)]
        case .acornSpent(let amount):
            return ["amount": String(amount)]
        case .badgeUnlocked(let badgeId):
            return ["badgeId": badgeId]
        case .achievementEarned(let achievementId):
            return ["achievementId": achievementId]
        case .themeChanged(let theme):
            return ["theme": theme]
        case .personaSelected(let persona):
            return ["persona": persona]
        case .onboardingCompleted(let stepsCompleted):
            return ["stepsCompleted": String(stepsCompleted)]
        case .onboardingAbandoned(let atStep):
            return ["atStep": String(atStep)]
        case .siriShortcutUsed(let intent):
            return ["intent": intent]
        case .contextEnrichmentFailed(let component):
            return ["component": component.rawValue]
        case .thoughtDeleted, .thoughtArchived, .searchZeroResults,
             .aiInsightsGenerated, .shinySurfaced, .classificationFailed,
             .aiUnavailable:
            return [:]
        }
    }
}
