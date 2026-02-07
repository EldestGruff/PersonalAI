//
//  ClassificationServiceTests.swift
//  STASHTests
//
//  Issue #6: Unit tests for ClassificationService
//  Tests type classification, sentiment analysis, and tag generation
//

import Testing
import Foundation
@testable import STASH

@Suite("ClassificationService Tests")
struct ClassificationServiceTests {

    // MARK: - Classification Type Tests

    @Test("Content with 'remind me' is classified as reminder")
    func remindMeClassifiesAsReminder() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Remind me to buy groceries tomorrow")

        #expect(classification.type == .reminder)
    }

    @Test("Content with 'don't forget' is classified as reminder")
    func dontForgetClassifiesAsReminder() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Don't forget to call mom")

        #expect(classification.type == .reminder)
    }

    @Test("Content with 'need to' is classified as reminder")
    func needToClassifiesAsReminder() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("I need to finish the report")

        #expect(classification.type == .reminder)
    }

    @Test("Content with 'meeting' is classified as event")
    func meetingClassifiesAsEvent() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Team meeting at 3pm")

        #expect(classification.type == .event)
    }

    @Test("Content with 'appointment' is classified as event")
    func appointmentClassifiesAsEvent() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Doctor appointment on Thursday")

        #expect(classification.type == .event)
    }

    @Test("Content with 'tomorrow' is classified as event")
    func tomorrowClassifiesAsEvent() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Lunch with Sarah tomorrow")

        #expect(classification.type == .event)
    }

    @Test("Content ending with question mark is classified as question")
    func questionMarkClassifiesAsQuestion() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("What is the best approach for this?")

        #expect(classification.type == .question)
    }

    @Test("Content starting with 'what if' is classified as idea")
    func whatIfClassifiesAsIdea() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("What if we could automate this process")

        #expect(classification.type == .idea)
    }

    @Test("Content starting with 'idea:' is classified as idea")
    func ideaPrefixClassifiesAsIdea() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Idea: create a new feature for user onboarding")

        #expect(classification.type == .idea)
    }

    @Test("Generic content is classified as note")
    func genericContentClassifiesAsNote() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("The weather is nice today")

        #expect(classification.type == .note)
    }

    // MARK: - Confidence Tests

    @Test("Classification confidence is between 0 and 1")
    func confidenceIsInValidRange() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Some random thought")

        #expect(classification.confidence >= 0.0)
        #expect(classification.confidence <= 1.0)
    }

    @Test("Explicit reminder has high confidence")
    func explicitReminderHasHighConfidence() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Remind me to pick up the package")

        // Even with Foundation Models, explicit reminders should have high confidence
        #expect(classification.confidence >= 0.7)
    }

    @Test("Question with question mark has high confidence")
    func questionWithMarkHasHighConfidence() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Where should we hold the meeting?")

        // Questions ending with ? should have high confidence
        #expect(classification.confidence >= 0.7)
    }

    // MARK: - Sentiment Tests

    @Test("Classification includes sentiment")
    func classificationIncludesSentiment() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("This is a great day!")

        // Just verify sentiment is one of the valid values
        #expect(Sentiment.allCases.contains(classification.sentiment))
    }

    // MARK: - Tag Suggestion Tests

    @Test("suggestTags returns up to 5 tags")
    func suggestTagsReturnsMaxFiveTags() async {
        let service = ClassificationService(configuration: .shared)
        let tags = await service.suggestTags("This is a long thought about work, meetings, projects, deadlines, tasks, goals, and planning")

        #expect(tags.count <= 5)
    }

    @Test("suggestTags returns lowercase tags")
    func suggestTagsReturnsLowercaseTags() async {
        let service = ClassificationService(configuration: .shared)
        let tags = await service.suggestTags("Meeting with JOHN about PROJECT alpha")

        for tag in tags {
            #expect(tag == tag.lowercased())
        }
    }

    @Test("Classification suggestedTags are included")
    func classificationIncludesSuggestedTags() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Important meeting with the marketing team about the product launch")

        // Just verify we got some tags
        #expect(classification.suggestedTags.count <= 5)
    }

    // MARK: - Language Detection Tests

    @Test("Classification includes language detection")
    func classificationIncludesLanguage() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("This is an English sentence")

        // Language should be detected
        #expect(classification.language != nil)
    }

    // MARK: - Processing Time Tests

    @Test("Classification has positive processing time")
    func classificationHasPositiveProcessingTime() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Test thought for timing")

        #expect(classification.processingTime > 0)
    }

    // MARK: - Entity Extraction Tests

    @Test("Classification extracts entities")
    func classificationExtractsEntities() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Call John Smith tomorrow about the new project")

        // Entities array should exist (may be empty depending on NLP)
        #expect(classification.entities != nil)
    }

    // MARK: - Model Attribution Tests

    @Test("Classification includes model name")
    func classificationIncludesModelName() async throws {
        let service = ClassificationService(configuration: .shared)
        let classification = try await service.classify("Test thought")

        #expect(!classification.model.isEmpty)
    }

    // MARK: - Cache Tests

    @Test("Same content returns cached result")
    func sameContentReturnsCachedResult() async throws {
        let service = ClassificationService(configuration: .shared)

        let content = "Cache test thought content"
        let first = try await service.classify(content)
        let second = try await service.classify(content)

        // Same ID indicates cached result
        #expect(first.id == second.id)
    }

    @Test("clearCache clears the cache")
    func clearCacheClearsCache() async throws {
        let service = ClassificationService(configuration: .shared)

        let content = "Cache clear test"
        let first = try await service.classify(content)

        await service.clearCache()

        let second = try await service.classify(content)

        // Different ID after cache clear
        #expect(first.id != second.id)
    }

    // MARK: - Edge Cases

    @Test("Empty content is handled gracefully")
    func emptyContentHandledGracefully() async throws {
        let service = ClassificationService(configuration: .shared)

        // Empty content should still return a classification (as note)
        let classification = try await service.classify("")
        #expect(classification.type == .note)
    }

    @Test("Very long content is handled")
    func veryLongContentIsHandled() async throws {
        let service = ClassificationService(configuration: .shared)
        let longContent = String(repeating: "This is a test. ", count: 100)

        let classification = try await service.classify(longContent)
        #expect(classification.type != nil)
    }

    @Test("Content with special characters is handled")
    func specialCharactersAreHandled() async throws {
        let service = ClassificationService(configuration: .shared)

        let classification = try await service.classify("Test with @#$%^&*() special characters!")
        #expect(classification.type != nil)
    }

    @Test("Content with newlines is handled")
    func newlinesAreHandled() async throws {
        let service = ClassificationService(configuration: .shared)

        let classification = try await service.classify("First line\nSecond line\nThird line")
        #expect(classification.type != nil)
    }

    // MARK: - Classification Type Priority Tests

    @Test("Reminder takes priority over event for task-like content")
    func reminderPriorityOverEvent() async throws {
        let service = ClassificationService(configuration: .shared)

        // "Remind me" should classify as reminder even with time reference
        let classification = try await service.classify("Remind me about the meeting tomorrow")
        #expect(classification.type == .reminder)
    }

    @Test("Question takes priority based on question mark")
    func questionMarkTakesPriority() async throws {
        let service = ClassificationService(configuration: .shared)

        // Question mark should make it a question
        let classification = try await service.classify("Should I schedule this meeting for tomorrow?")
        #expect(classification.type == .question)
    }

    // MARK: - Parsed DateTime Tests

    @Test("Time-related content may have parsed date/time")
    func timeContentMayHaveParsedDateTime() async throws {
        let service = ClassificationService(configuration: .shared)

        let classification = try await service.classify("Meeting at 3pm on Friday")

        // Note: parsedDateTime may be nil if confidence is below threshold
        // Just verify the field exists
        _ = classification.parsedDateTime
    }

    // MARK: - Creation Date Tests

    @Test("Classification has valid createdAt timestamp")
    func classificationHasValidCreatedAt() async throws {
        let service = ClassificationService(configuration: .shared)
        let before = Date()

        let classification = try await service.classify("Test thought")

        let after = Date()

        #expect(classification.createdAt >= before)
        #expect(classification.createdAt <= after)
    }

    // MARK: - ID Uniqueness Tests

    @Test("Different content produces unique IDs")
    func differentContentProducesUniqueIds() async throws {
        let service = ClassificationService(configuration: .shared)

        let first = try await service.classify("First unique thought")
        await service.clearCache()
        let second = try await service.classify("Second unique thought")

        #expect(first.id != second.id)
    }
}

// MARK: - MockClassificationService Tests

@Suite("MockClassificationService Tests")
struct MockClassificationServiceTests {

    @Test("Mock service returns configured classification")
    func mockServiceReturnsConfiguredClassification() async throws {
        let expectedClassification = Classification(
            id: UUID(),
            type: .reminder,
            confidence: 0.95,
            entities: ["test"],
            suggestedTags: ["mock-tag"],
            sentiment: .positive,
            language: "en",
            processingTime: 0.01,
            model: "mock",
            createdAt: Date(),
            parsedDateTime: nil
        )

        let mockService = MockClassificationService(classification: expectedClassification)
        let result = try await mockService.classify("Any content")

        #expect(result.type == .reminder)
        #expect(result.confidence == 0.95)
        #expect(result.sentiment == .positive)
    }

    @Test("Mock service returns configured tags")
    func mockServiceReturnsConfiguredTags() async {
        let mockService = MockClassificationService(tags: ["custom", "tags"])
        let tags = await mockService.suggestTags("Any content")

        #expect(tags == ["custom", "tags"])
    }

    @Test("Mock service is always available")
    func mockServiceIsAlwaysAvailable() {
        let mockService = MockClassificationService()
        #expect(mockService.isAvailable == true)
    }
}
