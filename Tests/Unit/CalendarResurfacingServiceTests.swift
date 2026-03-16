//
//  CalendarResurfacingServiceTests.swift
//  STASHTests
//
//  Issue #22: Calendar resurfacing
//

import Testing
import Foundation
@testable import STASH

@Suite("CalendarResurfacingService Tests")
struct CalendarResurfacingServiceTests {

    @Test("Rate limiter: allows up to 3 notifications per day")
    func rateLimiterAllowsThreePerDay() {
        let limiter = ResurfacingRateLimiter()
        limiter.reset()

        #expect(limiter.canSchedule())
        limiter.recordScheduled()
        #expect(limiter.canSchedule())
        limiter.recordScheduled()
        #expect(limiter.canSchedule())
        limiter.recordScheduled()
        #expect(!limiter.canSchedule())  // 4th is denied
    }

    @Test("Rate limiter: resets on new day")
    func rateLimiterResetsOnNewDay() {
        let limiter = ResurfacingRateLimiter()
        limiter.reset()

        limiter.recordScheduled()
        limiter.recordScheduled()
        limiter.recordScheduled()
        #expect(!limiter.canSchedule())

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        limiter.overrideDateForTesting(yesterday)

        #expect(limiter.canSchedule())
    }

    @Test("Notification identifier is deterministic for the same event")
    func notificationIdentifierIsDeterministic() {
        let event = UpcomingEvent(id: "event-abc-123", title: "Team Meeting", startDate: Date())
        let id1 = CalendarResurfacingService.notificationIdentifier(for: event)
        let id2 = CalendarResurfacingService.notificationIdentifier(for: event)
        #expect(id1 == id2)
        #expect(id1.hasPrefix("resurfacing."))
    }

    @Test("Events starting in less than 10 minutes are skipped")
    func eventsStartingTooSoonAreSkipped() {
        let soonEvent = UpcomingEvent(
            id: "soon",
            title: "Meeting",
            startDate: Date().addingTimeInterval(5 * 60)
        )
        #expect(!CalendarResurfacingService.isEligible(event: soonEvent))
    }

    @Test("Events starting in 30+ minutes are eligible")
    func eventsStartingLaterAreEligible() {
        let laterEvent = UpcomingEvent(
            id: "later",
            title: "Meeting",
            startDate: Date().addingTimeInterval(45 * 60)
        )
        #expect(CalendarResurfacingService.isEligible(event: laterEvent))
    }
}
