//
//  FoundationModelsClassificationTests.swift
//  STASH
//
//  Tests for Issue #8: Foundation Models edge cases and refinements
//

import Foundation
@testable import STASH

/// Manual test runner for Foundation Models classification edge cases
/// Run this to evaluate classification quality for Issue #8
@MainActor
class FoundationModelsClassificationTests {

    struct TestCase {
        let input: String
        let expectedType: ClassificationType?
        let expectedSentiment: Sentiment?
        let notes: String

        init(
            _ input: String,
            expectedType: ClassificationType? = nil,
            expectedSentiment: Sentiment? = nil,
            notes: String = ""
        ) {
            self.input = input
            self.expectedType = expectedType
            self.expectedSentiment = expectedSentiment
            self.notes = notes
        }
    }

    // MARK: - Test Cases from Issue #8

    static let edgeCases: [TestCase] = [
        // Date/Time Parsing Edge Cases
        TestCase(
            "grab milk tomorrow",
            expectedType: .reminder,
            notes: "Simple task with tomorrow - should parse date"
        ),
        TestCase(
            "meeting with Sarah next Tuesday at 3",
            expectedType: .event,
            notes: "Specific day and time - should parse both"
        ),
        TestCase(
            "I'll need to get the snowblower out sometime",
            expectedType: .reminder,
            notes: "Vague timing - 'sometime' is not a date"
        ),
        TestCase(
            "password is abc123",
            expectedType: .note,
            expectedSentiment: .neutral,
            notes: "Sensitive info - should be neutral note"
        ),
        TestCase(
            "what's the best way to learn SwiftUI?",
            expectedType: .question,
            expectedSentiment: .neutral,
            notes: "Clear question format"
        ),
        TestCase(
            "tonight at 7",
            expectedType: .event,
            notes: "Ambiguous - evening implied, should parse time"
        ),
        TestCase(
            "this weekend",
            expectedType: .event,
            notes: "Relative time reference"
        ),
        TestCase(
            "in a few days",
            expectedType: .reminder,
            notes: "Vague future reference"
        ),

        // Ambiguous Time
        TestCase(
            "meet at 9",
            expectedType: .event,
            notes: "Ambiguous AM/PM - needs context"
        ),
        TestCase(
            "call John at 9",
            expectedType: .reminder,
            notes: "Task with ambiguous time"
        ),

        // Sentiment Edge Cases
        TestCase(
            "Great, another meeting",
            expectedSentiment: .neutral,
            notes: "Sarcasm - should be neutral, not positive"
        ),
        TestCase(
            "Of course the build failed",
            expectedSentiment: .neutral,
            notes: "Dry humor - should be neutral"
        ),
        TestCase(
            "Feeling overwhelmed and stressed",
            expectedSentiment: .negative,
            notes: "Genuine distress - should be negative"
        ),
        TestCase(
            "So excited about the new feature!",
            expectedSentiment: .positive,
            notes: "Genuine joy - should be positive"
        ),
        TestCase(
            "Need to finish the report",
            expectedSentiment: .neutral,
            notes: "Task - should be neutral"
        ),

        // Classification Edge Cases
        TestCase(
            "idea: what if we use SwiftUI charts",
            expectedType: .idea,
            notes: "Explicit idea marker"
        ),
        TestCase(
            "how about we try a different approach",
            expectedType: .idea,
            notes: "Suggestion phrase"
        ),
        TestCase(
            "follow up with client on proposal",
            expectedType: .reminder,
            notes: "Follow-up action"
        ),
        TestCase(
            "brainstorm session for new features",
            expectedType: .idea,
            notes: "Brainstorm keyword"
        ),

        // Multi-classification Ambiguity
        TestCase(
            "remember to ask Sarah about the meeting tomorrow",
            expectedType: .reminder,
            notes: "Reminder about future event - primary intent is reminder"
        ),
        TestCase(
            "tomorrow's meeting about project timeline",
            expectedType: .event,
            notes: "Event with task context - primary intent is event"
        ),

        // Typos and Misspellings
        TestCase(
            "reminde me to cal john",
            expectedType: .reminder,
            notes: "Typos in reminder keywords"
        ),
        TestCase(
            "meting with sarah tommorow",
            expectedType: .event,
            notes: "Typos in event keywords"
        ),

        // Empty and Minimal
        TestCase(
            "ok",
            expectedType: .note,
            expectedSentiment: .neutral,
            notes: "Minimal content"
        ),
        TestCase(
            "yes",
            expectedType: .note,
            expectedSentiment: .neutral,
            notes: "Single word affirmation"
        ),

        // Complex Sentences
        TestCase(
            "I was thinking we could implement dark mode, but we'd need to refactor the theme system first, so maybe start with that?",
            expectedType: .idea,
            notes: "Long sentence with multiple clauses"
        ),
        TestCase(
            "Buy milk, eggs, and bread when you go to the store later today",
            expectedType: .reminder,
            notes: "List embedded in reminder"
        )
    ]

    // MARK: - Test Runner

    static func runTests() async {
        print("🧪 Running Foundation Models Classification Tests")
        print("=" + String(repeating: "=", count: 79))
        print("")

        let classifier = FoundationModelsClassifier()

        guard classifier.isAvailable else {
            print("❌ Apple Intelligence not available - cannot run tests")
            return
        }

        var results: [(TestCase, FoundationModelsResult?, Error?)] = []

        for (index, testCase) in edgeCases.enumerated() {
            print("Test \(index + 1)/\(edgeCases.count): \"\(testCase.input)\"")
            print("  Notes: \(testCase.notes)")

            do {
                let result = try await classifier.classify(testCase.input)
                results.append((testCase, result, nil))

                print("  ✅ Result:")
                print("     Type: \(result.type) (confidence: \(String(format: "%.2f", result.confidence)))")
                print("     Sentiment: \(result.sentiment)")
                print("     Tags: \(result.tags.joined(separator: ", "))")

                // Validate expectations
                if let expectedType = testCase.expectedType {
                    if result.type == expectedType {
                        print("     ✓ Type matches expected")
                    } else {
                        print("     ⚠️  Expected \(expectedType), got \(result.type)")
                    }
                }

                if let expectedSentiment = testCase.expectedSentiment {
                    if result.sentiment == expectedSentiment {
                        print("     ✓ Sentiment matches expected")
                    } else {
                        print("     ⚠️  Expected \(expectedSentiment), got \(result.sentiment)")
                    }
                }

            } catch {
                results.append((testCase, nil, error))
                print("  ❌ Error: \(error.localizedDescription)")
            }

            print("")
        }

        // Summary
        print("=" + String(repeating: "=", count: 79))
        print("📊 Test Summary")
        print("=" + String(repeating: "=", count: 79))

        let successful = results.filter { $0.1 != nil }.count
        let failed = results.filter { $0.2 != nil }.count

        print("Total Tests: \(results.count)")
        print("Successful: \(successful)")
        print("Failed: \(failed)")
        print("")

        // Type accuracy
        let typeMatches = results.filter { testCase, result, _ in
            guard let expected = testCase.expectedType, let result = result else { return false }
            return result.type == expected
        }.count

        let typeTests = results.filter { $0.0.expectedType != nil }.count
        if typeTests > 0 {
            let typeAccuracy = Double(typeMatches) / Double(typeTests) * 100
            print("Type Classification Accuracy: \(String(format: "%.1f%%", typeAccuracy)) (\(typeMatches)/\(typeTests))")
        }

        // Sentiment accuracy
        let sentimentMatches = results.filter { testCase, result, _ in
            guard let expected = testCase.expectedSentiment, let result = result else { return false }
            return result.sentiment == expected
        }.count

        let sentimentTests = results.filter { $0.0.expectedSentiment != nil }.count
        if sentimentTests > 0 {
            let sentimentAccuracy = Double(sentimentMatches) / Double(sentimentTests) * 100
            print("Sentiment Analysis Accuracy: \(String(format: "%.1f%%", sentimentAccuracy)) (\(sentimentMatches)/\(sentimentTests))")
        }

        print("")

        // Issues found
        print("🔍 Issues Found:")
        print("")

        var issuesFound = false

        for (testCase, result, error) in results {
            if let error = error {
                issuesFound = true
                print("❌ \"\(testCase.input)\"")
                print("   Error: \(error.localizedDescription)")
                print("")
                continue
            }

            guard let result = result else { continue }

            // Check type mismatch
            if let expected = testCase.expectedType, result.type != expected {
                issuesFound = true
                print("⚠️  \"\(testCase.input)\"")
                print("   Expected: \(expected), Got: \(result.type)")
                print("   Confidence: \(String(format: "%.2f", result.confidence))")
                print("   Note: \(testCase.notes)")
                print("")
            }

            // Check sentiment mismatch
            if let expected = testCase.expectedSentiment, result.sentiment != expected {
                issuesFound = true
                print("⚠️  \"\(testCase.input)\"")
                print("   Expected sentiment: \(expected), Got: \(result.sentiment)")
                print("   Note: \(testCase.notes)")
                print("")
            }

            // Check low confidence
            if result.confidence < 0.6 {
                issuesFound = true
                print("⚠️  \"\(testCase.input)\"")
                print("   Low confidence: \(String(format: "%.2f", result.confidence))")
                print("   Type: \(result.type)")
                print("")
            }
        }

        if !issuesFound {
            print("✅ No issues found - all tests passed expectations!")
        }

        print("=" + String(repeating: "=", count: 79))
    }
}
