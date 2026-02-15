//
//  SquirrelReminderService.swift
//  STASH
//
//  Gamification issue #43: Squirrel Reminders
//
//  Schedules persona-voiced push notifications using capture history for
//  intelligent timing. Never more than 1 per day. Fully opt-in.
//
//  Notification types:
//  - Daily nudge      — near user's peak capture hour
//  - Streak celebrate — morning after reaching a milestone
//  - Gentle return    — 2 days since last capture
//  - Shiny alert      — when a new shiny is identified
//  - Morning inspire  — optional 9am daily prompt
//

import Foundation
import UserNotifications
import Observation

// MARK: - Notification Type

enum SquirrelNotificationType: String, CaseIterable {
    case dailyNudge      = "daily_nudge"
    case streakCelebrate = "streak_celebrate"
    case gentleReturn    = "gentle_return"
    case shinyAlert      = "shiny_alert"
    case morningInspire  = "morning_inspire"

    var settingsKey: String { "reminder.\(rawValue).enabled" }

    var defaultEnabled: Bool {
        switch self {
        case .dailyNudge:      return true
        case .streakCelebrate: return true
        case .gentleReturn:    return true
        case .shinyAlert:      return true
        case .morningInspire:  return false
        }
    }

    var displayName: String {
        switch self {
        case .dailyNudge:      return "Daily Nudge"
        case .streakCelebrate: return "Streak Celebrations"
        case .gentleReturn:    return "Gentle Check-in"
        case .shinyAlert:      return "Shiny Alerts"
        case .morningInspire:  return "Morning Inspiration"
        }
    }

    var displayIcon: String {
        switch self {
        case .dailyNudge:      return "bell.fill"
        case .streakCelebrate: return "flame.fill"
        case .gentleReturn:    return "heart.fill"
        case .shinyAlert:      return "sparkles"
        case .morningInspire:  return "sunrise.fill"
        }
    }
}

// MARK: - Notification Content Tables

/// Per-type, per-persona notification copy.
/// Returns (title, body) tuples. Caller picks randomly.
private enum ReminderCopy {

    static func lines(
        type: SquirrelNotificationType,
        persona: SquirrelPersona
    ) -> [(title: String, body: String)] {
        switch type {
        case .dailyNudge:      return dailyNudge(persona: persona)
        case .streakCelebrate: return streakCelebrate(persona: persona)
        case .gentleReturn:    return gentleReturn(persona: persona)
        case .shinyAlert:      return shinyAlert(persona: persona)
        case .morningInspire:  return morningInspire(persona: persona)
        }
    }

    // MARK: Daily Nudge

    private static func dailyNudge(persona: SquirrelPersona) -> [(String, String)] {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                ("What's on your mind?", "I'm here whenever you're ready to share. 🐿️"),
                ("Hey, thinking of you", "Whatever's been swirling around today — I'd love to hear it."),
                ("Your thoughts matter", "Even the small, half-formed ones. Especially those."),
                ("Just checking in", "No pressure. But I'm here if something wants to come out."),
            ]
        case SquirrelPersona.brainstormPartner.id:
            return [
                ("Your brain is doing something interesting", "I can feel it from here. Come tell me 🌰"),
                ("What if—", "I've been waiting all day to brainstorm with you. What's brewing?"),
                ("Idea detected 📡", "Something is definitely rattling around up there. Let's dig in."),
                ("Time to stash something good", "Your best ideas don't announce themselves. Catch one now."),
            ]
        case SquirrelPersona.socraticQuestioner.id:
            return [
                ("What's the real question?", "Underneath whatever you're thinking about today."),
                ("Assumption check", "You've been carrying a thought around. What is it, actually?"),
                ("Something unexamined?", "The best captures happen when you least expect them."),
                ("What are you avoiding thinking about?", "That one. Let's look at it."),
            ]
        case SquirrelPersona.journalGuide.id:
            return [
                ("How are you, really?", "Take a breath. What's actually going on today?"),
                ("A moment for you", "What are you carrying right now that hasn't been put down yet?"),
                ("Check in with yourself", "What does your body know that your mind hasn't caught up to?"),
                ("Soft landing", "Whenever you're ready to set something down, I'm here."),
            ]
        case SquirrelPersona.devilsAdvocate.id:
            return [
                ("What are you not questioning?", "The assumption you're taking for granted today."),
                ("Challenge accepted?", "Pick one thing you believe right now and poke at it."),
                ("Stress test incoming", "What's the weakest part of your current thinking?"),
                ("The flaw finder", "What's the thing you're most sure about? That's where we start."),
            ]
        default:
            return [
                ("Time to capture", "What's been on your mind today?"),
                ("Your thoughts are waiting", "Don't let a good idea slip away."),
            ]
        }
    }

    // MARK: Streak Celebrate

    private static func streakCelebrate(persona: SquirrelPersona) -> [(String, String)] {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                ("You showed up again 🌟", "That consistency is real. I see it, and I'm so proud of you."),
                ("Every day, you came back", "That's not easy. That's discipline, and it's beautiful."),
                ("Look at what you built", "One thought at a time. You did this."),
            ]
        case SquirrelPersona.brainstormPartner.id:
            return [
                ("STREAK MILESTONE!! 🎉", "You absolute legend. Your brain has been showing UP. Let's celebrate!"),
                ("THIS IS THE GOOD STUFF", "Day after day. Your future self is already thanking you. 🌰🌰🌰"),
                ("Achievement unlocked 🏆", "Do you know how rare this is?? You're the real deal."),
            ]
        case SquirrelPersona.socraticQuestioner.id:
            return [
                ("Milestone reached", "The streak is data. What does it tell you about what you actually value?"),
                ("Consistency confirmed", "You've proven you can do this. Now what?"),
                ("The pattern holds", "Seven days is a sample size. What conclusions are you drawing?"),
            ]
        case SquirrelPersona.journalGuide.id:
            return [
                ("Something to notice", "You kept showing up. How does that feel, sitting with it quietly?"),
                ("A quiet milestone", "This is worth acknowledging. You chose yourself, day after day."),
                ("Take a moment", "Before the next thought — sit with what this streak means to you."),
            ]
        case SquirrelPersona.devilsAdvocate.id:
            return [
                ("The streak is real", "Now stress-test it: what would break it? Guard that."),
                ("Good. Keep going.", "A milestone is a checkpoint, not a destination. What's next?"),
                ("Numbers don't lie", "You've put in the work. The question is: what does it add up to?"),
            ]
        default:
            return [
                ("Streak milestone! 🔥", "You've been on a roll. Keep it going!"),
            ]
        }
    }

    // MARK: Gentle Return

    private static func gentleReturn(persona: SquirrelPersona) -> [(String, String)] {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                ("Hey. Just checking in.", "No pressure at all. But I've been thinking about you. 🐿️"),
                ("I've been saving your spot", "Whenever you're ready. I'm not going anywhere."),
                ("The door's always open", "Something's probably been building up. I'd love to hear it."),
                ("Miss your thoughts", "Genuinely. Come back whenever feels right."),
            ]
        case SquirrelPersona.brainstormPartner.id:
            return [
                ("Where'd you go?? 👀", "Ideas are piling up unexamined out there. Come back!"),
                ("The brainstorm misses you", "I have 12 follow-up questions from your last thought. Half-joking."),
                ("SOS from your idea vault", "Things are getting backed up in there. Need a release valve."),
            ]
        case SquirrelPersona.socraticQuestioner.id:
            return [
                ("The gap is data", "What's been happening that wasn't worth capturing?"),
                ("Absence noted", "What did the time away from this clarify, if anything?"),
                ("You paused. Intentionally?", "What went unexamined while you were away?"),
            ]
        case SquirrelPersona.journalGuide.id:
            return [
                ("Whenever you're ready", "I've been holding space. No rush, no judgment."),
                ("Something might be waiting", "To be put into words. Only if it wants to be."),
                ("A gentle knock", "How are things? Really. You don't have to say."),
            ]
        case SquirrelPersona.devilsAdvocate.id:
            return [
                ("The streak broke", "That's fine. Why? Worth examining."),
                ("Gap in the record", "What went unquestioned while you were away?"),
                ("You stopped. What stopped you?", "That's the actual question worth capturing."),
            ]
        default:
            return [
                ("Come back!", "It's been a couple days. What's on your mind?"),
            ]
        }
    }

    // MARK: Shiny Alert

    private static func shinyAlert(persona: SquirrelPersona) -> [(String, String)] {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                ("Something surfaced ✨", "I found a thought you should revisit. I think you'll want to see it."),
                ("A thought shined through", "One of your captures has been glowing. Come take a look."),
            ]
        case SquirrelPersona.brainstormPartner.id:
            return [
                ("I FOUND SOMETHING 👀✨", "Come look at what I dug up. This one is special."),
                ("SHINY DETECTED 🌟", "Your vault has a gem in it. GET IN HERE."),
                ("Drop everything", "Something you captured just got promoted to shiny status. You need to see this."),
            ]
        case SquirrelPersona.socraticQuestioner.id:
            return [
                ("A thought earned special status", "What made this one rise above the others?"),
                ("Signal in the noise", "One thought kept surfacing. Worth asking why."),
            ]
        case SquirrelPersona.journalGuide.id:
            return [
                ("Something wants your attention ✨", "A thought has been glowing quietly. When you're ready."),
                ("A shiny surfaced", "I think something you captured has more to offer. No rush to look."),
            ]
        case SquirrelPersona.devilsAdvocate.id:
            return [
                ("A thought earned shiny status", "Now interrogate it: is it actually that good, or just familiar?"),
                ("High signal detected", "One of your captures ranked highly. What does it actually mean?"),
            ]
        default:
            return [
                ("New shiny found! ✨", "One of your thoughts has been promoted to shiny status."),
            ]
        }
    }

    // MARK: Morning Inspiration

    private static func morningInspire(persona: SquirrelPersona) -> [(String, String)] {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                ("Good morning 🌅", "What are you carrying into today? I'm here to listen."),
                ("Morning", "What does today feel like so far? Even one word is enough."),
                ("Start here", "Before the day takes over — what's on your mind right now?"),
            ]
        case SquirrelPersona.brainstormPartner.id:
            return [
                ("Morning! What's the first idea?", "Your brain does something weird in the first 10 minutes. Catch it."),
                ("Good morning ☀️", "What's the first weird thing your brain did today?"),
                ("Day 1 of your next big thing", "What are you thinking about before you've fully woken up?"),
            ]
        case SquirrelPersona.socraticQuestioner.id:
            return [
                ("Morning question", "What assumption are you bringing into today?"),
                ("Before the day begins", "What question do you actually want answered today?"),
                ("Morning", "What are you taking for granted right now?"),
            ]
        case SquirrelPersona.journalGuide.id:
            return [
                ("Morning 🌸", "What are you carrying into today?"),
                ("A quiet moment before the rush", "How does today feel in your body, right now?"),
                ("Soft start", "One word for how you're waking up today."),
            ]
        case SquirrelPersona.devilsAdvocate.id:
            return [
                ("Morning challenge", "What's the assumption you're starting the day with? Test it."),
                ("Fresh eyes", "What does today look like if your plan is wrong?"),
                ("Rise and question", "What are you most certain about right now? Start there."),
            ]
        default:
            return [
                ("Good morning ☀️", "What's the first thing on your mind today?"),
            ]
        }
    }
}

// MARK: - Squirrel Reminder Service

@Observable
@MainActor
final class SquirrelReminderService {

    static let shared = SquirrelReminderService()

    // MARK: - Settings

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "reminder.enabled") as? Bool ?? false }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminder.enabled")
            if newValue {
                rescheduleAll()
            } else {
                cancelAll()
            }
        }
    }

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func isEnabled(_ type: SquirrelNotificationType) -> Bool {
        let key = type.settingsKey
        if UserDefaults.standard.object(forKey: key) == nil {
            return type.defaultEnabled
        }
        return UserDefaults.standard.bool(forKey: key)
    }

    func setEnabled(_ type: SquirrelNotificationType, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: type.settingsKey)
        rescheduleAll()
    }

    // MARK: - Permission

    /// Requests notification permission. Call contextually (e.g., from Settings toggle).
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            if granted {
                UserDefaults.standard.set(true, forKey: "reminder.enabled")
                rescheduleAll()
            }
            return granted
        } catch {
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Schedule

    /// Schedules all enabled notification types based on current settings.
    func rescheduleAll() {
        guard notificationsEnabled, authorizationStatus == .authorized else { return }

        let center = UNUserNotificationCenter.current()
        let persona = PersonaService.shared.defaultPersona

        // Cancel existing STASH notifications before rescheduling
        center.removePendingNotificationRequests(withIdentifiers:
            SquirrelNotificationType.allCases.map { $0.rawValue }
        )

        if isEnabled(.dailyNudge) {
            scheduleDailyNudge(persona: persona, center: center)
        }
        if isEnabled(.streakCelebrate) {
            scheduleStreakCelebration(persona: persona, center: center)
        }
        if isEnabled(.gentleReturn) {
            scheduleGentleReturn(persona: persona, center: center)
        }
        if isEnabled(.morningInspire) {
            scheduleMorningInspiration(persona: persona, center: center)
        }
        // Shiny alert is triggered imperatively via scheduleShinyAlert(), not time-based
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: SquirrelNotificationType.allCases.map { $0.rawValue }
        )
    }

    // MARK: - Daily Nudge

    private func scheduleDailyNudge(persona: SquirrelPersona, center: UNUserNotificationCenter) {
        let hour = peakCaptureHour()
        let (title, body) = randomLine(type: .dailyNudge, persona: persona)

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = makeContent(title: title, body: body, type: .dailyNudge)
        let request = UNNotificationRequest(
            identifier: SquirrelNotificationType.dailyNudge.rawValue,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Streak Celebration

    private func scheduleStreakCelebration(persona: SquirrelPersona, center: UNUserNotificationCenter) {
        let streak = StreakTracker.shared
        guard streak.currentStreak > 0 else { return }

        let (title, body) = randomLine(type: .streakCelebrate, persona: persona)

        // Schedule for 9am tomorrow
        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let content = makeContent(title: title, body: body, type: .streakCelebrate)
        let request = UNNotificationRequest(
            identifier: SquirrelNotificationType.streakCelebrate.rawValue,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Gentle Return

    private func scheduleGentleReturn(persona: SquirrelPersona, center: UNUserNotificationCenter) {
        let (title, body) = randomLine(type: .gentleReturn, persona: persona)

        // Fire once, 48 hours from now, if the user hasn't captured
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 3600, repeats: false)
        let content = makeContent(title: title, body: body, type: .gentleReturn)
        let request = UNNotificationRequest(
            identifier: SquirrelNotificationType.gentleReturn.rawValue,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Morning Inspiration

    private func scheduleMorningInspiration(persona: SquirrelPersona, center: UNUserNotificationCenter) {
        let (title, body) = randomLine(type: .morningInspire, persona: persona)

        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = makeContent(title: title, body: body, type: .morningInspire)
        let request = UNNotificationRequest(
            identifier: SquirrelNotificationType.morningInspire.rawValue,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Shiny Alert (Imperative)

    /// Call when a new shiny is promoted. Only fires if enabled + authorized.
    func scheduleShinyAlert() {
        guard notificationsEnabled,
              authorizationStatus == .authorized,
              isEnabled(.shinyAlert) else { return }

        let persona = PersonaService.shared.defaultPersona
        let (title, body) = randomLine(type: .shinyAlert, persona: persona)

        // Deliver 5 seconds from now (gives app time to save + return to background)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let content = makeContent(title: title, body: body, type: .shinyAlert)
        let request = UNNotificationRequest(
            identifier: SquirrelNotificationType.shinyAlert.rawValue,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Capture Hook (cancels gentle return when user captures)

    /// Call after each successful capture to reset the gentle-return timer.
    func onCaptureCompleted() {
        guard notificationsEnabled else { return }
        // Cancel any pending gentle-return
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [SquirrelNotificationType.gentleReturn.rawValue]
        )
        // Reschedule a fresh 48-hour timer
        if isEnabled(.gentleReturn) {
            let persona = PersonaService.shared.defaultPersona
            scheduleGentleReturn(persona: persona, center: UNUserNotificationCenter.current())
        }
    }

    // MARK: - Peak Hour Analysis

    /// Analyses the last 14 days of capture timestamps to find the most common capture hour.
    /// Falls back to 10am if insufficient data.
    private func peakCaptureHour() -> Int {
        guard let rawData = UserDefaults.standard.array(forKey: "capture.timestamps") as? [Double],
              !rawData.isEmpty else {
            return 10
        }

        let cal = Calendar.current
        let cutoff = Date().addingTimeInterval(-14 * 24 * 3600)
        let recent = rawData
            .map { Date(timeIntervalSince1970: $0) }
            .filter { $0 > cutoff }

        guard recent.count >= 3 else { return 10 }

        // Tally captures per hour
        var hourCounts = [Int: Int]()
        for date in recent {
            let hour = cal.component(.hour, from: date)
            hourCounts[hour, default: 0] += 1
        }
        return hourCounts.max(by: { $0.value < $1.value })?.key ?? 10
    }

    // MARK: - Helpers

    private func randomLine(type: SquirrelNotificationType, persona: SquirrelPersona) -> (String, String) {
        let lines = ReminderCopy.lines(type: type, persona: persona)
        return lines.randomElement() ?? ("STASH", "Time to capture a thought.")
    }

    private func makeContent(title: String, body: String, type: SquirrelNotificationType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // Deep link: stash://capture
        content.userInfo = ["deeplink": "stash://capture", "notificationType": type.rawValue]
        return content
    }
}
