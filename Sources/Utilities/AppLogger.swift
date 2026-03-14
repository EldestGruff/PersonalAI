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

    enum Category: String {
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

    private static func logger(for category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Log Methods

    /// Verbose detail useful during development. Not shown in release builds by default.
    static func debug(_ message: String, category: Category = .general) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    /// Informational messages for normal operation milestones.
    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    /// Non-fatal issues that degrade functionality but do not crash.
    static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    /// Errors that represent failures the user or developer needs to act on.
    static func error(_ message: String, category: Category = .general) {
        logger(for: category).error("\(message, privacy: .public)")
    }
}
