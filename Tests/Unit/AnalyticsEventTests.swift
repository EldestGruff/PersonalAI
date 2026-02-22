//
//  AnalyticsEventTests.swift
//  STASH
//

import XCTest
@testable import STASH

final class AnalyticsEventTests: XCTestCase {

    // MARK: - Signal Names

    func test_screenViewed_signalName() {
        XCTAssertEqual(AnalyticsEvent.screenViewed(.browse).signalName, "screenViewed")
    }

    func test_thoughtCaptured_signalName() {
        XCTAssertEqual(AnalyticsEvent.thoughtCaptured(method: .text).signalName, "thoughtCaptured")
    }

    func test_shinyPromoted_signalName() {
        XCTAssertEqual(AnalyticsEvent.shinyPromoted(count: 1).signalName, "shinyPromoted")
    }

    func test_contextEnrichmentFailed_signalName() {
        XCTAssertEqual(
            AnalyticsEvent.contextEnrichmentFailed(component: .healthKit).signalName,
            "contextEnrichmentFailed"
        )
    }

    // MARK: - Metadata

    func test_screenViewed_metadata_containsScreen() {
        let event = AnalyticsEvent.screenViewed(.insights)
        XCTAssertEqual(event.metadata["screen"], "insights")
    }

    func test_thoughtCaptured_voice_metadata() {
        let event = AnalyticsEvent.thoughtCaptured(method: .voice)
        XCTAssertEqual(event.metadata["method"], "voice")
    }

    func test_thoughtCaptured_text_metadata() {
        let event = AnalyticsEvent.thoughtCaptured(method: .text)
        XCTAssertEqual(event.metadata["method"], "text")
    }

    func test_classificationOverridden_metadata() {
        let event = AnalyticsEvent.classificationOverridden(from: "note", to: "reminder")
        XCTAssertEqual(event.metadata["from"], "note")
        XCTAssertEqual(event.metadata["to"], "reminder")
    }

    func test_searchPerformed_metadata() {
        let event = AnalyticsEvent.searchPerformed(resultCount: 7)
        XCTAssertEqual(event.metadata["resultCount"], "7")
    }

    func test_shinyPromoted_metadata() {
        let event = AnalyticsEvent.shinyPromoted(count: 3)
        XCTAssertEqual(event.metadata["count"], "3")
    }

    func test_acornEarned_metadata() {
        let event = AnalyticsEvent.acornEarned(amount: 10)
        XCTAssertEqual(event.metadata["amount"], "10")
    }

    func test_contextEnrichmentFailed_healthKit_metadata() {
        let event = AnalyticsEvent.contextEnrichmentFailed(component: .healthKit)
        XCTAssertEqual(event.metadata["component"], "healthkit")
    }

    func test_contextEnrichmentFailed_location_metadata() {
        let event = AnalyticsEvent.contextEnrichmentFailed(component: .location)
        XCTAssertEqual(event.metadata["component"], "location")
    }

    func test_onboardingCompleted_metadata() {
        let event = AnalyticsEvent.onboardingCompleted(stepsCompleted: 6)
        XCTAssertEqual(event.metadata["stepsCompleted"], "6")
    }


    func test_acornSpent_metadata() {
        let event = AnalyticsEvent.acornSpent(amount: 5)
        XCTAssertEqual(event.metadata["amount"], "5")
    }

    func test_siriShortcutUsed_metadata() {
        let event = AnalyticsEvent.siriShortcutUsed(intent: "capture")
        XCTAssertEqual(event.metadata["intent"], "capture")
    }

    func test_badgeUnlocked_metadata() {
        let event = AnalyticsEvent.badgeUnlocked(badgeId: "streak-7")
        XCTAssertEqual(event.metadata["badgeId"], "streak-7")
    }

    func test_themeChanged_metadata() {
        let event = AnalyticsEvent.themeChanged(theme: "minimalist")
        XCTAssertEqual(event.metadata["theme"], "minimalist")
    }

    func test_personaSelected_metadata() {
        let event = AnalyticsEvent.personaSelected(persona: "brainstormPartner")
        XCTAssertEqual(event.metadata["persona"], "brainstormPartner")
    }

    func test_onboardingAbandoned_metadata() {
        let event = AnalyticsEvent.onboardingAbandoned(atStep: 3)
        XCTAssertEqual(event.metadata["atStep"], "3")
    }

    // MARK: - Privacy: no personal data in metadata

    func test_noPersonalDataLeaks() {
        let events: [AnalyticsEvent] = [
            .thoughtCaptured(method: .text),
            .thoughtDeleted,
            .thoughtArchived,
            .searchZeroResults,
            .aiInsightsGenerated,
            .shinySurfaced,
            .classificationFailed,
            .aiUnavailable,
        ]
        let forbidden = ["content", "tags", "query", "text", "location", "health"]
        for event in events {
            for key in forbidden {
                XCTAssertNil(event.metadata[key], "\(event.signalName) leaks '\(key)'")
            }
        }
    }

    // MARK: - Zero-metadata events

    func test_thoughtDeleted_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.thoughtDeleted.metadata.isEmpty)
    }

    func test_classificationFailed_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.classificationFailed.metadata.isEmpty)
    }

    func test_thoughtArchived_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.thoughtArchived.metadata.isEmpty)
    }

    func test_searchZeroResults_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.searchZeroResults.metadata.isEmpty)
    }

    func test_aiInsightsGenerated_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.aiInsightsGenerated.metadata.isEmpty)
    }

    func test_shinySurfaced_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.shinySurfaced.metadata.isEmpty)
    }

    func test_aiUnavailable_emptyMetadata() {
        XCTAssertTrue(AnalyticsEvent.aiUnavailable.metadata.isEmpty)
    }
}
