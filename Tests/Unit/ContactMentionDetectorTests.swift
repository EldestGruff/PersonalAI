//
//  ContactMentionDetectorTests.swift
//  STASHTests
//
//  Issue #67: Contacts enrichment
//

import Testing
import Foundation
@testable import STASH

@Suite("ContactMentionDetector Tests")
struct ContactMentionDetectorTests {

    @Test("Full name match is detected")
    func fullNameMatch() {
        let result = ContactMentionDetector.detect(
            in: "Lunch with Sarah Johnson tomorrow",
            knownNames: ["Sarah Johnson", "John Smith"]
        )
        #expect(result.contains("Sarah Johnson"))
        #expect(!result.contains("John Smith"))
    }

    @Test("First name with social context is detected")
    func firstNameWithSocialContext() {
        let result = ContactMentionDetector.detect(
            in: "Call Sarah about the contract",
            knownNames: ["Sarah Johnson"]
        )
        #expect(result.contains("Sarah Johnson"))
    }

    @Test("First name without social context is not detected")
    func firstNameWithoutContext() {
        let result = ContactMentionDetector.detect(
            in: "The project is going well",
            knownNames: ["Sarah Johnson"]
        )
        #expect(result.isEmpty)
    }

    @Test("Full name wins over first-name-only match")
    func fullNamePreferredOverFirstName() {
        let result = ContactMentionDetector.detect(
            in: "Meeting with Sarah Johnson",
            knownNames: ["Sarah", "Sarah Johnson"]
        )
        #expect(result.contains("Sarah Johnson"))
        #expect(result.count == 1)
    }

    @Test("Multiple contacts detected")
    func multipleContacts() {
        let result = ContactMentionDetector.detect(
            in: "Email John Smith and call Jane Doe",
            knownNames: ["John Smith", "Jane Doe", "Bob Wilson"]
        )
        #expect(result.contains("John Smith"))
        #expect(result.contains("Jane Doe"))
        #expect(!result.contains("Bob Wilson"))
    }

    @Test("Empty text returns empty")
    func emptyText() {
        let result = ContactMentionDetector.detect(in: "", knownNames: ["Sarah Johnson"])
        #expect(result.isEmpty)
    }

    @Test("Empty known names returns empty")
    func emptyKnownNames() {
        let result = ContactMentionDetector.detect(in: "Call Sarah", knownNames: [])
        #expect(result.isEmpty)
    }

    @Test("Case insensitive matching")
    func caseInsensitive() {
        let result = ContactMentionDetector.detect(
            in: "meeting with JOHN SMITH today",
            knownNames: ["John Smith"]
        )
        #expect(result.contains("John Smith"))
    }
}
