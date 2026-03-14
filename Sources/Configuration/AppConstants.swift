//
//  AppConstants.swift
//  STASH
//
//  Application-wide constants. Single source of truth for
//  identifiers and limits used across multiple files.
//

import Foundation

enum AppConstants {

    // MARK: - App Group

    enum AppGroup {
        /// Shared UserDefaults suite used by app extensions (Siri intents, widgets).
        static let identifier = "group.com.withershins.stash"

        /// Pre-built accessor for the shared suite. Returns nil if the entitlement is missing.
        static var defaults: UserDefaults? {
            UserDefaults(suiteName: identifier)
        }
    }

    // MARK: - CloudKit

    enum CloudKit {
        /// Must match the identifier configured in Xcode Signing & Capabilities.
        static let containerIdentifier = "iCloud.com.withershins.stash"
    }

    // MARK: - Classification

    enum Classification {
        /// Maximum number of results held in the classification cache.
        static let maxCacheSize = 100

        /// Maximum number of recent thoughts included in a conversation context summary.
        static let recentThoughtsLimit = 50

        /// Maximum number of suggested follow-up questions shown to the user.
        static let maxSuggestionCount = 3

        /// Minimum confidence score required to include a parsed date/time result.
        static let parsedDateTimeMinConfidence: Double = 0.6

        /// Maximum number of suggested tags attached to a classification result.
        static let maxSuggestedTags = 5
    }

    // MARK: - Pending Actions

    enum PendingActions {
        /// UserDefaults key for the pending voice capture flag set by OpenVoiceCaptureIntent.
        static let pendingVoiceCaptureKey = "pendingVoiceCapture"
    }
}
