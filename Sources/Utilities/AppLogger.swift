//
//  AppLogger.swift
//  STASH
//
//  Unified structured logging backed by os_log.
//  Use instead of print() or NSLog() throughout the codebase.
//  Log output is visible in Console.app, Xcode console, and Instruments.
//

import os.log

enum AppLogger {

    // MARK: - Categories

    enum Category: String, CaseIterable {
        case classification = "Classification"
        case conversation   = "Conversation"
        case context        = "Context"
        case location       = "Location"
        case sync           = "Sync"
        case persistence    = "Persistence"
        case analytics      = "Analytics"
        case gamification   = "Gamification"
        case general        = "General"
    }

    // MARK: - Private

    private static let subsystem = "com.withershins.stash"

    /// One Logger per category, created once at startup. Logger is a struct but
    /// building it allocates the subsystem/category strings — cache to avoid per-call overhead.
    private static let loggers: [Category: Logger] = Dictionary(
        uniqueKeysWithValues: Category.allCases.map { cat in
            (cat, Logger(subsystem: subsystem, category: cat.rawValue))
        }
    )

    private static func logger(for category: Category) -> Logger {
        loggers[category] ?? Logger(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Log Methods (private — user data redacted in production logs)

    /// Verbose detail useful during development. Not shown in release builds by default.
    /// User data is redacted in production — safe to pass thought content, tags, etc.
    static func debug(_ message: String, category: Category = .general) {
        logger(for: category).debug("\(message, privacy: .private)")
    }

    /// Informational messages for normal operation milestones.
    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .private)")
    }

    /// Non-fatal issues that degrade functionality but do not crash.
    static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("\(message, privacy: .private)")
    }

    /// Errors that represent failures the user or developer needs to act on.
    static func error(_ message: String, category: Category = .general) {
        logger(for: category).error("\(message, privacy: .private)")
    }

    // MARK: - Public Variants (non-sensitive data only)

    /// Use ONLY for non-sensitive values: counts, enum names, type identifiers.
    /// Never use for user content, thought text, tags, or calendar data.
    static func debugPublic(_ message: String, category: Category = .general) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    static func infoPublic(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public)")
    }
}
