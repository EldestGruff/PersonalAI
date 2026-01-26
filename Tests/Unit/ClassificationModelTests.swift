//
//  ClassificationModelTests.swift
//  PersonalAITests
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Unit tests for Classification model validation using Swift Testing
//

import Testing
@testable import PersonalAI

@Suite("Classification Model Tests")
struct ClassificationModelTests {

    // MARK: - Happy Path

    @Test("Valid classification creation succeeds")
    func validClassificationCreation() throws {
        let classification = createValidClassification()
        try classification.validate()
    }

    @Test("Classification is identifiable")
    func classificationIsIdentifiable() {
        let classification = createValidClassification()
        #expect(classification.id != UUID())
    }

    @Test("Classification is codable")
    func classificationIsCodable() throws {
        let classification = createValidClassification()
        let encoded = try JSONEncoder().encode(classification)
        let decoded = try JSONDecoder().decode(Classification.self, from: encoded)

        #expect(decoded.id == classification.id)
        #expect(decoded.type == classification.type)
        #expect(decoded.confidence == classification.confidence)
        #expect(decoded.sentiment == classification.sentiment)
    }

    // MARK: - Confidence Validation

    @Test("Confidence below zero throws error")
    func confidenceBelowZeroThrowsError() {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: -0.1,
            entities: classification.entities,
            suggestedTags: classification.suggestedTags,
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: ValidationError.invalidConfidence(-0.1)) {
            try classification.validate()
        }
    }

    @Test("Confidence above one throws error")
    func confidenceAboveOneThrowsError() {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: 1.1,
            entities: classification.entities,
            suggestedTags: classification.suggestedTags,
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: ValidationError.invalidConfidence(1.1)) {
            try classification.validate()
        }
    }

    @Test("Confidence zero is valid")
    func confidenceZeroIsValid() throws {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: 0.0,
            entities: classification.entities,
            suggestedTags: classification.suggestedTags,
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        try classification.validate()
    }

    @Test("Confidence one is valid")
    func confidenceOneIsValid() throws {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: 1.0,
            entities: classification.entities,
            suggestedTags: classification.suggestedTags,
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        try classification.validate()
    }

    // MARK: - Processing Time Validation

    @Test("Negative processing time throws error")
    func negativeProcessingTimeThrowsError() {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: classification.confidence,
            entities: classification.entities,
            suggestedTags: classification.suggestedTags,
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: -10.0,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: ValidationError.invalidProcessingTime(-10.0)) {
            try classification.validate()
        }
    }

    @Test("Zero processing time throws error")
    func zeroProcessingTimeThrowsError() {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: classification.confidence,
            entities: classification.entities,
            suggestedTags: classification.suggestedTags,
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: 0.0,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: (any Error).self) {
            try classification.validate()
        }
    }

    // MARK: - Suggested Tags Validation

    @Test("Too many suggested tags throws error")
    func tooManySuggestedTagsThrowsError() {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: classification.confidence,
            entities: classification.entities,
            suggestedTags: ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6"],
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: ValidationError.tooManyTags(6)) {
            try classification.validate()
        }
    }

    @Test("Suggested tag too long throws error")
    func suggestedTagTooLongThrowsError() {
        let longTag = String(repeating: "a", count: 51)
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: classification.confidence,
            entities: classification.entities,
            suggestedTags: [longTag],
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: ValidationError.tagTooLong(longTag, 51)) {
            try classification.validate()
        }
    }

    @Test("Suggested tag with invalid characters throws error")
    func suggestedTagWithInvalidCharactersThrowsError() {
        var classification = createValidClassification()
        classification = Classification(
            id: classification.id,
            type: classification.type,
            confidence: classification.confidence,
            entities: classification.entities,
            suggestedTags: ["invalid tag"],
            sentiment: classification.sentiment,
            language: classification.language,
            processingTime: classification.processingTime,
            model: classification.model,
            createdAt: classification.createdAt
        )

        #expect(throws: (any Error).self) {
            try classification.validate()
        }
    }

    // MARK: - Helpers

    private func createValidClassification() -> Classification {
        Classification(
            id: UUID(),
            type: .reminder,
            confidence: 0.95,
            entities: ["email", "john"],
            suggestedTags: ["work"],
            sentiment: .neutral,
            language: "en",
            processingTime: 125.5,
            model: "foundation-model-v1",
                parsedDateTime: nil
            createdAt: Date(),
            parsedDateTime: nil
        )
    }
}
