//
//  DateFormatter+Shared.swift
//  STASH
//
//  Shared static DateFormatter instances.
//  DateFormatter is expensive to allocate (allocates locale and timezone state).
//  Caching shared instances avoids repeated allocation in render/update hot paths.
//
//  Usage:
//    DateFormatter.mediumDate.string(from: date)   // "Mar 13, 2026"
//    DateFormatter.mediumDateTime.string(from: date) // "Mar 13, 2026 at 2:30 PM"
//

import Foundation

extension DateFormatter {
    /// Medium date, no time — e.g. "Mar 13, 2026"
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// Medium date + short time — e.g. "Mar 13, 2026 at 2:30 PM"
    static let mediumDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    /// Month + day only — e.g. "3/13"
    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f
    }()

    /// Hour + AM/PM — e.g. "2 PM"
    static let hourAmPm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()

    /// ISO date string — e.g. "2026-03-13"
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
