//
//  ThoughtRepository.swift
//  STASH
//
//  Phase 3A Spec 2: Repository for Thought CRUD operations
//  Thread-safe actor-based repository
//

import Foundation
import CoreData

/// Thread-safe repository for Thought persistence operations
actor ThoughtRepository {
    static let shared = ThoughtRepository()

    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    // MARK: - Create

    /// Creates a new thought in the persistent store
    func create(_ thought: Thought) async throws -> Thought {
        // Note: Validation handled by ThoughtService - repository only persists
        let context = container.newBackgroundContext()

        return try await context.perform {
            let entity = try thought.toEntity(in: context)
            try context.save()
            return try Thought.from(entity)
        }
    }

    // MARK: - Read

    /// Fetches a thought by ID
    func fetch(_ id: UUID) async throws -> Thought? {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)

        guard let entity = results.first else {
            return nil
        }

        return try Thought.from(entity)
    }

    /// Lists all thoughts with optional filtering
    func list(filter: ThoughtFilter? = nil) async throws -> [Thought] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")

        if let filter = filter {
            fetchRequest.predicate = filter.predicate
        }

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try context.fetch(fetchRequest)

        return try results.map { try Thought.from($0) }
    }

    /// Searches thoughts by content
    func search(_ query: String) async throws -> [Thought] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        fetchRequest.predicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try context.fetch(fetchRequest)

        return try results.map { try Thought.from($0) }
    }

    // MARK: - Update

    /// Updates an existing thought
    func update(_ thought: Thought) async throws {
        try thought.validate()

        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", thought.id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(thought.id)
            }

            // Update entity properties
            entity.content = thought.content
            entity.tagsJSON = try JSONEncoder().encode(thought.tags)
            entity.status = thought.status.rawValue
            entity.contextJSON = try JSONEncoder().encode(thought.context)
            entity.updatedAt = thought.updatedAt
            entity.isShiny = NSNumber(value: thought.isShiny)  // Issue #40: Persist shiny status
            entity.taskId = thought.taskId

            // Update classification (one-to-one relationship) (#49)
            if let classification = thought.classification {
                // If classification exists, update it; otherwise create new
                if let existingClassification = entity.classification {
                    // Update existing classification entity
                    existingClassification.type = classification.type.rawValue
                    existingClassification.confidence = classification.confidence
                    existingClassification.sentiment = classification.sentiment.rawValue
                    existingClassification.language = classification.language
                    existingClassification.processingTime = classification.processingTime
                    existingClassification.model = classification.model
                    existingClassification.entitiesJSON = try JSONEncoder().encode(classification.entities)
                    existingClassification.suggestedTagsJSON = try JSONEncoder().encode(classification.suggestedTags)

                    if let parsedDateTime = classification.parsedDateTime {
                        existingClassification.parsedDateTimeJSON = try JSONEncoder().encode(parsedDateTime)
                    } else {
                        existingClassification.parsedDateTimeJSON = nil
                    }
                } else {
                    // Create new classification entity
                    entity.classification = try classification.toEntity(in: context)
                    entity.classification?.thought = entity
                }
            } else {
                // Remove classification if thought no longer has one
                if let existingClassification = entity.classification {
                    context.delete(existingClassification)
                    entity.classification = nil
                }
            }

            try context.save()
        }
    }

    // MARK: - Delete

    /// Deletes a thought by ID
    func delete(_ id: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.notFound(id)
            }

            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Many-to-Many Relationships

    /// Adds a related thought relationship
    func addRelatedThought(_ relatedId: UUID, toThought thoughtId: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id IN %@", [thoughtId, relatedId])

            let results = try context.fetch(fetchRequest)

            guard let thought = results.first(where: { $0.id == thoughtId }),
                  let related = results.first(where: { $0.id == relatedId }) else {
                throw PersistenceError.notFound(thoughtId)
            }

            thought.addToRelatedThoughts(related)
            related.addToRelatedThoughts(thought)

            try context.save()
        }
    }

    /// Removes a related thought relationship
    func removeRelatedThought(_ relatedId: UUID, fromThought thoughtId: UUID) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id IN %@", [thoughtId, relatedId])

            let results = try context.fetch(fetchRequest)

            guard let thought = results.first(where: { $0.id == thoughtId }),
                  let related = results.first(where: { $0.id == relatedId }) else {
                throw PersistenceError.notFound(thoughtId)
            }

            thought.removeFromRelatedThoughts(related)
            related.removeFromRelatedThoughts(thought)

            try context.save()
        }
    }

    /// Gets all related thoughts for a given thought
    func getRelatedThoughts(for thoughtId: UUID) async throws -> [Thought] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", thoughtId as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let entity = try context.fetch(fetchRequest).first else {
            throw PersistenceError.notFound(thoughtId)
        }

        if let relatedSet = entity.relatedThoughts as? Set<ThoughtEntity> {
            return try relatedSet.map { try Thought.from($0) }
        }

        return []
    }

    // MARK: - Optimized Aggregation Queries for Charts
    //
    // These methods use Core Data's NSExpression for server-side aggregation
    // to avoid loading all thoughts into memory (critical for 10,000+ thoughts)

    /// Get distinct capture dates for streak calculation
    /// Uses optimized query to avoid loading full thought entities
    func getDistinctCaptureDates() async throws -> [Date] {
        let context = container.viewContext

        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "ThoughtEntity")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true

        // Only fetch the createdAt date (not the full entity)
        fetchRequest.propertiesToFetch = ["createdAt"]

        let results = try context.fetch(fetchRequest)

        // Extract dates and normalize to start of day
        let calendar = Calendar.current
        return results.compactMap { dict in
            guard let date = dict["createdAt"] as? Date else { return nil }
            return calendar.startOfDay(for: date)
        }
        .sorted()
    }

    /// Aggregate sentiment by date range
    /// Returns daily averages without loading all thoughts into memory
    func aggregateSentimentByDate(
        startDate: Date?,
        endDate: Date
    ) async throws -> [(date: Date, avgSentiment: Double, count: Int)] {
        // Note: Core Data doesn't support aggregating on nested JSON (classification.sentiment)
        // We'll need to load thoughts for this query
        // Future optimization: Add sentimentValue as a direct property on ThoughtEntity

        let thoughts = try await list(filter: nil)
        let filtered = thoughts.filter { thought in
            guard let start = startDate else { return thought.createdAt <= endDate }
            return thought.createdAt >= start && thought.createdAt <= endDate
        }

        let calendar = Calendar.current

        // Group by day
        let grouped = Dictionary(grouping: filtered) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        return grouped.compactMap { date, dayThoughts in
            let sentiments = dayThoughts.compactMap { thought -> Double? in
                guard let sentiment = thought.classification?.sentiment else { return nil }
                switch sentiment {
                case .very_negative: return -1.0
                case .negative: return -0.5
                case .neutral: return 0.0
                case .positive: return 0.5
                case .very_positive: return 1.0
                }
            }

            guard !sentiments.isEmpty else { return nil }
            let avg = sentiments.reduce(0.0, +) / Double(sentiments.count)

            return (date: date, avgSentiment: avg, count: dayThoughts.count)
        }
        .sorted { $0.date < $1.date }
    }

    /// Aggregate thought count by type
    /// Optimized query using Core Data grouping
    func aggregateByType(
        startDate: Date?,
        endDate: Date
    ) async throws -> [(type: ClassificationType, count: Int)] {
        // Note: Core Data doesn't support grouping on nested JSON (classification.type)
        // We'll need to load thoughts for this query
        // Future optimization: Add classificationTypeValue as a direct property

        let thoughts = try await list(filter: nil)
        let filtered = thoughts.filter { thought in
            guard let start = startDate else { return thought.createdAt <= endDate }
            return thought.createdAt >= start && thought.createdAt <= endDate
        }

        let grouped = Dictionary(grouping: filtered) { thought in
            thought.classification?.type ?? .note
        }

        return grouped.map { type, thoughts in
            (type: type, count: thoughts.count)
        }
        .sorted { $0.count > $1.count }
    }

    /// Aggregate tag frequency
    /// Returns top N tags with their counts
    func aggregateTagFrequency(
        startDate: Date?,
        endDate: Date,
        limit: Int
    ) async throws -> [(tag: String, count: Int)] {
        let thoughts = try await list(filter: nil)
        let filtered = thoughts.filter { thought in
            guard let start = startDate else { return thought.createdAt <= endDate }
            return thought.createdAt >= start && thought.createdAt <= endDate
        }

        // Flatten all tags and count occurrences
        let allTags = filtered.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }

        return tagCounts
            .map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    /// Get thought count by hour of day (for heatmap)
    /// Returns array of 24 elements (hour 0-23)
    func aggregateByHourOfDay(
        startDate: Date?,
        endDate: Date
    ) async throws -> [Int] {
        let thoughts = try await list(filter: nil)
        let filtered = thoughts.filter { thought in
            guard let start = startDate else { return thought.createdAt <= endDate }
            return thought.createdAt >= start && thought.createdAt <= endDate
        }

        let calendar = Calendar.current
        var hourCounts = Array(repeating: 0, count: 24)

        for thought in filtered {
            let hour = calendar.component(.hour, from: thought.createdAt)
            hourCounts[hour] += 1
        }

        return hourCounts
    }

    /// Get thought count by day of week (for heatmap)
    /// Returns array of 7 elements (Sunday=0, Saturday=6)
    func aggregateByDayOfWeek(
        startDate: Date?,
        endDate: Date
    ) async throws -> [Int] {
        let thoughts = try await list(filter: nil)
        let filtered = thoughts.filter { thought in
            guard let start = startDate else { return thought.createdAt <= endDate }
            return thought.createdAt >= start && thought.createdAt <= endDate
        }

        let calendar = Calendar.current
        var dayCounts = Array(repeating: 0, count: 7)

        for thought in filtered {
            let weekday = calendar.component(.weekday, from: thought.createdAt)
            dayCounts[weekday - 1] += 1  // Convert to 0-indexed
        }

        return dayCounts
    }
}

/// Filter options for thought queries
enum ThoughtFilter: Sendable {
    case active
    case archived
    case byUserId(UUID)
    case byStatus(ThoughtStatus)
    case byTag(String)

    nonisolated var predicate: NSPredicate {
        switch self {
        case .active:
            return NSPredicate(format: "status == %@", ThoughtStatus.active.rawValue)
        case .archived:
            return NSPredicate(format: "status == %@", ThoughtStatus.archived.rawValue)
        case .byUserId(let userId):
            return NSPredicate(format: "userId == %@", userId as CVarArg)
        case .byStatus(let status):
            return NSPredicate(format: "status == %@", status.rawValue)
        case .byTag(let tag):
            return NSPredicate(format: "tagsJSON CONTAINS %@", tag)
        }
    }
}
