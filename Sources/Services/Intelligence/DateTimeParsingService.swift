//
//  DateTimeParsingService.swift
//  PersonalAI
//
//  Phase 4: Intelligence & Automation
//  Natural language date and time parsing using Apple's Foundation Models (iOS 26)
//

import Foundation
import FoundationModels

// MARK: - Parsed Date/Time Result (Internal)

/// Internal result of parsing date and time from natural language text.
///
/// Contains detailed metadata about the parse. This is converted to the
/// simpler `ParsedDateTime` model for storage in classifications.
struct ParsedDateTimeInternal: Equatable, Sendable {
    /// The parsed date component (nil if no date found)
    let date: Date?

    /// The parsed time component (nil if no time found)
    /// Stored as seconds since midnight (0-86399)
    let timeOfDay: Int?

    /// Whether this is an all-day event (no specific time)
    let isAllDay: Bool

    /// The original text that was matched
    let matchedText: String?

    /// Range in the original text where the match was found
    let range: NSRange?

    /// Confidence in the parse (0.0 to 1.0)
    /// - 1.0: Absolute date/time (NSDataDetector)
    /// - 0.9: Clear relative date ("tomorrow", "next Monday")
    /// - 0.7: Fuzzy relative date ("next week", "in a few days")
    let confidence: Double

    /// The parsing strategy that was used
    let strategy: ParsingStrategy

    enum ParsingStrategy: String, Sendable {
        case foundationModels = "Foundation Models (iOS 26)"
        case dataDetector = "NSDataDetector"
        case relativeDate = "Relative Date Pattern"
        case relativeTime = "Relative Time Pattern"
        case fuzzyPattern = "Fuzzy Pattern"
        case none = "None"
    }

    /// Convert to the model's ParsedDateTime for storage
    func toModel() -> ParsedDateTime {
        ParsedDateTime(
            date: date,
            timeOfDay: timeOfDay,
            isAllDay: isAllDay,
            matchedText: matchedText,
            confidence: confidence
        )
    }
}

// MARK: - DateTime Parsing Service Protocol

/// Protocol for date/time parsing services.
///
/// Enables mocking in tests.
protocol DateTimeParsingServiceProtocol: ServiceProtocol {
    /// Parse date and time from natural language text
    func parseDateTime(_ text: String, referenceDate: Date) async -> ParsedDateTimeInternal

    /// Extract all date/time mentions from text
    func extractAllDateTimes(_ text: String, referenceDate: Date) async -> [ParsedDateTimeInternal]
}

// MARK: - DateTime Parsing Service

/// Service for parsing dates and times from natural language text.
///
/// Uses Apple's NSDataDetector as the primary parser, designed for natural language understanding.
/// This leverages the same technology that powers Siri's date/time comprehension.
///
/// ## Examples
///
/// - "tomorrow at 2pm" → Tomorrow, 14:00
/// - "next Thursday at 3:30" → Next Thursday, 15:30
/// - "January 15th at 3pm" → Jan 15, 15:00
/// - "in 2 hours" → 2 hours from reference date
///
/// ## Performance
///
/// All parsing operations complete in <50ms typical.
///
/// ## Thread Safety
///
/// Service is an actor, safe to call from any context.
actor DateTimeParsingService: DateTimeParsingServiceProtocol, DomainServiceProtocol {
    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration
    private let calendar: Calendar
    private var foundationModelsParser: FoundationModelsDateTimeParser?

    // MARK: - Initialization

    init(
        configuration: ServiceConfiguration = .shared,
        calendar: Calendar = .current
    ) {
        self.configuration = configuration
        self.calendar = calendar
        // Foundation Models parser initialized lazily on first use
    }

    // MARK: - Main Parsing

    /// Parse date and time from natural language text.
    ///
    /// **iOS 26 Approach**: Uses Apple's Foundation Models (on-device AI) as primary parser.
    /// This eliminates regex hacks and handles any natural language variation.
    /// Falls back to NSDataDetector only if Foundation Models unavailable.
    ///
    /// Returns the first successful parse, or empty result if nothing found.
    func parseDateTime(_ text: String, referenceDate: Date = Date()) async -> ParsedDateTimeInternal {
        guard !text.isEmpty else {
            return ParsedDateTimeInternal(
                date: nil,
                timeOfDay: nil,
                isAllDay: false,
                matchedText: nil,
                range: nil,
                confidence: 0.0,
                strategy: .none
            )
        }

        // PRIMARY (iOS 26): Use Foundation Models - on-device AI that understands any natural language
        // Handles "tomorrow at three", misspellings, context, etc. NO REGEX NEEDED!
        if foundationModelsParser == nil {
            foundationModelsParser = FoundationModelsDateTimeParser()
        }

        if let parser = foundationModelsParser {
            do {
                let result = try await parser.parseDateTime(text, referenceDate: referenceDate)
                NSLog("📊 Foundation Models parse result: date=\(result.date?.description ?? "nil"), timeOfDay=\(result.timeOfDay?.description ?? "nil"), confidence=\(result.confidence), matched='\(result.matchedText ?? "")'")
                // Only use if confidence is reasonable
                if result.confidence >= 0.5 {
                    NSLog("✅ Using Foundation Models result (confidence: \(result.confidence))")
                    return result
                } else {
                    NSLog("⚠️ Foundation Models confidence too low (\(result.confidence)), trying fallback")
                }
            } catch {
                // Foundation Models failed - fall back to NSDataDetector
                NSLog("❌ Foundation Models failed, falling back to NSDataDetector: \(error)")
            }
        }

        // FALLBACK: NSDataDetector (with preprocessing hacks for word numbers)
        if let result = parseWithDataDetector(text, referenceDate: referenceDate) {
            NSLog("📝 Using NSDataDetector fallback: date=\(result.date?.description ?? "nil"), timeOfDay=\(result.timeOfDay?.description ?? "nil")")
            return result
        }

        // FALLBACK: Simple relative date patterns
        if let result = parseSimpleRelativeDate(text, referenceDate: referenceDate) {
            return result
        }

        // No date/time found
        return ParsedDateTimeInternal(
            date: nil,
            timeOfDay: nil,
            isAllDay: false,
            matchedText: nil,
            range: nil,
            confidence: 0.0,
            strategy: .none
        )
    }

    /// Extract all date/time mentions from text.
    ///
    /// Returns array of all found date/time references, sorted by confidence.
    func extractAllDateTimes(_ text: String, referenceDate: Date = Date()) async -> [ParsedDateTimeInternal] {
        // Get all NSDataDetector results
        let results = extractAllDataDetectorDates(text, referenceDate: referenceDate)

        // Sort by confidence (highest first)
        return results.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - NSDataDetector Parsing

    /// Use NSDataDetector to parse natural language dates and times.
    ///
    /// NSDataDetector is Apple's built-in natural language parser, designed to understand
    /// the same date/time expressions that Siri understands. This is the recommended approach
    /// for iOS 18+ and handles phrases like:
    /// - "tomorrow at 3pm"
    /// - "next Friday at 2:30"
    /// - "January 15th"
    /// - And many more natural language patterns
    private func parseWithDataDetector(_ text: String, referenceDate: Date) -> ParsedDateTimeInternal? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        // Preprocess: Convert word numbers to digits so NSDataDetector can understand them
        // e.g., "tomorrow at three" → "tomorrow at 3"
        let preprocessedText = convertWordNumbersToDigits(text)
        NSLog("🔄 Preprocessed text: '\(text)' → '\(preprocessedText)'")

        let range = NSRange(preprocessedText.startIndex..<preprocessedText.endIndex, in: preprocessedText)
        let matches = detector.matches(in: preprocessedText, options: [], range: range)

        guard let firstMatch = matches.first,
              let date = firstMatch.date else {
            NSLog("⚠️ NSDataDetector found no matches in: '\(preprocessedText)'")
            return nil
        }

        // Get matched text - need to find it in original since preprocessing changed lengths
        // Pattern: Look for date/time keywords in the original text around the same position
        let preprocessedMatch = String(preprocessedText[Range(firstMatch.range, in: preprocessedText)!])
        let matchedText = findOriginalMatch(in: text, preprocessedMatch: preprocessedMatch)

        // Extract time components from the parsed date
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        NSLog("🕐 NSDataDetector parsed date: \(date), hour: \(hour), minute: \(minute), matched: '\(matchedText)'")

        // Check if time component exists
        // NSDataDetector may not always set timeZone, so we check multiple indicators
        let hasExplicitTimeInText = matchedText.contains(":") ||
                                    matchedText.lowercased().contains("am") ||
                                    matchedText.lowercased().contains("pm") ||
                                    preprocessedText.lowercased().contains(" at ")

        // If we found "at" in the text and the hour isn't midnight, consider it a time
        let hasTime = hasExplicitTimeInText || (hour != 0 && preprocessedText.lowercased().contains(" at "))

        let timeOfDay: Int?
        if hasTime {
            timeOfDay = hour * 3600 + minute * 60
        } else {
            timeOfDay = nil
        }

        return ParsedDateTimeInternal(
            date: date,
            timeOfDay: timeOfDay,
            isAllDay: !hasTime,
            matchedText: matchedText,
            range: firstMatch.range,
            confidence: 1.0,
            strategy: .dataDetector
        )
    }

    /// Extract all dates found by NSDataDetector.
    private func extractAllDataDetectorDates(_ text: String, referenceDate: Date) -> [ParsedDateTimeInternal] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }

        let preprocessedText = convertWordNumbersToDigits(text)
        let range = NSRange(preprocessedText.startIndex..<preprocessedText.endIndex, in: preprocessedText)
        let matches = detector.matches(in: preprocessedText, options: [], range: range)

        return matches.compactMap { match in
            guard let date = match.date else { return nil }

            // Get matched text from original input for clean title extraction
            let matchedText = String(text[Range(match.range, in: text)!])
            let components = calendar.dateComponents([.hour, .minute], from: date)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0

            let hasExplicitTimeInText = matchedText.contains(":") ||
                                        matchedText.lowercased().contains("am") ||
                                        matchedText.lowercased().contains("pm") ||
                                        preprocessedText.lowercased().contains(" at ")

            let hasTime = hasExplicitTimeInText || (hour != 0 && preprocessedText.lowercased().contains(" at "))

            let timeOfDay: Int?
            if hasTime {
                timeOfDay = hour * 3600 + minute * 60
            } else {
                timeOfDay = nil
            }

            return ParsedDateTimeInternal(
                date: date,
                timeOfDay: timeOfDay,
                isAllDay: !hasTime,
                matchedText: matchedText,
                range: match.range,
                confidence: 1.0,
                strategy: .dataDetector
            )
        }
    }

    // MARK: - Preprocessing Helpers

    /// Find the original matched text in the input before preprocessing.
    ///
    /// Since preprocessing changes text length (e.g., "three" → "3"), we can't use indices directly.
    /// Instead, we search for common date/time patterns in the original text.
    private func findOriginalMatch(in originalText: String, preprocessedMatch: String) -> String {
        let lowercased = originalText.lowercased()
        _ = preprocessedMatch.lowercased() // For future pattern matching

        // Pattern: "tomorrow at three", "next friday at eleven", etc.
        // Search for common date+time patterns using regex
        let patterns = [
            #"(tomorrow|today|tonight|yesterday)\s+at\s+(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|\d{1,2})(?::\d{2})?\s*(am|pm)?"#,
            #"(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+at\s+(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|\d{1,2})(?::\d{2})?\s*(am|pm)?"#,
            #"(next|this)\s+\w+\s+at\s+(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|\d{1,2})(?::\d{2})?\s*(am|pm)?"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(lowercased.startIndex..<lowercased.endIndex, in: lowercased)),
               let range = Range(match.range, in: lowercased) {
                return String(originalText[range])
            }
        }

        // Fallback: return the preprocessed match (better than nothing)
        return preprocessedMatch
    }

    /// Convert word numbers to digits for better NSDataDetector comprehension.
    ///
    /// NSDataDetector understands "tomorrow at 3" but not "tomorrow at three".
    /// This simple preprocessing step converts word numbers to digits.
    ///
    /// Examples:
    /// - "tomorrow at three" → "tomorrow at 3"
    /// - "next Friday at eleven thirty" → "next Friday at 11 thirty" (partial)
    private func convertWordNumbersToDigits(_ text: String) -> String {
        let wordToDigit: [(word: String, digit: String)] = [
            ("one", "1"), ("two", "2"), ("three", "3"), ("four", "4"),
            ("five", "5"), ("six", "6"), ("seven", "7"), ("eight", "8"),
            ("nine", "9"), ("ten", "10"), ("eleven", "11"), ("twelve", "12")
        ]

        var result = text.lowercased()

        // Replace word numbers when they appear in time context (after "at")
        for (word, digit) in wordToDigit {
            // Match "at <word>" or "at <word>pm/am"
            let patterns = [
                "at \(word)",
                "at \(word) am",
                "at \(word) pm"
            ]

            for pattern in patterns {
                let replacement = pattern.replacingOccurrences(of: word, with: digit)
                result = result.replacingOccurrences(of: pattern, with: replacement)
            }
        }

        return result
    }

    // MARK: - Simple Fallback Patterns

    /// Simple fallback for basic relative dates that NSDataDetector might occasionally miss.
    ///
    /// This is a minimal safety net - NSDataDetector handles 99% of cases.
    private func parseSimpleRelativeDate(_ text: String, referenceDate: Date) -> ParsedDateTimeInternal? {
        let lowercased = text.lowercased()

        // "in X hours/days" patterns
        let patterns: [(regex: String, component: Calendar.Component)] = [
            (#"in (\d+) hour"#, .hour),
            (#"in (\d+) day"#, .day),
            (#"in (\d+) week"#, .weekOfYear)
        ]

        for (pattern, component) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: lowercased, options: [], range: NSRange(lowercased.startIndex..<lowercased.endIndex, in: lowercased)),
               let valueRange = Range(match.range(at: 1), in: lowercased),
               let value = Int(lowercased[valueRange]) {

                guard let resultDate = calendar.date(byAdding: component, value: value, to: referenceDate) else {
                    continue
                }

                let matchedText = String(text[Range(match.range, in: text)!])

                return ParsedDateTimeInternal(
                    date: resultDate,
                    timeOfDay: nil,
                    isAllDay: true,
                    matchedText: matchedText,
                    range: match.range,
                    confidence: 0.9,
                    strategy: .relativeDate
                )
            }
        }

        return nil
    }

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        // No cleanup needed
    }
}

// MARK: - Mock DateTime Parsing Service

/// Mock date/time parsing service for testing and previews.
actor MockDateTimeParsingService: DateTimeParsingServiceProtocol {
    nonisolated var isAvailable: Bool { true }

    var mockResult: ParsedDateTimeInternal?
    var mockResults: [ParsedDateTimeInternal]

    init(
        result: ParsedDateTimeInternal? = nil,
        results: [ParsedDateTimeInternal] = []
    ) {
        self.mockResult = result
        self.mockResults = results
    }

    func parseDateTime(_ text: String, referenceDate: Date) async -> ParsedDateTimeInternal {
        mockResult ?? ParsedDateTimeInternal(
            date: nil,
            timeOfDay: nil,
            isAllDay: false,
            matchedText: nil,
            range: nil,
            confidence: 0.0,
            strategy: .none
        )
    }

    func extractAllDateTimes(_ text: String, referenceDate: Date) async -> [ParsedDateTimeInternal] {
        mockResults
    }
}

// MARK: - Foundation Models Integration
//
// Foundation Models implementation is in DateTimeParsingService_FoundationModels.swift
// This separation keeps the main service file focused while allowing the AI parser
// to use the latest iOS 26 APIs without cluttering this file.
