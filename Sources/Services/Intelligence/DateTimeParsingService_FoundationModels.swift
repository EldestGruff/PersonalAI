//
//  DateTimeParsingService_FoundationModels.swift
//  STASH
//
//  Phase 4: Intelligence & Automation
//  Natural language date and time parsing using Apple's Foundation Models (iOS 26)
//

import Foundation
import FoundationModels
import OSLog

// MARK: - Structured Output Model

/// Structured output from Foundation Models for date/time extraction.
///
/// The @Generable macro tells Apple's on-device LLM to return structured data
/// instead of raw text, eliminating the need for regex parsing.
@Generable
struct ExtractedDateTime: Codable, Equatable {
    /// The extracted date in ISO 8601 format (e.g., "2026-01-26")
    /// Nil if no date was mentioned
    @Guide(description: "Extract the date in ISO 8601 format (YYYY-MM-DD). Convert 'today' to today's date, 'tomorrow' to tomorrow's date, 'next Friday' to that Friday's date. REQUIRED if any time is mentioned.")
    let date: String?

    /// The extracted time in 24-hour format (e.g., "15:00", "09:30")
    /// Nil if no specific time was mentioned
    @Guide(description: "Extract the time mentioned. Convert to 24-hour format (HH:MM). '3pm' becomes '15:00', 'three' becomes '15:00' if afternoon context.")
    let time: String?

    /// Whether this is an all-day event (no specific time)
    @Guide(description: "True if no specific time is mentioned, false if a time is given")
    let isAllDay: Bool

    /// The exact text that contained the date/time information
    /// Used for removing from the original content to create a clean title
    @Guide(description: "The exact phrase from the original text that mentioned date/time (e.g., 'tomorrow at three', 'next Friday at 2pm')")
    let matchedText: String?

    /// Confidence score from 0.0 to 1.0
    @Guide(description: "How confident are you in this extraction? 1.0 = very confident, 0.5 = uncertain, 0.0 = no date/time found")
    let confidence: Double
}

// MARK: - Foundation Models Date/Time Parser

/// Modern date/time parser using Apple's Foundation Models (iOS 26).
///
/// Replaces regex-based parsing with on-device AI that understands natural language.
/// Supports phrases like:
/// - "tomorrow at three"
/// - "next Friday at eleven thirty"
/// - "January 15th at 3pm"
/// - "in two hours"
///
/// ## Advantages over Regex
/// - No hardcoded keywords - handles any natural language
/// - Understands context ("three" in afternoon = 3pm)
/// - Handles misspellings and variations
/// - Apple's AI improves over time via OS updates
actor FoundationModelsDateTimeParser {
    private var session: LanguageModelSession?
    private var isProcessing = false

    init() {
        // Session will be created lazily on first use
    }

    /// Parse date and time from natural language using Foundation Models.
    func parseDateTime(_ text: String, referenceDate: Date = Date()) async throws -> ParsedDateTimeInternal {
        // CRITICAL: Prevent concurrent requests - Foundation Models can only handle one at a time
        guard !isProcessing else {
            throw ServiceError.frameworkUnavailable(
                framework: .foundationModels,
                reason: "Foundation Models is already processing a request"
            )
        }

        isProcessing = true
        defer { isProcessing = false }

        // Recreate session on each call to avoid context accumulation
        // Foundation Models has a 4096 token limit and accumulated context can overflow
        session = createSession()

        guard let session = session else {
            throw ServiceError.frameworkUnavailable(
                framework: .foundationModels,
                reason: "Could not create LanguageModelSession"
            )
        }

        // Create prompt for the AI
        let prompt = createPrompt(text: text, referenceDate: referenceDate)

        do {
            // Get structured output from Foundation Models
            let response = try await session.respond(
                to: prompt,
                generating: ExtractedDateTime.self
            )

            // Convert to internal format
            return convertToInternal(extracted: response.content, referenceDate: referenceDate)
        } catch {
            // Reset session on error to clear accumulated context
            self.session = nil
            throw error
        }
    }

    private func createSession() -> LanguageModelSession {
        LanguageModelSession {
            """
            You are a date and time extraction assistant. Your job is to:
            1. ALWAYS extract BOTH date AND time when any temporal reference is mentioned
            2. Convert relative dates to absolute ISO 8601 dates:
               - "today" → today's date in ISO 8601
               - "tomorrow" → tomorrow's date in ISO 8601
               - "next Friday" → the date of next Friday in ISO 8601
            3. Convert times to 24-hour format (HH:MM):
               - "three" in afternoon context → "15:00"
               - "eleven thirty" → "11:30" or "23:30" based on context
            4. Use context clues for AM/PM (afternoon hours default to PM)
            5. Extract the exact phrase that mentioned the date/time
            6. Be confident: if you can extract date/time, set confidence to 1.0

            Today's date is: \(ISO8601DateFormatter().string(from: Date()))

            CRITICAL: If text mentions "today" or "tonight", you MUST provide the date field with today's date!
            """
        }
    }

    private func createPrompt(text: String, referenceDate: Date) -> String {
        let cal = Calendar.current
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter.isoDate

        let today = dateFormatter.string(from: referenceDate)
        let tomorrow = dateFormatter.string(from: cal.date(byAdding: .day, value: 1, to: referenceDate)!)

        // Pre-compute the next occurrence of each weekday so the model
        // has concrete examples — never show relative strings like "next Thursday"
        func nextWeekday(_ weekday: Int) -> String {
            var components = DateComponents()
            components.weekday = weekday
            let next = cal.nextDate(after: referenceDate, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) ?? referenceDate
            return dateFormatter.string(from: next)
        }
        let nextThursday = nextWeekday(5)
        let nextWednesday = nextWeekday(4)

        let hour = cal.component(.hour, from: referenceDate)
        let timeContext = hour >= 12 ? "afternoon/evening" : "morning"

        return """
        Parse this text: "\(text)"

        IMPORTANT: Today is \(today). All dates MUST be returned as YYYY-MM-DD (e.g. "\(today)"). \
        Never return relative strings like "next Wednesday" — compute the actual date.

        Current time context: \(timeContext) — use this to resolve AM/PM for ambiguous times.

        Examples:
        - "today at three" → date: "\(today)", time: "15:00"
        - "tomorrow at 2pm" → date: "\(tomorrow)", time: "14:00"
        - "Thursday at 4" → date: "\(nextThursday)", time: "16:00"
        - "Wednesday at 6:30 PM" → date: "\(nextWednesday)", time: "18:30"
        - "meeting at 9" → date: "\(today)", time: "09:00" if morning context, "21:00" if evening

        Rules:
        - date MUST be YYYY-MM-DD. Compute it from today (\(today)).
        - time in 24-hour HH:MM. Times 1–7 without AM/PM → assume PM.
        - matchedText: the exact phrase from the original text that contains the date/time.
        - confidence: 1.0 if found, 0.0 if not.
        """
    }

    private func convertToInternal(extracted: ExtractedDateTime, referenceDate: Date) -> ParsedDateTimeInternal {
        // Parse ISO date if present — model should return YYYY-MM-DD.
        // Always parse in local timezone: extracting just the YYYY-MM-DD portion
        // prevents ISO8601DateFormatter from treating midnight UTC as the previous
        // day in negative-offset timezones (e.g. "2026-03-11T00:00:00Z" → Mar 10 ET).
        var date: Date?
        if let dateString = extracted.date {
            let localDateFormatter = DateFormatter.isoDate
            // localDateFormatter uses the device timezone by default — no explicit set needed

            // Extract the YYYY-MM-DD prefix if the model returned a full ISO datetime
            let datePart: String
            if dateString.count >= 10,
               dateString.prefix(4).allSatisfy({ $0.isNumber }),
               dateString.dropFirst(4).first == "-" {
                datePart = String(dateString.prefix(10))
            } else {
                datePart = dateString
            }

            if let parsed = localDateFormatter.date(from: datePart) {
                date = parsed
                AppLogger.ai.debug("FM date parsed: '\(dateString)' → '\(datePart)' → \(parsed)")
            } else if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
                      let match = detector.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
                      let fallback = match.date {
                // Model returned a relative string like "next Wednesday" — NSDataDetector resolves it
                AppLogger.ai.warning("FM returned non-ISO date '\(dateString)', NSDataDetector resolved to \(fallback)")
                date = fallback
            }
        }

        // Parse time if present (HH:MM format)
        let timeOfDay: Int?
        if let timeString = extracted.time {
            let components = timeString.split(separator: ":")
            if components.count == 2,
               let hour = Int(components[0]),
               let minute = Int(components[1]) {
                timeOfDay = hour * 3600 + minute * 60
            } else {
                timeOfDay = nil
            }
        } else {
            timeOfDay = nil
        }

        // SMART FIX: If we have a time but no date, assume "today"
        // This handles cases where Foundation Models successfully extracts "at three" → "15:00"
        // but fails to extract "today" as a date
        if timeOfDay != nil && date == nil {
            // Use the reference date (typically "today")
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            components.hour = 0
            components.minute = 0
            components.second = 0
            date = calendar.date(from: components)

            AppLogger.ai.debug("Smart fix: Foundation Models found time but no date, using today: \(date?.description ?? "nil")")
        }

        return ParsedDateTimeInternal(
            date: date,
            timeOfDay: timeOfDay,
            isAllDay: extracted.isAllDay,
            matchedText: extracted.matchedText,
            range: nil, // Foundation Models doesn't provide ranges
            confidence: extracted.confidence,
            strategy: .foundationModels
        )
    }
}

// Note: ParsingStrategy.foundationModels is defined in DateTimeParsingService.swift
