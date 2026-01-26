//
//  ModelError.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Error types for model validation and conversion
//

import Foundation

/// Errors that can occur during model validation.
///
/// These errors indicate that a model's data does not meet business requirements.
/// They are thrown by `validate()` methods on model types.
enum ValidationError: LocalizedError, Equatable {
    case emptyContent
    case contentTooLong(Int)
    case tooManyTags(Int)
    case invalidTimestamp
    case invalidConfidence(Double)
    case invalidProcessingTime(TimeInterval)
    case emptyTitle
    case titleTooLong(Int)
    case invalidDueDate
    case invalidEffort(Int)
    case invalidCompletedAt
    case tagTooLong(String, Int)
    case invalidTagCharacters(String)
    case invalidTimeOfDay(Int)

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Thought content cannot be empty"
        case .contentTooLong(let length):
            return "Content is too long (\(length) characters, maximum 5000)"
        case .tooManyTags(let count):
            return "Too many tags (\(count), maximum 5)"
        case .invalidTimestamp:
            return "Created timestamp cannot be after updated timestamp"
        case .invalidConfidence(let value):
            return "Classification confidence must be between 0.0 and 1.0 (got \(value))"
        case .invalidProcessingTime(let value):
            return "Processing time must be positive (got \(value))"
        case .emptyTitle:
            return "Task title cannot be empty"
        case .titleTooLong(let length):
            return "Title is too long (\(length) characters, maximum 200)"
        case .invalidDueDate:
            return "Due date cannot be in the past"
        case .invalidEffort(let minutes):
            return "Estimated effort must be positive (got \(minutes) minutes)"
        case .invalidCompletedAt:
            return "Completed timestamp is set but status is not done"
        case .tagTooLong(let tag, let length):
            return "Tag '\(tag)' is too long (\(length) characters, maximum 50)"
        case .invalidTagCharacters(let tag):
            return "Tag '\(tag)' contains invalid characters (only lowercase alphanumeric and hyphens allowed)"
        case .invalidTimeOfDay(let seconds):
            return "Time of day must be between 0 and 86399 seconds (got \(seconds))"
        }
    }
}

/// Errors that can occur during conversion between Swift structs and Core Data entities.
///
/// These errors indicate data corruption or inconsistencies between model representations.
enum ConversionError: LocalizedError, Equatable {
    case missingRequiredField(String)
    case invalidJSONData(String)
    case typeMismatch(String)
    case corruptedRelationship(String)

    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing or nil"
        case .invalidJSONData(let field):
            return "Invalid JSON data for field '\(field)'"
        case .typeMismatch(let message):
            return "Type mismatch during conversion: \(message)"
        case .corruptedRelationship(let message):
            return "Corrupted relationship: \(message)"
        }
    }
}

/// Errors that can occur during persistence operations.
///
/// These errors indicate problems with Core Data operations, including
/// storage failures, concurrency issues, and data integrity violations.
enum PersistenceError: LocalizedError, Equatable {
    case invalidModel(String)
    case notFound(UUID)
    case corruptedData
    case saveFailed(String)
    case concurrencyViolation
    case fetchFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidModel(let message):
            return "Invalid model: \(message)"
        case .notFound(let id):
            return "Entity with ID \(id) not found"
        case .corruptedData:
            return "Corrupted data detected in Core Data"
        case .saveFailed(let message):
            return "Failed to save to Core Data: \(message)"
        case .concurrencyViolation:
            return "Concurrent access violation detected"
        case .fetchFailed(let message):
            return "Failed to fetch from Core Data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete from Core Data: \(message)"
        }
    }

    static func == (lhs: PersistenceError, rhs: PersistenceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidModel(let a), .invalidModel(let b)):
            return a == b
        case (.notFound(let a), .notFound(let b)):
            return a == b
        case (.corruptedData, .corruptedData):
            return true
        case (.saveFailed(let a), .saveFailed(let b)):
            return a == b
        case (.concurrencyViolation, .concurrencyViolation):
            return true
        case (.fetchFailed(let a), .fetchFailed(let b)):
            return a == b
        case (.deleteFailed(let a), .deleteFailed(let b)):
            return a == b
        default:
            return false
        }
    }
}
