//
//  DateFormatters.swift
//  STASH
//
//  Shared DateFormatter instances. DateFormatter is expensive to allocate;
//  these are created once as static constants and reused throughout the app.
//

import Foundation

enum DateFormatters {

    /// "Jan 5, 2026 at 3:00 PM" — used for timestamps on thoughts and conversation turns.
    static let mediumDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    /// "Jan 5, 2026" — used in date-only contexts such as date range summaries.
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
