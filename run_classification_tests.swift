#!/usr/bin/env swift

//
//  run_classification_tests.swift
//  STASH
//
//  Quick runner for Foundation Models classification tests
//  Usage: swift run_classification_tests.swift
//

import Foundation

print("""
🧪 Foundation Models Classification Test Runner
================================================

This script tests edge cases from Issue #8.

To run the full test suite:
1. Open STASH.xcodeproj in Xcode
2. Navigate to Tests/FoundationModelsClassificationTests.swift
3. Add this to a test target or create a playground
4. Run: FoundationModelsClassificationTests.runTests()

Alternatively, you can test manually in the app by:
- Opening CaptureScreen
- Entering the test cases from Issue #8
- Observing the classification results

Test Cases:
===========
1. "grab milk tomorrow" (reminder)
2. "meeting with Sarah next Tuesday at 3" (event)
3. "I'll need to get the snowblower out sometime" (reminder, vague timing)
4. "password is abc123" (note, neutral)
5. "what's the best way to learn SwiftUI?" (question)
6. "tonight at 7" (event)
7. "this weekend" (event)
8. "in a few days" (reminder)
9. "Great, another meeting" (neutral - sarcasm)
10. "Feeling overwhelmed and stressed" (negative - genuine distress)

For a complete test report, integration with XCTest is recommended.
""")
