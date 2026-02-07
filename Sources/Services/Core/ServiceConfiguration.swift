//
//  ServiceConfiguration.swift
//  STASH
//
//  Phase 3A Spec 2: Centralized Service Configuration
//  Single source of truth for timeouts, limits, and feature flags
//

import Foundation

/// Centralized configuration for all services.
///
/// Provides timeout values, retry policies, batch sizes, and feature flags.
/// All values have sensible defaults for production use.
///
/// ## Usage
///
/// ```swift
/// let config = ServiceConfiguration.shared
/// let timeout = config.timeouts.contextGathering
/// ```
///
/// ## Testing
///
/// For tests, create a custom configuration:
/// ```swift
/// let testConfig = ServiceConfiguration(
///     timeouts: .init(contextGathering: 5.0), // longer for tests
///     features: .init(enableClassification: false)
/// )
/// ```
struct ServiceConfiguration: Sendable {
    /// Shared configuration instance for production use
    static let shared = ServiceConfiguration()

    // MARK: - Nested Types

    /// Timeout configuration for various operations
    struct Timeouts: Sendable {
        /// Maximum time for gathering all context sources (target: 300ms)
        let contextGathering: TimeInterval

        /// Maximum time for ML classification (target: 200ms)
        let classification: TimeInterval

        /// Maximum time for individual framework operations (target: 100ms)
        let frameworkOperation: TimeInterval

        /// Maximum time for network requests
        let networkRequest: TimeInterval

        /// Maximum time for geocoding operations
        let geocoding: TimeInterval

        init(
            contextGathering: TimeInterval = 0.3,
            classification: TimeInterval = 0.2,
            frameworkOperation: TimeInterval = 0.1,
            networkRequest: TimeInterval = 30.0,
            geocoding: TimeInterval = 5.0
        ) {
            self.contextGathering = contextGathering
            self.classification = classification
            self.frameworkOperation = frameworkOperation
            self.networkRequest = networkRequest
            self.geocoding = geocoding
        }
    }

    /// Retry policy configuration
    struct RetryPolicy: Sendable {
        /// Base delay before first retry (seconds)
        let baseDelay: TimeInterval

        /// Maximum number of retry attempts
        let maxRetries: Int

        /// Maximum delay between retries (seconds)
        let maxDelay: TimeInterval

        /// Jitter factor (0.0-1.0) to add randomness to delays
        let jitterFactor: Double

        init(
            baseDelay: TimeInterval = 1.0,
            maxRetries: Int = 5,
            maxDelay: TimeInterval = 32.0,
            jitterFactor: Double = 0.1
        ) {
            self.baseDelay = baseDelay
            self.maxRetries = maxRetries
            self.maxDelay = maxDelay
            self.jitterFactor = jitterFactor
        }

        /// Calculates the delay for a given retry attempt using exponential backoff
        ///
        /// - Parameter attempt: The retry attempt number (0-indexed)
        /// - Returns: The delay in seconds before the next attempt
        func delay(forAttempt attempt: Int) -> TimeInterval {
            let exponentialDelay = baseDelay * pow(2.0, Double(min(attempt, 10)))
            let cappedDelay = min(exponentialDelay, maxDelay)
            let jitter = cappedDelay * jitterFactor * Double.random(in: 0..<1)
            return cappedDelay + jitter
        }
    }

    /// Batch size and limit configuration
    struct Limits: Sendable {
        /// Maximum items to process in a single sync batch
        let syncBatchSize: Int

        /// Maximum search results to return
        let searchResultLimit: Int

        /// Maximum thoughts to load in a single list request
        let thoughtListLimit: Int

        /// Maximum contacts to cache for entity matching
        let contactCacheLimit: Int

        /// Maximum tags per thought
        let maxTagsPerThought: Int

        /// Maximum thought content length
        let maxContentLength: Int

        /// Maximum task title length
        let maxTaskTitleLength: Int

        init(
            syncBatchSize: Int = 10,
            searchResultLimit: Int = 100,
            thoughtListLimit: Int = 50,
            contactCacheLimit: Int = 1000,
            maxTagsPerThought: Int = 5,
            maxContentLength: Int = 5000,
            maxTaskTitleLength: Int = 200
        ) {
            self.syncBatchSize = syncBatchSize
            self.searchResultLimit = searchResultLimit
            self.thoughtListLimit = thoughtListLimit
            self.contactCacheLimit = contactCacheLimit
            self.maxTagsPerThought = maxTagsPerThought
            self.maxContentLength = maxContentLength
            self.maxTaskTitleLength = maxTaskTitleLength
        }
    }

    /// Feature flags for enabling/disabling functionality
    struct Features: Sendable {
        /// Whether to gather context when capturing thoughts
        let enableContextGathering: Bool

        /// Whether to run ML classification on new thoughts
        let enableClassification: Bool

        /// Whether to track user behavior for fine-tuning
        let enableFineTuningTracking: Bool

        /// Whether to sync data to backend (when available)
        let enableSync: Bool

        /// Whether to create system reminders via EventKit
        let enableSystemReminders: Bool

        /// Whether to create calendar events via EventKit
        let enableCalendarEvents: Bool

        init(
            enableContextGathering: Bool = true,
            enableClassification: Bool = true,
            enableFineTuningTracking: Bool = true,
            enableSync: Bool = true,
            enableSystemReminders: Bool = true,
            enableCalendarEvents: Bool = true
        ) {
            self.enableContextGathering = enableContextGathering
            self.enableClassification = enableClassification
            self.enableFineTuningTracking = enableFineTuningTracking
            self.enableSync = enableSync
            self.enableSystemReminders = enableSystemReminders
            self.enableCalendarEvents = enableCalendarEvents
        }
    }

    /// Logging configuration
    struct Logging: Sendable {
        /// Enable verbose debug logging
        let verboseLogging: Bool

        /// Log performance metrics
        let logPerformanceMetrics: Bool

        /// Log service initialization
        let logServiceLifecycle: Bool

        init(
            verboseLogging: Bool = false,
            logPerformanceMetrics: Bool = true,
            logServiceLifecycle: Bool = true
        ) {
            self.verboseLogging = verboseLogging
            self.logPerformanceMetrics = logPerformanceMetrics
            self.logServiceLifecycle = logServiceLifecycle
        }
    }

    // MARK: - Properties

    /// Timeout configuration
    let timeouts: Timeouts

    /// Retry policy configuration
    let retryPolicy: RetryPolicy

    /// Batch size and limit configuration
    let limits: Limits

    /// Feature flags
    let features: Features

    /// Logging configuration
    let logging: Logging

    // MARK: - Initialization

    /// Creates a configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - timeouts: Timeout configuration (default: production values)
    ///   - retryPolicy: Retry policy configuration (default: exponential backoff)
    ///   - limits: Batch size and limit configuration (default: production values)
    ///   - features: Feature flags (default: all enabled)
    ///   - logging: Logging configuration (default: minimal logging)
    init(
        timeouts: Timeouts = Timeouts(),
        retryPolicy: RetryPolicy = RetryPolicy(),
        limits: Limits = Limits(),
        features: Features = Features(),
        logging: Logging = Logging()
    ) {
        self.timeouts = timeouts
        self.retryPolicy = retryPolicy
        self.limits = limits
        self.features = features
        self.logging = logging
    }
}

// MARK: - Convenience Configurations

extension ServiceConfiguration {
    /// Configuration optimized for unit tests (longer timeouts, minimal features)
    static let testing = ServiceConfiguration(
        timeouts: Timeouts(
            contextGathering: 5.0,
            classification: 2.0,
            frameworkOperation: 1.0,
            networkRequest: 5.0,
            geocoding: 2.0
        ),
        retryPolicy: RetryPolicy(
            baseDelay: 0.1,
            maxRetries: 2,
            maxDelay: 1.0,
            jitterFactor: 0.0
        ),
        features: Features(
            enableContextGathering: false,
            enableClassification: false,
            enableFineTuningTracking: false,
            enableSync: false,
            enableSystemReminders: false,
            enableCalendarEvents: false
        ),
        logging: Logging(
            verboseLogging: true,
            logPerformanceMetrics: true,
            logServiceLifecycle: true
        )
    )

    /// Configuration for SwiftUI previews (all features disabled)
    static let preview = ServiceConfiguration(
        features: Features(
            enableContextGathering: false,
            enableClassification: false,
            enableFineTuningTracking: false,
            enableSync: false,
            enableSystemReminders: false,
            enableCalendarEvents: false
        ),
        logging: Logging(
            verboseLogging: false,
            logPerformanceMetrics: false,
            logServiceLifecycle: false
        )
    )
}
