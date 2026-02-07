//
//  TaskModelTests.swift
//  STASHTests
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Unit tests for Task model validation using Swift Testing
//

import Testing
@testable import STASH

@Suite("Task Model Tests")
struct TaskModelTests {

    // MARK: - Happy Path

    @Test("Valid task creation succeeds")
    func validTaskCreation() throws {
        let task = createValidTask()
        try task.validate()
    }

    @Test("Task is identifiable")
    func taskIsIdentifiable() {
        let task = createValidTask()
        #expect(task.id != UUID())
    }

    @Test("Task is codable")
    func taskIsCodable() throws {
        let task = createValidTask()
        let encoded = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(Task.self, from: encoded)

        #expect(decoded.id == task.id)
        #expect(decoded.title == task.title)
        #expect(decoded.priority == task.priority)
        #expect(decoded.status == task.status)
    }

    // MARK: - Title Validation

    @Test("Empty title throws error")
    func emptyTitleThrowsError() {
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: "",
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: ValidationError.emptyTitle) {
            try task.validate()
        }
    }

    @Test("Whitespace-only title throws error")
    func whitespaceOnlyTitleThrowsError() {
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: "   \n\t   ",
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: ValidationError.emptyTitle) {
            try task.validate()
        }
    }

    @Test("Title too long throws error")
    func titleTooLongThrowsError() {
        let longTitle = String(repeating: "a", count: 201)
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: longTitle,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: ValidationError.titleTooLong(201)) {
            try task.validate()
        }
    }

    @Test("Maximum length title is valid")
    func maxLengthTitleIsValid() throws {
        let maxTitle = String(repeating: "a", count: 200)
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: maxTitle,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        try task.validate()
    }

    // MARK: - Due Date Validation

    @Test("Due date in past throws error")
    func dueDateInPastThrowsError() {
        let pastDate = Date().addingTimeInterval(-86400 * 2) // 2 days ago
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: pastDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: ValidationError.invalidDueDate) {
            try task.validate()
        }
    }

    @Test("Due date in future is valid")
    func dueDateInFutureIsValid() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7) // 7 days from now
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: futureDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        try task.validate()
    }

    // MARK: - Effort Validation

    @Test("Negative effort throws error")
    func negativeEffortThrowsError() {
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: -10,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: ValidationError.invalidEffort(-10)) {
            try task.validate()
        }
    }

    @Test("Zero effort throws error")
    func zeroEffortThrowsError() {
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: 0,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: (any Error).self) {
            try task.validate()
        }
    }

    // MARK: - Completion Validation

    @Test("Completed timestamp set but status not done throws error")
    func completedAtSetButNotDoneThrowsError() {
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: .pending,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: Date(),
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        #expect(throws: ValidationError.invalidCompletedAt) {
            try task.validate()
        }
    }

    @Test("Completed timestamp with done status is valid")
    func completedAtSetWithDoneStatusIsValid() throws {
        var task = createValidTask()
        task = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: .done,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedAt: Date(),
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        try task.validate()
    }

    // MARK: - Helpers

    private func createValidTask() -> Task {
        Task(
            id: UUID(),
            userId: UUID(),
            sourceThoughtId: UUID(),
            title: "Valid task title",
            description: "Valid task description",
            priority: .medium,
            status: .pending,
            dueDate: Date().addingTimeInterval(86400),
            estimatedEffortMinutes: 60,
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: nil,
            reminderId: nil,
            eventId: nil
        )
    }
}
