//
//  ThoughtEntity.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Core Data entity for Thought
//

import Foundation
import CoreData

/// Core Data entity for persisting thoughts.
///
/// This is the persistence layer representation of the `Thought` domain model.
/// It uses NSManagedObject for Core Data storage and includes relationships
/// to other entities.
///
/// ## Relationships
///
/// - `relatedThoughts`: Many-to-many bidirectional self-reference
/// - `classification`: One-to-one to ClassificationEntity
/// - `task`: One-to-zero-or-one to TaskEntity
/// - `fineTuningDataPoints`: One-to-many to FineTuningDataEntity
///
/// ## Conversion
///
/// Use `Thought.toEntity(in:)` to create from domain model.
/// Use `Thought.from(_:)` to convert to domain model.
///
/// - Important: Never use ThoughtEntity directly in business logic.
///             Always convert to/from `Thought` struct.
@objc(ThoughtEntity)
public final class ThoughtEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged public var id: UUID

    /// User who owns this thought
    @NSManaged public var userId: UUID

    /// Thought content
    @NSManaged public var content: String

    /// Rich text content with formatting (iOS 15+, optional)
    /// Stored as Data (serialized AttributedString)
    @NSManaged public var attributedContentData: Data?

    /// Tags stored as JSON array
    @NSManaged public var tagsJSON: Data

    /// Status as string (enum raw value)
    @NSManaged public var status: String

    /// Context stored as JSON
    @NSManaged public var contextJSON: Data

    /// Creation timestamp
    @NSManaged public var createdAt: Date

    /// Last update timestamp
    @NSManaged public var updatedAt: Date

    /// Optional task ID
    @NSManaged public var taskId: UUID?

    // MARK: - Relationships

    /// Many-to-many self-referencing relationship
    @NSManaged public var relatedThoughts: NSSet

    /// One-to-one relationship to classification
    @NSManaged public var classification: ClassificationEntity?

    /// One-to-many relationship to fine-tuning data
    @NSManaged public var fineTuningDataPoints: NSSet
}

// MARK: - Generated accessors for relatedThoughts

extension ThoughtEntity {
    /// Adds a related thought (bidirectional)
    @objc(addRelatedThoughtsObject:)
    @NSManaged public func addToRelatedThoughts(_ value: ThoughtEntity)

    /// Removes a related thought (bidirectional)
    @objc(removeRelatedThoughtsObject:)
    @NSManaged public func removeFromRelatedThoughts(_ value: ThoughtEntity)

    /// Adds multiple related thoughts (bidirectional)
    @objc(addRelatedThoughts:)
    @NSManaged public func addToRelatedThoughts(_ values: NSSet)

    /// Removes multiple related thoughts (bidirectional)
    @objc(removeRelatedThoughts:)
    @NSManaged public func removeFromRelatedThoughts(_ values: NSSet)
}

// MARK: - Generated accessors for fineTuningDataPoints

extension ThoughtEntity {
    /// Adds a fine-tuning data point
    @objc(addFineTuningDataPointsObject:)
    @NSManaged public func addToFineTuningDataPoints(_ value: FineTuningDataEntity)

    /// Removes a fine-tuning data point
    @objc(removeFineTuningDataPointsObject:)
    @NSManaged public func removeFromFineTuningDataPoints(_ value: FineTuningDataEntity)

    /// Adds multiple fine-tuning data points
    @objc(addFineTuningDataPoints:)
    @NSManaged public func addToFineTuningDataPoints(_ values: NSSet)

    /// Removes multiple fine-tuning data points
    @objc(removeFineTuningDataPoints:)
    @NSManaged public func removeFromFineTuningDataPoints(_ values: NSSet)
}
