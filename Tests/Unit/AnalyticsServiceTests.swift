//
//  AnalyticsServiceTests.swift
//  STASH
//

import XCTest
@testable import STASH

@MainActor
final class AnalyticsServiceTests: XCTestCase {

    private let optOutKey = "analytics.optOut"
    private var service: AnalyticsService { .shared }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: optOutKey)
    }

    func test_isOptedOut_defaultsFalse() {
        UserDefaults.standard.removeObject(forKey: optOutKey)
        XCTAssertFalse(service.isOptedOut)
    }

    func test_setOptedOut_true_persists() {
        service.isOptedOut = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func test_setOptedOut_false_persists() {
        service.isOptedOut = true
        service.isOptedOut = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func test_isOptedOut_reflectsUserDefaults() {
        UserDefaults.standard.set(true, forKey: optOutKey)
        XCTAssertTrue(service.isOptedOut)

        UserDefaults.standard.set(false, forKey: optOutKey)
        XCTAssertFalse(service.isOptedOut)
    }
}
