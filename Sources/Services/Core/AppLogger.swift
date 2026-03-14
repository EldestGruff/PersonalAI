//
//  AppLogger.swift
//  STASH
//
//  Shared os.Logger instances for structured, privacy-aware logging.
//  Replaces print()/NSLog() throughout the codebase.
//
//  Usage:
//    AppLogger.services.info("Classification complete")
//    AppLogger.ai.error("Request failed: \(error, privacy: .public)")
//    AppLogger.data.debug("Saved thought \(thought.id, privacy: .public)")
//
//  View logs in Console.app by filtering on subsystem:
//    com.withershins.stash
//

import OSLog

/// Shared logger instances keyed by architectural layer.
///
/// Use the most specific category available. All logs are automatically
/// tagged with subsystem `com.withershins.stash` and appear in Console.app.
///
/// ## Privacy
/// User content (thought text, location strings) should use `.private`:
/// ```swift
/// AppLogger.services.debug("Content: \(thought.content, privacy: .private)")
/// ```
/// IDs, type names, counts, and error codes are `.public` (logged in release builds).
enum AppLogger {
    static let ui       = Logger(subsystem: "com.withershins.stash", category: "UI")
    static let services = Logger(subsystem: "com.withershins.stash", category: "Services")
    static let ai       = Logger(subsystem: "com.withershins.stash", category: "AI")
    static let sync     = Logger(subsystem: "com.withershins.stash", category: "Sync")
    static let health   = Logger(subsystem: "com.withershins.stash", category: "HealthKit")
    static let location = Logger(subsystem: "com.withershins.stash", category: "Location")
    static let calendar = Logger(subsystem: "com.withershins.stash", category: "Calendar")
    static let speech   = Logger(subsystem: "com.withershins.stash", category: "Speech")
    static let store    = Logger(subsystem: "com.withershins.stash", category: "StoreKit")
    static let data     = Logger(subsystem: "com.withershins.stash", category: "CoreData")
    static let watch    = Logger(subsystem: "com.withershins.stash", category: "Watch")
}
