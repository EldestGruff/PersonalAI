//
//  TaskService.swift
//  STASH
//
//  Phase 3A Spec 2: Task Domain Service
//  Business logic for task management
//

import Foundation

// MARK: - Task Service Protocol

/// Protocol for task services.
///
/// Enables mocking in tests.
protocol TaskServiceProtocol: DomainServiceProtocol {
    // MARK: CRUD
    func create(_ task: Task) async throws -> Task
    func fetch(_ id: UUID) async throws -> Task?
    func list(filter: TaskFilter?) async throws -> [Task]
    func update(_ task: Task) async throws -> Task
    func delete(_ id: UUID) async throws

    // MARK: Status Transitions
    func start(_ id: UUID) async throws -> Task
    func complete(_ id: UUID) async throws -> Task
    func cancel(_ id: UUID) async throws -> Task

    // MARK: EventKit Integration
    func createSystemReminder(for task: Task) async throws -> Task
    func createCalendarEvent(for task: Task, startDate: Date, endDate: Date) async throws -> Task

    // MARK: Queries
    func listPending() async throws -> [Task]
    func listOverdue() async throws -> [Task]
    func listDueToday() async throws -> [Task]
}

// MARK: - Task Service

/// Domain service for task management.
///
/// Handles CRUD operations, status transitions, validation, and
/// integration with EventKit for system reminders and calendar events.
///
/// ## Error Handling
///
/// All operations throw `ServiceError` on failure:
/// - `.validation` for invalid input
/// - `.notFound` for missing tasks
/// - `.persistence` for Core Data errors
/// - `.permissionDenied` for EventKit permission issues
///
/// ## Status Transitions
///
/// Tasks follow a state machine:
/// - pending -> in_progress (start)
/// - pending -> done (complete)
/// - pending -> cancelled (cancel)
/// - in_progress -> done (complete)
/// - in_progress -> cancelled (cancel)
/// - done/cancelled are terminal states
actor TaskService: TaskServiceProtocol {
    // MARK: - Shared Instance

    /// Shared service instance for production use
    static let shared = TaskService(
        eventKitService: EventKitService(),
        syncService: SyncService.shared,
        fineTuningService: FineTuningService.shared
    )

    // MARK: - Dependencies

    private let repository: TaskRepository
    private let eventKitService: EventKitServiceProtocol?
    private let syncService: SyncServiceProtocol?
    private let fineTuningService: FineTuningServiceProtocol?
    private let configuration: ServiceConfiguration

    // MARK: - Initialization

    init(
        repository: TaskRepository = .shared,
        eventKitService: EventKitServiceProtocol? = nil,
        syncService: SyncServiceProtocol? = nil,
        fineTuningService: FineTuningServiceProtocol? = nil,
        configuration: ServiceConfiguration = .shared
    ) {
        self.repository = repository
        self.eventKitService = eventKitService
        self.syncService = syncService
        self.fineTuningService = fineTuningService
        self.configuration = configuration
    }

    // MARK: - Service Protocol

    nonisolated var isAvailable: Bool { true }

    // MARK: - Create

    /// Creates a new task.
    ///
    /// - Parameter task: The task to create
    /// - Returns: The created task
    /// - Throws: `ServiceError` on validation or persistence failure
    func create(_ task: Task) async throws -> Task {
        // Validate
        try validateTask(task)

        // Persist
        let created: Task
        do {
            created = try await repository.create(task)
        } catch {
            throw ServiceError.persistence(operation: "create task", underlying: error)
        }

        // Queue for sync
        if configuration.features.enableSync, let syncService {
            _Concurrency.Task {
                try? await syncService.enqueue(.task, created.id, action: .create, payload: nil)
            }
        }

        return created
    }

    // MARK: - Read

    /// Fetches a task by ID.
    func fetch(_ id: UUID) async throws -> Task? {
        do {
            return try await repository.fetch(id)
        } catch {
            throw ServiceError.persistence(operation: "fetch task", underlying: error)
        }
    }

    /// Lists tasks with optional filtering.
    func list(filter: TaskFilter?) async throws -> [Task] {
        do {
            return try await repository.list(filter: filter)
        } catch {
            throw ServiceError.persistence(operation: "list tasks", underlying: error)
        }
    }

    /// Lists pending tasks.
    func listPending() async throws -> [Task] {
        try await list(filter: .byStatus(.pending))
    }

    /// Lists overdue tasks.
    func listOverdue() async throws -> [Task] {
        try await list(filter: .overdue)
    }

    /// Lists tasks due today.
    func listDueToday() async throws -> [Task] {
        try await list(filter: .dueToday)
    }

    // MARK: - Update

    /// Updates an existing task.
    func update(_ task: Task) async throws -> Task {
        // Validate
        try validateTask(task)

        // Check exists
        guard try await repository.fetch(task.id) != nil else {
            throw ServiceError.notFound(entity: "Task", id: task.id)
        }

        // Update with new timestamp
        let updated = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: Date(),
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        do {
            try await repository.update(updated)
        } catch {
            throw ServiceError.persistence(operation: "update task", underlying: error)
        }

        // Queue for sync
        if configuration.features.enableSync, let syncService {
            _Concurrency.Task {
                try? await syncService.enqueue(.task, updated.id, action: .update, payload: nil)
            }
        }

        return updated
    }

    // MARK: - Delete

    /// Deletes a task by ID.
    func delete(_ id: UUID) async throws {
        guard try await repository.fetch(id) != nil else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }

        do {
            try await repository.delete(id)
        } catch {
            throw ServiceError.persistence(operation: "delete task", underlying: error)
        }

        // Queue for sync
        if configuration.features.enableSync, let syncService {
            _Concurrency.Task {
                try? await syncService.enqueue(.task, id, action: .delete, payload: nil)
            }
        }
    }

    // MARK: - Status Transitions

    /// Starts a task (pending -> in_progress).
    func start(_ id: UUID) async throws -> Task {
        guard let task = try await fetch(id) else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }

        guard task.status == .pending else {
            throw ServiceError.conflict(
                message: "Cannot start task with status '\(task.status.rawValue)'"
            )
        }

        let started = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: .in_progress,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: Date(),
            completedAt: nil,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        return try await update(started)
    }

    /// Completes a task (pending/in_progress -> done).
    func complete(_ id: UUID) async throws -> Task {
        guard let task = try await fetch(id) else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }

        guard task.status == .pending || task.status == .in_progress else {
            throw ServiceError.conflict(
                message: "Cannot complete task with status '\(task.status.rawValue)'"
            )
        }

        let completed = Task(
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
            updatedAt: Date(),
            completedAt: Date(),
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        let result = try await update(completed)

        // Track completion for fine-tuning
        if configuration.features.enableFineTuningTracking, let fineTuningService {
            try? await fineTuningService.trackReminderCompleted(task.sourceThoughtId)
        }

        return result
    }

    /// Cancels a task (pending/in_progress -> cancelled).
    func cancel(_ id: UUID) async throws -> Task {
        guard let task = try await fetch(id) else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }

        guard task.status == .pending || task.status == .in_progress else {
            throw ServiceError.conflict(
                message: "Cannot cancel task with status '\(task.status.rawValue)'"
            )
        }

        let cancelled = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: .cancelled,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: Date(),
            completedAt: nil,
            reminderId: task.reminderId,
            eventId: task.eventId
        )

        return try await update(cancelled)
    }

    // MARK: - EventKit Integration

    /// Creates a system reminder for the task.
    ///
    /// Updates the task with the reminder ID on success.
    func createSystemReminder(for task: Task) async throws -> Task {
        guard configuration.features.enableSystemReminders else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "System reminders are disabled"
            )
        }

        guard let eventKitService else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "EventKit service not available"
            )
        }

        // Get selected reminder list from settings
        let selectedListId = UserDefaults.standard.string(forKey: AppStorageKeys.Settings.selectedReminderListId)

        let reminderId = try await eventKitService.createReminder(
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            calendarIdentifier: selectedListId
        )

        let updated = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: Date(),
            completedAt: task.completedAt,
            reminderId: reminderId,
            eventId: task.eventId
        )

        let result = try await update(updated)

        // Track reminder creation for fine-tuning
        if configuration.features.enableFineTuningTracking, let fineTuningService {
            try? await fineTuningService.trackReminderCreated(task.sourceThoughtId)
        }

        return result
    }

    /// Creates a calendar event for the task.
    ///
    /// Updates the task with the event ID on success.
    func createCalendarEvent(for task: Task, startDate: Date, endDate: Date) async throws -> Task {
        guard configuration.features.enableCalendarEvents else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "Calendar events are disabled"
            )
        }

        guard let eventKitService else {
            throw ServiceError.frameworkUnavailable(
                framework: .eventKit,
                reason: "EventKit service not available"
            )
        }

        // Get selected calendar from settings
        let selectedCalendarId = UserDefaults.standard.string(forKey: AppStorageKeys.Settings.selectedCalendarId)

        let eventId = try await eventKitService.createEvent(
            title: task.title,
            description: task.description,
            startDate: startDate,
            endDate: endDate,
            calendarIdentifier: selectedCalendarId
        )

        let updated = Task(
            id: task.id,
            userId: task.userId,
            sourceThoughtId: task.sourceThoughtId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt,
            updatedAt: Date(),
            completedAt: task.completedAt,
            reminderId: task.reminderId,
            eventId: eventId
        )

        let result = try await update(updated)

        // Track event creation for fine-tuning
        if configuration.features.enableFineTuningTracking, let fineTuningService {
            try? await fineTuningService.trackEventCreated(task.sourceThoughtId)
        }

        return result
    }

    // MARK: - Validation

    private func validateTask(_ task: Task) throws {
        // Title validation
        let trimmedTitle = task.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTitle.isEmpty {
            throw ServiceError.validation(.emptyField(fieldName: "title"))
        }

        let maxLength = configuration.limits.maxTaskTitleLength
        if task.title.count > maxLength {
            throw ServiceError.validation(.fieldTooLong(
                fieldName: "title",
                maxLength: maxLength,
                actualLength: task.title.count
            ))
        }

        // Effort validation
        if let effort = task.estimatedEffortMinutes, effort <= 0 {
            throw ServiceError.validation(.outOfRange(
                fieldName: "estimatedEffortMinutes",
                min: 1,
                max: Double.greatestFiniteMagnitude,
                actual: Double(effort)
            ))
        }

        // CompletedAt validation
        if task.completedAt != nil && task.status != .done {
            throw ServiceError.validation(.constraintViolation(
                message: "completedAt can only be set when status is 'done'"
            ))
        }

        // Timestamp validation
        if task.createdAt > task.updatedAt {
            throw ServiceError.validation(.invalidTimestamp(
                message: "createdAt cannot be after updatedAt"
            ))
        }
    }
}

// MARK: - Mock Task Service

/// Mock task service for testing and previews.
actor MockTaskService: TaskServiceProtocol {
    nonisolated var isAvailable: Bool { true }

    var tasks: [UUID: Task] = [:]
    var createCallCount = 0

    func create(_ task: Task) async throws -> Task {
        createCallCount += 1
        tasks[task.id] = task
        return task
    }

    func fetch(_ id: UUID) async throws -> Task? {
        tasks[id]
    }

    func list(filter: TaskFilter?) async throws -> [Task] {
        Array(tasks.values)
    }

    func update(_ task: Task) async throws -> Task {
        tasks[task.id] = task
        return task
    }

    func delete(_ id: UUID) async throws {
        tasks.removeValue(forKey: id)
    }

    func start(_ id: UUID) async throws -> Task {
        guard let task = tasks[id] else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }
        let started = Task(
            id: task.id, userId: task.userId, sourceThoughtId: task.sourceThoughtId,
            title: task.title, description: task.description, priority: task.priority,
            status: .in_progress, dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt, updatedAt: Date(), completedAt: nil,
            reminderId: task.reminderId, eventId: task.eventId
        )
        tasks[id] = started
        return started
    }

    func complete(_ id: UUID) async throws -> Task {
        guard let task = tasks[id] else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }
        let completed = Task(
            id: task.id, userId: task.userId, sourceThoughtId: task.sourceThoughtId,
            title: task.title, description: task.description, priority: task.priority,
            status: .done, dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt, updatedAt: Date(), completedAt: Date(),
            reminderId: task.reminderId, eventId: task.eventId
        )
        tasks[id] = completed
        return completed
    }

    func cancel(_ id: UUID) async throws -> Task {
        guard let task = tasks[id] else {
            throw ServiceError.notFound(entity: "Task", id: id)
        }
        let cancelled = Task(
            id: task.id, userId: task.userId, sourceThoughtId: task.sourceThoughtId,
            title: task.title, description: task.description, priority: task.priority,
            status: .cancelled, dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt, updatedAt: Date(), completedAt: nil,
            reminderId: task.reminderId, eventId: task.eventId
        )
        tasks[id] = cancelled
        return cancelled
    }

    func createSystemReminder(for task: Task) async throws -> Task {
        let updatedTask = Task(
            id: task.id, userId: task.userId, sourceThoughtId: task.sourceThoughtId,
            title: task.title, description: task.description, priority: task.priority,
            status: task.status, dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt, updatedAt: Date(), completedAt: task.completedAt,
            reminderId: UUID().uuidString, eventId: task.eventId
        )
        tasks[task.id] = updatedTask
        return updatedTask
    }

    func createCalendarEvent(for task: Task, startDate: Date, endDate: Date) async throws -> Task {
        let updatedTask = Task(
            id: task.id, userId: task.userId, sourceThoughtId: task.sourceThoughtId,
            title: task.title, description: task.description, priority: task.priority,
            status: task.status, dueDate: task.dueDate,
            estimatedEffortMinutes: task.estimatedEffortMinutes,
            createdAt: task.createdAt, updatedAt: Date(), completedAt: task.completedAt,
            reminderId: task.reminderId, eventId: UUID().uuidString
        )
        tasks[task.id] = updatedTask
        return updatedTask
    }

    func listPending() async throws -> [Task] {
        tasks.values.filter { $0.status == .pending }
    }

    func listOverdue() async throws -> [Task] {
        let now = Date()
        return tasks.values.filter {
            $0.dueDate != nil && $0.dueDate! < now && $0.status != .done
        }
    }

    func listDueToday() async throws -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return tasks.values.filter {
            guard let due = $0.dueDate else { return false }
            return due >= today && due < tomorrow
        }
    }
}
