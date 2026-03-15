//
//  EventHelpers.swift
//  STASH
//
//  Shared utilities for extracting event title and times from thought classification.
//  Used by CaptureViewModel and DetailViewModel.
//

import Foundation

enum EventHelpers {
    /// Extracts a clean event title from raw thought content by removing date/time references.
    ///
    /// Uses the matchedText from parsed date/time to remove the temporal reference.
    /// Falls back to using the full content if no match is found.
    static func extractCleanTitle(from content: String, parsedDateTime: ParsedDateTime?) -> String {
        guard let parsedDateTime = parsedDateTime,
              let matchedText = parsedDateTime.matchedText,
              !matchedText.isEmpty else {
            return content
        }

        // Remove the matched date/time text
        var cleanedContent = content

        // Try case-insensitive replacement
        if let range = cleanedContent.range(of: matchedText, options: [.caseInsensitive]) {
            cleanedContent.removeSubrange(range)
        }

        // Clean up extra whitespace and punctuation
        cleanedContent = cleanedContent
            .replacingOccurrences(of: "  ", with: " ")  // Double spaces
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove leading/trailing punctuation that might be left over
        let punctuationSet = CharacterSet(charactersIn: ",-:;")
        cleanedContent = cleanedContent.trimmingCharacters(in: punctuationSet)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // If we removed too much and the title is now too short, use original
        if cleanedContent.count < 3 {
            return content
        }

        // Capitalize first letter if needed
        if let firstChar = cleanedContent.first, firstChar.isLowercase {
            cleanedContent = cleanedContent.prefix(1).uppercased() + cleanedContent.dropFirst()
        }

        return cleanedContent
    }

    /// Calculates start and end dates for a calendar event from parsed date/time data.
    ///
    /// Returns a tuple of (startDate, endDate) for calendar events.
    /// Falls back to sensible defaults if no date/time was parsed.
    static func calculateEventTimes(from parsedDateTime: ParsedDateTime?) -> (Date, Date) {
        guard let parsedDateTime = parsedDateTime,
              let baseDate = parsedDateTime.date else {
            // Fallback: 1 hour from now, duration 1 hour
            let now = Date()
            return (now.addingTimeInterval(3600), now.addingTimeInterval(7200))
        }

        let calendar = Calendar.current

        // If we have a specific time of day, use it
        if let timeOfDay = parsedDateTime.timeOfDay {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            let hours = timeOfDay / 3600
            let minutes = (timeOfDay % 3600) / 60

            var components = dateComponents
            components.hour = hours
            components.minute = minutes
            components.second = 0

            if let startDate = calendar.date(from: components) {
                // Default event duration: 1 hour
                let endDate = startDate.addingTimeInterval(3600)
                return (startDate, endDate)
            }
        }

        // All-day event: use 9am to 10am on that date
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = 9
        components.minute = 0
        components.second = 0

        if let startDate = calendar.date(from: components) {
            let endDate = startDate.addingTimeInterval(3600)
            return (startDate, endDate)
        }

        // Final fallback
        return (baseDate, baseDate.addingTimeInterval(3600))
    }
}
