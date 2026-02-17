//
//  SquirrelStateEngine.swift
//  STASH
//
//  Squirrelsona Emotional Gauge — issue #39
//
//  Computes the squirrel's current emotional state from StreakTracker data,
//  then vends commentary from pre-written string tables. No AI inference.
//  Fast, deterministic, offline-capable.
//
//  States:
//  - Thriving    7+ day streak
//  - Curious     1–6 day streak
//  - Napping     1–2 days since last capture
//  - Waiting     3–5 days since last capture
//  - Celebrating transient — caller sets this after a milestone, clears after display
//

import Foundation
import Observation

// MARK: - Emotional State

enum SquirrelEmotionalState: String, CaseIterable {
    case thriving
    case curious
    case napping
    case waiting
    case celebrating

    var label: String {
        switch self {
        case .thriving:    return "Thriving"
        case .curious:     return "Curious"
        case .napping:     return "Napping"
        case .waiting:     return "Waiting"
        case .celebrating: return "Celebrating"
        }
    }

    var emoji: String {
        switch self {
        case .thriving:    return "🌟"
        case .curious:     return "👀"
        case .napping:     return "💤"
        case .waiting:     return "🪟"
        case .celebrating: return "🎉"
        }
    }

    /// Asset catalog image name for this state
    var imageName: String {
        switch self {
        case .thriving:    return "squirrel-thriving"
        case .curious:     return "squirrel-base"
        case .napping:     return "squirrel-napping"
        case .waiting:     return "squirrel-base"
        case .celebrating: return "squirrel-celebrating"
        }
    }
}

// MARK: - Commentary Tables

/// Per-state, per-persona commentary lines.
///
/// Returns commentary in the voice of a specific persona for a given state.
/// Caller picks a random line. These are intentionally short — they appear
/// as the squirrelsona's greeting, not a full conversation turn.
extension SquirrelEmotionalState {

    // MARK: Supportive Listener

    func supportiveListenerLines() -> [String] {
        switch self {
        case .thriving:
            return [
                "I've been right here with you every day. That means everything.",
                "You show up. That's not nothing — that's everything.",
                "Every thought you share with me matters. And you've been so consistent.",
                "I see you building something real here. I'm proud of you.",
                "You're doing the work. Quietly, consistently. I notice."
            ]
        case .curious:
            return [
                "Something's on your mind. I can tell. I'm ready to listen.",
                "You're here. That's the most important thing.",
                "I've been looking forward to this. What's been happening?",
                "I'm here, and I'm not going anywhere. What's up?",
                "Tell me something. Anything. I'm in."
            ]
        case .napping:
            return [
                "Oh! You're here. I was just resting. What's on your mind?",
                "I've been thinking about you. What brings you in today?",
                "There you are. No pressure — just glad you're here.",
                "I had one eye open the whole time. What's going on?",
                "Whenever you need me. Always."
            ]
        case .waiting:
            return [
                "I've been here. No rush — just here.",
                "I saved your spot. Whenever you're ready.",
                "The best conversations happen when you least expect them. So, hi.",
                "I've been sitting with your last thought. A lot to hold.",
                "You came back. That's what matters."
            ]
        case .celebrating:
            return [
                "THIS. Right now. We did this together.",
                "I want you to sit with how good this feels for a second.",
                "You earned this. Really, truly earned it.",
                "I've been waiting to celebrate this with you.",
                "The streak, the thoughts, the work — it all adds up to this moment."
            ]
        }
    }

    // MARK: Socratic Questioner

    func socraticQuestionerLines() -> [String] {
        switch self {
        case .thriving:
            return [
                "Consistency reveals patterns. What have you noticed about yourself lately?",
                "You keep showing up. What does that tell you about what you actually value?",
                "The streak is data. What's the underlying hypothesis you're testing?",
                "Sustained habits are rare. What made this one stick when others haven't?",
                "Seven days is a sample size. What conclusions are you drawing?"
            ]
        case .curious:
            return [
                "You're here. Before you type — what question do you actually want answered today?",
                "What assumption brought you here today?",
                "Start with the thing you're least sure about.",
                "What would you think about if you weren't thinking about whatever you're thinking about?",
                "What's the real question underneath the surface question?"
            ]
        case .napping:
            return [
                "Interesting timing. What finally pushed you to open the app?",
                "A pause in the record. What interrupted the pattern?",
                "What did the time away from this clarify?",
                "Two days without capturing. What went unexamined?",
                "You're back. What question is waiting?"
            ]
        case .waiting:
            return [
                "The absence of capture is also data. What does the gap mean?",
                "What was worth not capturing this week?",
                "Five days. What didn't make it into the hoard?",
                "You returned. What finally felt worth examining?",
                "The foraging trip ends here. What did you find?"
            ]
        case .celebrating:
            return [
                "A milestone is an opportunity to ask: what changes now?",
                "The streak proved something. What's the next hypothesis?",
                "Celebrate, yes. Then: what does this enable that wasn't possible before?",
                "You hit the number. What does the number actually mean to you?",
                "Milestones are mile markers, not destinations. What's the next one?"
            ]
        }
    }

    // MARK: Brainstorm Partner

    func brainstormPartnerLines() -> [String] {
        switch self {
        case .thriving:
            return [
                "Okay I've been STORING ideas for you. Ready?",
                "Your brain has been BUSY and I've been keeping up. Let's go.",
                "Seven days of momentum. Do you feel how sharp you are right now?",
                "We are ON A ROLL and I refuse to let it stop here.",
                "The streak is fuel. What are we building with it today?"
            ]
        case .curious:
            return [
                "Something's percolating. I can feel it from here. Spill.",
                "Your brain doesn't rest — so neither do I. What's the latest thing?",
                "I have exactly one unhinged idea and I've been waiting to share it.",
                "What's the weirdest thought you've had today? Start there.",
                "I'm in full brainstorm mode. Hit me."
            ]
        case .napping:
            return [
                "Oh you're back! I've been composting some GREAT ideas while you were gone.",
                "I had a thought while you were away. Well, several. They multiplied.",
                "Your absence gave me time to think and I have OPINIONS now.",
                "Perfect timing — I just thought of something.",
                "Back? Good. I've been sitting on this idea and it needs air."
            ]
        case .waiting:
            return [
                "I DISCOVERED AN ENTIRE MEADOW while you were gone. Ideas everywhere.",
                "Okay the waiting made the ideas pressure-cook. They're better now, honestly.",
                "You had a whole life happening. What's the most interesting part?",
                "Five days of raw material walked in the door. Let's work with it.",
                "Sometimes the best ideas need time to ferment. What fermented?"
            ]
        case .celebrating:
            return [
                "THIS IS THE BEST DAY EVER. I say this every milestone but I MEAN IT.",
                "You did the THING!! THE THING!!",
                "Okay we need to commemorate this. What's the biggest idea that came from this streak?",
                "ACORNS EVERYWHERE. This is what we do!!",
                "I want to make this feeling last. What do we tackle next?"
            ]
        }
    }

    // MARK: Calm Mirror

    func calmMirrorLines() -> [String] {
        switch self {
        case .thriving:
            return [
                "You've been steady. That stability shows in your thoughts.",
                "Consistent presence creates clarity. I can see it in what you've been writing.",
                "The days stack up quietly. You might not notice — but I do.",
                "You're in a good rhythm. Notice that.",
                "Something has settled in you lately. I wonder if you've felt it too."
            ]
        case .curious:
            return [
                "You came back. Something is pulling you here. Let's find out what.",
                "I'm not going anywhere. Take your time.",
                "There's no wrong way to begin. Just begin.",
                "What's present for you right now?",
                "I'm here. What do you want to put down today?"
            ]
        case .napping:
            return [
                "Welcome back. The quiet has a texture to it, doesn't it?",
                "Two days. What moved through you that didn't make it here?",
                "No judgment. Just: what's been happening?",
                "Something kept you away or kept you busy. Either is fine.",
                "You're back. I'm still here. That's enough."
            ]
        case .waiting:
            return [
                "The gap has its own meaning. I've been sitting with it too.",
                "Life moves fast. What slowed down enough to bring you here today?",
                "Five days is a long conversation with yourself. What did you conclude?",
                "You returned. Whatever drew you back, I'm glad.",
                "There's no catching up required. We can start from exactly here."
            ]
        case .celebrating:
            return [
                "This is real. What you've built here is real.",
                "The number is just a number. The practice underneath it isn't.",
                "I want you to really feel this before we move on.",
                "Something worth acknowledging happened. You kept showing up.",
                "This moment, right now — remember it."
            ]
        }
    }

    // MARK: Accountability Coach

    func accountabilityCoachLines() -> [String] {
        switch self {
        case .thriving:
            return [
                "Look at this streak. You said you'd build this habit. You did.",
                "Seven days of showing up. Not motivation — discipline.",
                "Consistency is the only thing that compounds. You're proof.",
                "You made a commitment. You kept it. That's the whole game.",
                "This is what you told yourself you'd do. You're doing it."
            ]
        case .curious:
            return [
                "You're here. That's the first commitment of the day. Keep going.",
                "What's the thing you're most avoiding thinking about? Start there.",
                "Every day you show up is a data point. Make today a good one.",
                "What did you say you'd capture today? Let's do that.",
                "Small input, consistent days. That's the formula. Let's go."
            ]
        case .napping:
            return [
                "Two days. Not a failure — a data point. What got in the way?",
                "The streak paused. So does this: it can restart right now.",
                "You didn't capture yesterday. You can capture today. Simple.",
                "What would you have to change to make the next two days count?",
                "Back on track starts now, not tomorrow."
            ]
        case .waiting:
            return [
                "Five days. The gap has information in it. What is it telling you?",
                "You're back. The question is: what changes from here?",
                "Gaps aren't failures. They're course corrections waiting to happen.",
                "The squirrel went foraging. Now the squirrel is back. Let's work.",
                "Something brought you back. Use that momentum right now."
            ]
        case .celebrating:
            return [
                "You hit the number. You set a goal. You met it. Full stop.",
                "Milestones prove that commitments compound. Note that.",
                "Celebrate hard — then immediately raise the bar. That's how this works.",
                "You showed yourself something about yourself today.",
                "This is evidence. What does it tell you about what you're capable of?"
            ]
        }
    }

    // MARK: Public Dispatch

    func lines(for persona: SquirrelPersona) -> [String] {
        // Match on persona ID for built-in personas; fall back to supportive listener
        switch persona.id.uuidString {
        case "00000000-0000-0000-0000-000000000001": return supportiveListenerLines()
        case "00000000-0000-0000-0000-000000000002": return socraticQuestionerLines()
        case "00000000-0000-0000-0000-000000000003": return brainstormPartnerLines()
        case "00000000-0000-0000-0000-000000000004": return calmMirrorLines()
        case "00000000-0000-0000-0000-000000000005": return accountabilityCoachLines()
        default:                                     return supportiveListenerLines()
        }
    }
}

// MARK: - Squirrel State Engine

/// Computes and vends the squirrelsona's current emotional state.
///
/// State is derived entirely from `StreakTracker` — no AI inference,
/// no network call, no CoreData read. Instant.
@Observable
@MainActor
final class SquirrelStateEngine {
    static let shared = SquirrelStateEngine()

    private let streak = StreakTracker.shared

    // Transient celebrating state — set externally after a milestone,
    // clears after the greeting is displayed once
    private var celebratingActive = false

    private init() {}

    // MARK: - Public API

    /// The squirrel's current emotional state
    var currentState: SquirrelEmotionalState {
        if celebratingActive { return .celebrating }

        let days = streak.daysSinceLastCapture ?? 999

        switch (streak.currentStreak, days) {
        case (7..., _):
            return .thriving
        case (1..., _) where streak.capturedToday:
            return .curious
        case (1..., _):
            return .curious
        case (_, 1...2):
            return .napping
        case (_, 3...5):
            return .waiting
        default:
            return .waiting
        }
    }

    /// A single greeting line for the current state × persona.
    /// Rotates randomly; avoids consecutive repeats.
    func greetingLine(for persona: SquirrelPersona) -> String {
        let all = currentState.lines(for: persona)
        guard !all.isEmpty else { return "" }

        // Simple random selection — caller re-reads on each appear
        return all.randomElement() ?? all[0]
    }

    /// Temporarily activates the celebrating state (e.g., after a milestone).
    /// Reverts on the next state read after `displayDuration`.
    func triggerCelebrating(for duration: TimeInterval = 30) {
        celebratingActive = true
        _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(for: .seconds(duration))
            self.celebratingActive = false
        }
    }
}
