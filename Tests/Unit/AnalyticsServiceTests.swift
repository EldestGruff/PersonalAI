//
//  AnalyticsServiceTests.swift
//  STASH
//

import XCTest
@testable import STASH

final class AnalyticsServiceTests: XCTestCase {

    private let optOutKey = "analytics.optOut"
    private var testDefaults: UserDefaults!
    private var service: AnalyticsService!

    override func setUp() async throws {
        testDefaults = UserDefaults(suiteName: "test.analytics")!
        testDefaults.removePersistentDomain(forName: "test.analytics")
        service = AnalyticsService(defaults: testDefaults)
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "test.analytics")
        testDefaults = nil
        service = nil
    }

    func test_isOptedOut_defaultsFalse() {
        XCTAssertFalse(service.isOptedOut)
    }

    func test_setOptedOut_true_persists() {
        service.isOptedOut = true
        XCTAssertTrue(testDefaults.bool(forKey: optOutKey))
    }

    func test_setOptedOut_false_persists() {
        service.isOptedOut = true
        service.isOptedOut = false
        XCTAssertFalse(testDefaults.bool(forKey: optOutKey))
    }

    func test_isOptedOut_reflectsUserDefaults() {
        testDefaults.set(true, forKey: optOutKey)
        XCTAssertTrue(service.isOptedOut)

        testDefaults.set(false, forKey: optOutKey)
        XCTAssertFalse(service.isOptedOut)
    }
}
