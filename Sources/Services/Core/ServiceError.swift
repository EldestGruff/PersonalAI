//
//  ServiceError.swift
//  PersonalAI
//
//  Phase 3A Spec 2: Unified Error Hierarchy
//  All service errors derive from this hierarchy for consistent handling
//

import Foundation

// MARK: - Framework Type

/// Identifies iOS frameworks that services integrate with.
///
/// Used for permission management and error reporting.
enum FrameworkType: String, Sendable, CaseIterable {
    case healthKit = "HealthKit"
    case coreLocation = "Core Location"
    case coreMotion = "Core Motion"
    case eventKit = "EventKit"
    case contacts = "Contacts"
    case speech = "Speech"
    case network = "Network"
    case foundationModels = "Foundation Models"

    /// Human-readable name for UI display
    var displayName: String { rawValue }

    /// Settings URL path component for this framework
    var settingsPath: String? {
        switch self {
        case .healthKit: return "Health"
        case .coreLocation: return "Privacy/Location"
        case .contacts: return "Privacy/Contacts"
        case .speech: return "Privacy/SpeechRecognition"
        default: return nil
        }
    }
}

// MARK: - Permission Level

/// Permission authorization states for iOS frameworks.
///
/// Maps to the various authorization status enums from iOS frameworks.
enum PermissionLevel: String, Sendable, CaseIterable {
    /// User has not yet been asked for permission
    case notDetermined

    /// Access restricted by parental controls or MDM
    case restricted

    /// User explicitly denied permission
    case denied

    /// User granted full access
    case authorized

    /// User granted limited access (e.g., selected photos only)
    case limited

    /// Whether this permission allows any access
    var allowsAccess: Bool {
        switch self {
        case .authorized, .limited: return true
        case .notDetermined, .restricted, .denied: return false
        }
    }
}

// MARK: - Service Validation Error

/// Field-level validation errors for service operations.
///
/// Used by domain services to report specific validation failures.
/// Note: This is separate from the model-level ValidationError in ModelError.swift.
enum ServiceValidationError: Error, Sendable, Equatable {
    /// Required field is empty or whitespace-only
    case emptyField(fieldName: String)

    /// Field exceeds maximum length
    case fieldTooLong(fieldName: String, maxLength: Int, actualLength: Int)

    /// Field is below minimum length
    case fieldTooShort(fieldName: String, minLength: Int, actualLength: Int)

    /// Field contains invalid characters or format
    case invalidFormat(fieldName: String, expected: String)

    /// Numeric field is out of valid range
    case outOfRange(fieldName: String, min: Double, max: Double, actual: Double)

    /// Array field has too many elements
    case tooManyElements(fieldName: String, maxCount: Int, actualCount: Int)

    /// Business rule constraint violated
    case constraintViolation(message: String)

    /// Timestamps are inconsistent (e.g., createdAt > updatedAt)
    case invalidTimestamp(message: String)
}

extension ServiceValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyField(let fieldName):
            return "\(fieldName) cannot be empty"
        case .fieldTooLong(let fieldName, let maxLength, let actualLength):
            return "\(fieldName) is too long (\(actualLength) characters, maximum is \(maxLength))"
        case .fieldTooShort(let fieldName, let minLength, let actualLength):
            return "\(fieldName) is too short (\(actualLength) characters, minimum is \(minLength))"
        case .invalidFormat(let fieldName, let expected):
            return "\(fieldName) has invalid format (expected: \(expected))"
        case .outOfRange(let fieldName, let min, let max, let actual):
            return "\(fieldName) is out of range (\(actual), must be between \(min) and \(max))"
        case .tooManyElements(let fieldName, let maxCount, let actualCount):
            return "\(fieldName) has too many elements (\(actualCount), maximum is \(maxCount))"
        case .constraintViolation(let message):
            return "Validation failed: \(message)"
        case .invalidTimestamp(let message):
            return "Invalid timestamp: \(message)"
        }
    }
}

// MARK: - Service Error

/// Unified error type for all service operations.
///
/// Provides consistent error handling, recovery suggestions, and
/// machine-readable error codes for analytics.
enum ServiceError: Error, Sendable {
    // MARK: Domain Errors (recoverable by user action)

    /// Model validation failed
    case validation(ServiceValidationError)

    /// Entity not found in persistence layer
    case notFound(entity: String, id: UUID)

    /// Operation conflicts with existing state
    case conflict(message: String)

    // MARK: Framework Errors (often require settings change)

    /// Permission not granted for framework
    case permissionDenied(framework: FrameworkType, currentLevel: PermissionLevel)

    /// Framework not available on this device
    case frameworkUnavailable(framework: FrameworkType, reason: String)

    /// Operation exceeded time limit
    case timeout(operation: String, elapsedMs: Int, limitMs: Int)

    // MARK: Infrastructure Errors

    /// Core Data or other persistence error
    case persistence(operation: String, underlying: Error)

    /// Network request failed
    case network(operation: String, underlying: Error)

    /// Encoding/decoding error
    case serialization(operation: String, underlying: Error)

    // MARK: Internal Errors (should not happen in production)

    /// Unexpected internal error (programming error)
    case internalError(message: String, file: String = #file, line: Int = #line)
}

// MARK: - LocalizedError Conformance

extension ServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .validation(let error):
            return error.localizedDescription

        case .notFound(let entity, let id):
            return "\(entity) not found (ID: \(id.uuidString.prefix(8))...)"

        case .conflict(let message):
            return "Operation conflict: \(message)"

        case .permissionDenied(let framework, _):
            return "\(framework.displayName) access not authorized"

        case .frameworkUnavailable(let framework, let reason):
            return "\(framework.displayName) is not available: \(reason)"

        case .timeout(let operation, let elapsedMs, let limitMs):
            return "\(operation) timed out (\(elapsedMs)ms, limit: \(limitMs)ms)"

        case .persistence(let operation, _):
            return "Failed to \(operation)"

        case .network(let operation, _):
            return "Network error during \(operation)"

        case .serialization(let operation, _):
            return "Data error during \(operation)"

        case .internalError(let message, _, _):
            return "Internal error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .validation:
            return "Please check the input and try again"

        case .notFound:
            return "The item may have been deleted"

        case .conflict:
            return "Please refresh and try again"

        case .permissionDenied(let framework, _):
            if let path = framework.settingsPath {
                return "Enable \(framework.displayName) in Settings > \(path)"
            }
            return "Enable \(framework.displayName) in Settings"

        case .frameworkUnavailable(let framework, _):
            return "\(framework.displayName) is not supported on this device"

        case .timeout:
            return "Please try again"

        case .persistence:
            return "Please try again. If the problem persists, restart the app"

        case .network:
            return "Check your internet connection and try again"

        case .serialization:
            return "Please update the app to the latest version"

        case .internalError:
            return "Please restart the app. If the problem persists, contact support"
        }
    }
}

// MARK: - Error Properties

extension ServiceError {
    /// Machine-readable error code for analytics and logging
    var errorCode: String {
        switch self {
        case .validation: return "VALIDATION_ERROR"
        case .notFound: return "NOT_FOUND"
        case .conflict: return "CONFLICT"
        case .permissionDenied: return "PERMISSION_DENIED"
        case .frameworkUnavailable: return "FRAMEWORK_UNAVAILABLE"
        case .timeout: return "TIMEOUT"
        case .persistence: return "PERSISTENCE_ERROR"
        case .network: return "NETWORK_ERROR"
        case .serialization: return "SERIALIZATION_ERROR"
        case .internalError: return "INTERNAL_ERROR"
        }
    }

    /// Whether the operation can be retried with the same inputs
    var isRetryable: Bool {
        switch self {
        case .validation, .notFound, .conflict, .permissionDenied, .frameworkUnavailable:
            return false
        case .timeout, .persistence, .network, .serialization, .internalError:
            return true
        }
    }

    /// The underlying error if this wraps another error
    var underlyingError: Error? {
        switch self {
        case .persistence(_, let error), .network(_, let error), .serialization(_, let error):
            return error
        default:
            return nil
        }
    }
}

// MARK: - Equatable Conformance

extension ServiceError: Equatable {
    static func == (lhs: ServiceError, rhs: ServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.validation(let l), .validation(let r)):
            return l == r
        case (.notFound(let le, let li), .notFound(let re, let ri)):
            return le == re && li == ri
        case (.conflict(let l), .conflict(let r)):
            return l == r
        case (.permissionDenied(let lf, let ll), .permissionDenied(let rf, let rl)):
            return lf == rf && ll == rl
        case (.frameworkUnavailable(let lf, let lr), .frameworkUnavailable(let rf, let rr)):
            return lf == rf && lr == rr
        case (.timeout(let lo, let le, let ll), .timeout(let ro, let re, let rl)):
            return lo == ro && le == re && ll == rl
        case (.internalError(let lm, let lf, let ll), .internalError(let rm, let rf, let rl)):
            return lm == rm && lf == rf && ll == rl
        default:
            // For wrapped errors, compare by error code only
            return lhs.errorCode == rhs.errorCode
        }
    }
}
