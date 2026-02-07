//
//  AppError.swift
//  STASH
//
//  Phase 3A Spec 3: User-Friendly Error Handling
//  Localized error types for UI display
//

import Foundation

// MARK: - App Error

/// User-facing error types with localized descriptions.
///
/// These errors are designed to be shown directly to users with
/// helpful messages and recovery suggestions.
enum AppError: LocalizedError, Equatable {
    case validationFailed(String)
    case permissionDenied(String)
    case networkError
    case storageError
    case classificationFailed
    case contextGatheringFailed
    case notFound(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return "Invalid input: \(message)"
        case .permissionDenied(let framework):
            return "Enable \(framework) in Settings"
        case .networkError:
            return "Network unavailable - offline mode"
        case .storageError:
            return "Storage error - please try again"
        case .classificationFailed:
            return "Could not classify thought"
        case .contextGatheringFailed:
            return "Could not gather context"
        case .notFound(let entity):
            return "\(entity) not found"
        case .unknownError:
            return "Something went wrong"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied(let framework):
            return "Open Settings > Personal AI > \(framework)"
        case .networkError:
            return "Your data will sync when connection resumes"
        case .storageError:
            return "Try closing and reopening the app"
        case .classificationFailed:
            return "You can still save your thought without classification"
        case .contextGatheringFailed:
            return "Context enrichment will be skipped"
        default:
            return nil
        }
    }

    /// Creates an AppError from any Error type.
    ///
    /// Attempts to map known error types to appropriate AppError cases.
    static func from(_ error: Error) -> AppError {
        // Already an AppError
        if let appError = error as? AppError {
            return appError
        }

        // ServiceError mapping
        if let serviceError = error as? ServiceError {
            return mapServiceError(serviceError)
        }

        // ServiceValidationError mapping
        if let validationError = error as? ServiceValidationError {
            return mapValidationError(validationError)
        }

        // URLError (network issues)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError
            default:
                return .networkError
            }
        }

        // Default
        return .unknownError
    }

    private static func mapServiceError(_ error: ServiceError) -> AppError {
        switch error {
        case .permissionDenied(let framework, _):
            return .permissionDenied(framework.rawValue)
        case .frameworkUnavailable(let framework, _):
            return .permissionDenied(framework.rawValue)
        case .timeout:
            return .networkError
        case .network:
            return .networkError
        case .persistence:
            return .storageError
        case .notFound(let entity, _):
            return .notFound(entity)
        case .validation(let validationError):
            return mapValidationError(validationError)
        case .conflict:
            return .unknownError
        case .serialization:
            return .storageError
        case .internalError:
            return .unknownError
        }
    }

    private static func mapValidationError(_ error: ServiceValidationError) -> AppError {
        switch error {
        case .emptyField(let fieldName):
            return .validationFailed("\(fieldName) cannot be empty")
        case .fieldTooLong(let fieldName, let maxLength, _):
            return .validationFailed("\(fieldName) must be under \(maxLength) characters")
        case .fieldTooShort(let fieldName, let minLength, _):
            return .validationFailed("\(fieldName) must be at least \(minLength) characters")
        case .invalidFormat(let fieldName, let expected):
            return .validationFailed("\(fieldName) format should be \(expected)")
        case .outOfRange(let fieldName, let min, let max, _):
            return .validationFailed("\(fieldName) must be between \(min) and \(max)")
        case .tooManyElements(let fieldName, let maxCount, _):
            return .validationFailed("Maximum \(maxCount) \(fieldName) allowed")
        case .constraintViolation(let message):
            return .validationFailed(message)
        case .invalidTimestamp(let message):
            return .validationFailed(message)
        }
    }
}

// MARK: - UI Feedback Type Alias

/// Type alias for UserFeedback from FineTuningData model.
/// Use this for UI feedback interactions.
typealias UIFeedbackType = UserFeedback.FeedbackType
