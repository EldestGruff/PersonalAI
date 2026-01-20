//
//  TaskRepository.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Repository for Task CRUD operations
//  Thread-safe actor-based repository
//

import Foundation
import CoreData

/// Thread-safe repository for Task persistence operations
actor TaskRepository {
    static let shared = TaskRepository()

    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: - Create

    /// Creates a new task in the persistent store
    func create(_ task: Task) async throws -> Task {
        try task.validate()

        let context = container.newBackgroundContext()

        return try await context.perform {
            let entity = try task.toEntity(in: context)
            try context.save()
            return try Task.from(entity)
        }
    }

    // MARK: - Read

    /// Fetches a task by ID
    func fetch(_ id: UUID) async throws -> Task? {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)

        guard let entity = results.first else {
            return nil
        }

        return try Task.from(entity)
    }

    /// Lists all tasks with optional filtering
    func list(filter: TaskFilter? = nil) async throws -> [Task] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")

        if let filter = filter {
            fetchRequest.predicate = filter.predicate
        }

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        let results = try context.fetch(fetchRequest)

        return try results.map { try Task.from($0) }
    }

    // MARK: - Update

    /// Updates an existing task
    func update(_ task: Task) async throws {
        try task.validate()

        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(task.id)
            }

            // Update entity properties
            entity.title = task.title
            entity.taskDescription = task.description
            entity.priority = task.priority.rawValue
            entity.status = task.status.rawValue
            entity.dueDate = task.dueDate
            entity.estimatedEffortMinutes = task.estimatedEffortMinutes.map { Int32($0) } ?? 0
            entity.completedAt = task.completedAt
            entity.updatedAt = task.updatedAt

            try context.save()
        }
    }

    // MARK: - Delete

    /// Deletes a task by ID
    func delete(_ id: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(id)
            }

            context.delete(entity)
            try context.save()
        }
    }
}

/// Filter options for task queries
enum TaskFilter: Sendable {
    case byStatus(TaskStatus)
    case byPriority(Priority)
    case overdue
    case dueToday
    case dueThisWeek

    nonisolated var predicate: NSPredicate {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .byStatus(let status):
            return NSPredicate(format: "status == %@", status.rawValue)
        case .byPriority(let priority):
            return NSPredicate(format: "priority == %@", priority.rawValue)
        case .overdue:
            return NSPredicate(format: "dueDate < %@ AND status != %@", now as NSDate, TaskStatus.done.rawValue)
        case .dueToday:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return NSPredicate(format: "dueDate >= %@ AND dueDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        case .dueThisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            return NSPredicate(format: "dueDate >= %@ AND dueDate < %@", startOfWeek as NSDate, endOfWeek as NSDate)
        }
    }
}
