//
//  ThoughtRepositoryTests.swift
//  PersonalAITests
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Integration tests for ThoughtRepository
//

import Testing
import CoreData
@testable import PersonalAI

@Suite("Thought Repository Tests")
@MainActor
struct ThoughtRepositoryTests {

    var repository: ThoughtRepository
    var controller: PersistenceController

    init() async throws {
        controller = PersistenceController(inMemory: true)
        repository = ThoughtRepository(container: controller.container)
    }

    // MARK: - Create Tests

    @Test("Create thought succeeds")
    func createThought() async throws {
        let thought = createValidThought()
        let saved = try await repository.create(thought)

        #expect(saved.id == thought.id)
        #expect(saved.content == thought.content)
        #expect(saved.tags == thought.tags)
    }

    @Test("Create invalid thought throws error")
    func createInvalidThoughtThrowsError() async throws {
        var thought = createValidThought()
        thought = Thought(
            id: thought.id,
            userId: thought.userId,
            content: "", // Invalid
            tags: thought.tags,
            status: thought.status,
            context: thought.context,
            createdAt: thought.createdAt,
            updatedAt: thought.updatedAt,
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )

        #expect(throws: ValidationError.self) {
            try await repository.create(thought)
        }
    }

    // MARK: - Read Tests

    @Test("Fetch thought by ID succeeds")
    func fetchThoughtById() async throws {
        let thought = try await repository.create(createValidThought())

        let fetched = try await repository.fetch(thought.id)

        #expect(fetched != nil)
        #expect(fetched?.id == thought.id)
        #expect(fetched?.content == thought.content)
    }

    @Test("Fetch nonexistent thought returns nil")
    func fetchNonexistentThoughtReturnsNil() async throws {
        let result = try await repository.fetch(UUID())
        #expect(result == nil)
    }

    @Test("List all thoughts succeeds")
    func listAllThoughts() async throws {
        let thought1 = try await repository.create(createValidThought())
        let thought2 = try await repository.create(createValidThought())

        let all = try await repository.list()

        #expect(all.count == 2)
        #expect(all.contains(where: { $0.id == thought1.id }))
        #expect(all.contains(where: { $0.id == thought2.id }))
    }

    @Test("List with status filter succeeds")
    func listWithStatusFilter() async throws {
        var active = createValidThought()
        active = Thought(
            id: active.id,
            userId: active.userId,
            content: active.content,
            tags: active.tags,
            status: .active,
            context: active.context,
            createdAt: active.createdAt,
            updatedAt: active.updatedAt,
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )

        var archived = createValidThought()
        archived = Thought(
            id: archived.id,
            userId: archived.userId,
            content: archived.content,
            tags: archived.tags,
            status: .archived,
            context: archived.context,
            createdAt: archived.createdAt,
            updatedAt: archived.updatedAt,
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )

        _ = try await repository.create(active)
        _ = try await repository.create(archived)

        let activeOnly = try await repository.list(filter: .active())

        #expect(activeOnly.count == 1)
        #expect(activeOnly.first?.status == .active)
    }

    @Test("Search by content succeeds")
    func searchByContent() async throws {
        var thought1 = createValidThought()
        thought1 = Thought(
            id: thought1.id,
            userId: thought1.userId,
            content: "Email about project alpha",
            tags: thought1.tags,
            status: thought1.status,
            context: thought1.context,
            createdAt: thought1.createdAt,
            updatedAt: thought1.updatedAt,
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )

        var thought2 = createValidThought()
        thought2 = Thought(
            id: thought2.id,
            userId: thought2.userId,
            content: "Meeting notes",
            tags: thought2.tags,
            status: thought2.status,
            context: thought2.context,
            createdAt: thought2.createdAt,
            updatedAt: thought2.updatedAt,
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )

        _ = try await repository.create(thought1)
        _ = try await repository.create(thought2)

        let results = try await repository.search("Email")

        #expect(results.count == 1)
        #expect(results.first?.content.contains("Email") ?? false)
    }

    // MARK: - Update Tests

    @Test("Update thought succeeds")
    func updateThought() async throws {
        let original = try await repository.create(createValidThought())

        var updated = original
        updated = Thought(
            id: updated.id,
            userId: updated.userId,
            content: "Updated content",
            tags: ["updated"],
            status: .archived,
            context: updated.context,
            createdAt: updated.createdAt,
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )

        try await repository.update(updated)

        let fetched = try await repository.fetch(original.id)
        #expect(fetched?.content == "Updated content")
        #expect(fetched?.tags == ["updated"])
        #expect(fetched?.status == .archived)
    }

    @Test("Update nonexistent thought throws error")
    func updateNonexistentThoughtThrowsError() async throws {
        let thought = createValidThought()

        #expect(throws: PersistenceError.notFound) {
            try await repository.update(thought)
        }
    }

    // MARK: - Delete Tests

    @Test("Delete thought succeeds")
    func deleteThought() async throws {
        let thought = try await repository.create(createValidThought())

        try await repository.delete(thought.id)

        let fetched = try await repository.fetch(thought.id)
        #expect(fetched == nil)
    }

    @Test("Delete nonexistent thought throws error")
    func deleteNonexistentThoughtThrowsError() async throws {
        #expect(throws: PersistenceError.notFound) {
            try await repository.delete(UUID())
        }
    }

    // MARK: - Many-to-Many Relationship Tests

    @Test("Add related thought succeeds")
    func addRelatedThought() async throws {
        let thought1 = try await repository.create(createValidThought())
        let thought2 = try await repository.create(createValidThought())

        try await repository.addRelatedThought(thought2.id, toThought: thought1.id)

        let related = try await repository.getRelatedThoughts(for: thought1.id)
        #expect(related.count == 1)
        #expect(related.first?.id == thought2.id)

        // Verify bidirectional
        let reverseRelated = try await repository.getRelatedThoughts(for: thought2.id)
        #expect(reverseRelated.count == 1)
        #expect(reverseRelated.first?.id == thought1.id)
    }

    @Test("Remove related thought succeeds")
    func removeRelatedThought() async throws {
        let thought1 = try await repository.create(createValidThought())
        let thought2 = try await repository.create(createValidThought())

        try await repository.addRelatedThought(thought2.id, toThought: thought1.id)
        try await repository.removeRelatedThought(thought2.id, fromThought: thought1.id)

        let related = try await repository.getRelatedThoughts(for: thought1.id)
        #expect(related.count == 0)

        // Verify bidirectional removal
        let reverseRelated = try await repository.getRelatedThoughts(for: thought2.id)
        #expect(reverseRelated.count == 0)
    }

    @Test("Add multiple related thoughts succeeds")
    func addMultipleRelatedThoughts() async throws {
        let main = try await repository.create(createValidThought())
        let related1 = try await repository.create(createValidThought())
        let related2 = try await repository.create(createValidThought())
        let related3 = try await repository.create(createValidThought())

        try await repository.addRelatedThought(related1.id, toThought: main.id)
        try await repository.addRelatedThought(related2.id, toThought: main.id)
        try await repository.addRelatedThought(related3.id, toThought: main.id)

        let related = try await repository.getRelatedThoughts(for: main.id)
        #expect(related.count == 3)
    }

    // MARK: - Helpers

    private func createValidThought() -> Thought {
        Thought(
            id: UUID(),
            userId: UUID(),
            content: "Test thought content",
            tags: ["test"],
            status: .active,
            context: Context(
                timestamp: Date(),
                location: nil,
                timeOfDay: .afternoon,
                energy: .medium,
                focusState: .deep_work,
                calendar: nil,
                activity: nil,
                weather: nil,
                stateOfMind: nil,
                energyBreakdown: nil
            ),
            createdAt: Date(),
            updatedAt: Date(),
            classification: nil,
            relatedThoughtIds: [],
            taskId: nil
        )
    }
}
