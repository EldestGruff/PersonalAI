//
//  ThoughtModelTests.swift
//  PersonalAITests
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Unit tests for Thought model validation using Swift Testing
//

import Testing
@testable import PersonalAI

@Suite("Thought Model Tests")
struct ThoughtModelTests {

    // MARK: - Happy Path

    @Test("Valid thought creation succeeds")
    func validThoughtCreation() throws {
        let thought = createValidThought()
        try thought.validate()
    }

    @Test("Thought is identifiable")
    func thoughtIsIdentifiable() {
        let thought = createValidThought()
        #expect(thought.id != UUID())
    }

    @Test("Thought is codable")
    func thoughtIsCodable() throws {
        let thought = createValidThought()
        let encoded = try JSONEncoder().encode(thought)
        let decoded = try JSONDecoder().decode(Thought.self, from: encoded)

        #expect(decoded.id == thought.id)
        #expect(decoded.content == thought.content)
        #expect(decoded.tags == thought.tags)
        #expect(decoded.status == thought.status)
    }

    // MARK: - Content Validation

    @Test("Empty content throws error")
    func emptyContentThrowsError() {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: "",
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.emptyContent) {
            try thought.validate()
        }
    }

    @Test("Whitespace-only content throws error")
    func whitespaceOnlyContentThrowsError() {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: "   \n\t   ",
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.emptyContent) {
            try thought.validate()
        }
    }

    @Test("Content too long throws error")
    func contentTooLongThrowsError() {
        var thought = createValidThought()
        let longContent = String(repeating: "a", count: 5001)
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: longContent,
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.contentTooLong(5001)) {
            try thought.validate()
        }
    }

    @Test("Maximum length content is valid")
    func maxLengthContentIsValid() throws {
        var thought = createValidThought()
        let maxContent = String(repeating: "a", count: 5000)
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: maxContent,
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        try thought.validate()
    }

    // MARK: - Tags Validation

    @Test("Too many tags throws error")
    func tooManyTagsThrowsError() {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6"],
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.tooManyTags(6)) {
            try thought.validate()
        }
    }

    @Test("Maximum 5 tags is valid")
    func maxTagsIsValid() throws {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: ["tag1", "tag2", "tag3", "tag4", "tag5"],
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        try thought.validate()
    }

    @Test("Tag too long throws error")
    func tagTooLongThrowsError() {
        var thought = createValidThought()
        let longTag = String(repeating: "a", count: 51)
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: [longTag],
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.tagTooLong(longTag, 51)) {
            try thought.validate()
        }
    }

    @Test("Tag with invalid characters throws error")
    func tagWithInvalidCharactersThrowsError() {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: ["tag with spaces"],
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.invalidTagCharacters("tag with spaces")) {
            try thought.validate()
        }
    }

    @Test("Tags with hyphens are valid")
    func tagWithHyphensIsValid() throws {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: ["project-alpha", "machine-learning"],
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        try thought.validate()
    }

    // MARK: - Timestamp Validation

    @Test("CreatedAt after updatedAt throws error")
    func createdAtAfterUpdatedAtThrowsError() {
        let now = Date()
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: now.addingTimeInterval(100),
            updatedAt: now,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: ValidationError.invalidTimestamp) {
            try thought.validate()
        }
    }

    @Test("Same created and updated timestamp is valid")
    func sameCreatedAndUpdatedTimestampIsValid() throws {
        let now = Date()
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: now,
            updatedAt: now,
            classification: thought.classification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        try thought.validate()
    }

    // MARK: - Classification Validation

    @Test("Thought with invalid classification throws error")
    func thoughtWithInvalidClassificationThrowsError() {
        var thought = createValidThought()
        let invalidClassification = Classification(
            id: UUID(),
            type: .reminder,
            confidence: 1.5, // Invalid: > 1.0
            entities: ["test"],
            suggestedTags: [],
            sentiment: .neutral,
            language: "en",
            processingTime: 100,
            model: "test-model",
            parsedDateTime: nil
            createdAt: Date()
        )

        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: thought.content,
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: invalidClassification,
            relatedThoughtIds: thought.relatedThoughtIds,
            taskId: thought.taskId
        )

        #expect(throws: (any Error).self) {
            try thought.validate()
        }
    }

    // MARK: - Helpers

    private func createValidThought() -> Thought {
        Thought(
            id: UUID(),
            userId: UUID(),
            content: "This is a valid thought",
            tags: ["test"],
            status: .active,
            context: createValidContext(),
            createdAt: Date(),
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )
    }

    private func createValidContext() -> Context {
        Context(
            timestamp: Date(),
            location: nil,
            timeOfDay: .afternoon,
            energy: .medium,
            focusState: .deep_work,
            calendar: nil,
            activity: nil,
            weather: nil
        )
    }
}
