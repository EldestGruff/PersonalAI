//
//  ConcurrencyUtilities.swift
//  STASH
//
//  Shared async timeout helpers used across the service layer.
//  Consolidates the private withTimeout implementations that previously
//  lived separately in ClassificationService and ContextService.
//

import Foundation

enum ConcurrencyUtilities {

    /// Runs `operation` and returns its result, or `nil` if it does not complete
    /// within `timeout` seconds.
    static func withTimeout<T: Sendable>(
        _ timeout: TimeInterval,
        operation: @Sendable @escaping () async -> T
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            for await result in group {
                if result != nil {
                    group.cancelAll()
                    return result
                }
            }
            return nil
        }
    }

    /// Runs `operation` and returns its result, or `defaultValue` if it does not
    /// complete within `timeout` seconds.
    static func withTimeout<T: Sendable>(
        _ timeout: TimeInterval,
        default defaultValue: T,
        operation: @Sendable @escaping () async -> T
    ) async -> T {
        await withTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return defaultValue
            }
            // First result wins — either the operation or the timeout sentinel
            for await result in group {
                group.cancelAll()
                return result
            }
            return defaultValue
        }
    }
}
