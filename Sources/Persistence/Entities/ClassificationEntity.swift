//
//  ClassificationEntity.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Core Data entity for Classification
//

import Foundation
import CoreData

/// Core Data entity for persisting classifications.
///
/// Stores ML classification results for thoughts.
/// Has one-to-one relationship with ThoughtEntity.
@objc(ClassificationEntity)
public final class ClassificationEntity: NSManagedObject {
    /// Unique identifier
    @NSManaged public var id: UUID

    /// Classification type (enum raw value)
    @NSManaged public var type: String

    /// Confidence score (0.0-1.0)
    @NSManaged public var confidence: Double

    /// Entities stored as JSON array
    @NSManaged public var entitiesJSON: Data

    /// Suggested tags stored as JSON array
    @NSManaged public var suggestedTagsJSON: Data

    /// Sentiment (enum raw value)
    @NSManaged public var sentiment: String

    /// Language code
    @NSManaged public var language: String?

    /// Processing time in milliseconds
    @NSManaged public var processingTime: Double

    /// Model name/version
    @NSManaged public var model: String

    /// Creation timestamp
    @NSManaged public var createdAt: Date

    // MARK: - Relationships

    /// One-to-one inverse relationship to thought
    @NSManaged public var thought: ThoughtEntity

    /// One-to-many relationship to fine-tuning data
    @NSManaged public var fineTuningDataPoints: NSSet
}

// MARK: - Generated accessors for fineTuningDataPoints

extension ClassificationEntity {
    @objc(addFineTuningDataPointsObject:)
    @NSManaged public func addToFineTuningDataPoints(_ value: FineTuningDataEntity)

    @objc(removeFineTuningDataPointsObject:)
    @NSManaged public func removeFromFineTuningDataPoints(_ value: FineTuningDataEntity)

    @objc(addFineTuningDataPoints:)
    @NSManaged public func addToFineTuningDataPoints(_ values: NSSet)

    @objc(removeFineTuningDataPoints:)
    @NSManaged public func removeFromFineTuningDataPoints(_ values: NSSet)
}
