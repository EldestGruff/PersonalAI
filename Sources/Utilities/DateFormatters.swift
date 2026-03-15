//
//  DateFormatters.swift
//  STASH
//
//  Thread-safe date formatting using FormatStyle (iOS 15+, stateless).
//  FormatStyle is safe to call from any actor or thread concurrently.
//  These replaced shared DateFormatter instances which are not thread-safe.
//

import Foundation

enum DateFormatters {

    /// "Jan 5, 2026 at 3:00 PM" — used for timestamps on thoughts and conversation turns.
    static func mediumDateTime(from date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    /// "Jan 5, 2026" — used in date-only contexts such as date range summaries.
    static func mediumDate(from date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
