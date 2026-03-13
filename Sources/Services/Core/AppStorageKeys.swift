//
//  AppStorageKeys.swift
//  STASH
//
//  Centralized UserDefaults key constants.
//  Eliminates scattered string literals and prevents key collisions.
//
//  Keys are grouped by owning layer.
//  Never use string literals directly — always reference constants here.
//

import Foundation

/// Centralized UserDefaults key constants, grouped by owning layer.
///
/// ## Usage
/// ```swift
/// // Read
/// UserDefaults.standard.bool(forKey: AppStorageKeys.Onboarding.completed)
///
/// // Write
/// UserDefaults.standard.set(true, forKey: AppStorageKeys.Onboarding.completed)
/// ```
enum AppStorageKeys {

    /// Onboarding flow state
    enum Onboarding {
        static let completed = "onboarding.completed"
    }

    /// Thought capture metadata
    enum Capture {
        /// Array of capture timestamps (Double / TimeInterval) used for frequency stats
        static let timestamps = "capture.timestamps"
        /// Stable device-local user ID (UUID string). Set once on first launch.
        static let stableUserId = "capture.stableUserId"
    }

    /// User-configurable settings
    enum Settings {
        static let autoCreateReminders  = "autoCreateReminders"
        static let selectedCalendarId   = "selectedCalendarId"
        static let selectedReminderListId = "selectedReminderListId"
    }

    /// Gamification: reminders and streak
    enum Gamification {
        static let reminderEnabled      = "reminder.enabled"
        /// Array of Int milestone rawValues already fired (shared with StreakTracker.Keys.milestonesAwarded)
        static let streakMilestonesAwarded = "streak.milestonesAwarded"
    }

    /// Analytics opt-out
    enum Analytics {
        static let optOut = "analytics.optOut"
    }

    /// Classification feedback/bias corrections
    enum Classification {
        static let biasCorrections = "classificationBiasCorrections"
    }

    /// HealthKit permission request tracking
    enum HealthKit {
        static let permissionRequested = "healthKitPermissionRequested"
    }

    /// iCloud KV sync migration guard
    enum Sync {
        static let migrationCompleted = "syncedDefaults.v1.migrated"
    }

    /// UI state stored in UserDefaults
    enum UI {
        /// Key prefix for per-thought action-prompt dismissal.
        /// Full key: "\(dismissedActionPromptPrefix)\(thoughtId)"
        static let dismissedActionPromptPrefix = "dismissedActionPrompt_"
        /// Currently selected theme identifier (stored in SyncedDefaults)
        static let selectedTheme = "selected_theme"
    }

    /// App intent / widget flags (stored in shared group suite)
    enum AppIntent {
        /// Set to `true` by CaptureThoughtIntent to signal a pending voice capture.
        /// Read in MainTabView and cleared after presentation.
        static let pendingVoiceCapture = "pendingVoiceCapture"
    }
}
