//
//  DateTimeParsingService_FoundationModels.swift
//  PersonalAI
//
//  Phase 4: Intelligence & Automation
//  Natural language date and time parsing using Apple's Foundation Models (iOS 26)
//

import Foundation
import FoundationModels

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
        let formatter = ISO8601DateFormatter()
        let today = formatter.string(from: referenceDate)

        // Determine current time of day for better context
        let hour = Calendar.current.component(.hour, from: referenceDate)
        let timeContext = hour >= 12 ? "afternoon/evening" : "morning"

        return """
        Parse this text: "\(text)"

        Today's date is \(today).
        Current time context: \(timeContext) (use this to infer AM/PM for ambiguous times)

        Examples:
        - "today at three" → date: "\(today)", time: "15:00" (afternoon context)
        - "tomorrow at 2pm" → date: "\(Calendar.current.date(byAdding: .day, value: 1, to: referenceDate)!)", time: "14:00"
        - "Thursday at 4" → date: "next Thursday", time: "16:00" (afternoon default for single-digit hours)
        - "meeting at 9" → time: "09:00" if morning context, "21:00" if evening

        Extract:
        - date: The date in format YYYY-MM-DD. If text says "today", return "\(today)".
        - time: The time in 24-hour format HH:MM
          * For times 1-7 without AM/PM: assume PM (13:00-19:00) unless morning context suggests otherwise
          * For times 8-12 without AM/PM: assume based on context (8-11 could be AM or PM)
        - matchedText: The exact date/time phrase from the original text.
        - confidence: 1.0 if you found date/time, 0.0 if not.
        """
    }

    private func convertToInternal(extracted: ExtractedDateTime, referenceDate: Date) -> ParsedDateTimeInternal {
        // Parse ISO date if present
        var date: Date?
        if let dateString = extracted.date {
            let formatter = ISO8601DateFormatter()
            date = formatter.date(from: dateString)
        } else {
            date = nil
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

            NSLog("🔧 Smart fix: Foundation Models found time but no date, using today: \(date?.description ?? "nil")")
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
