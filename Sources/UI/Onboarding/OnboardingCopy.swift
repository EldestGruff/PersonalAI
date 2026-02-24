//
//  OnboardingCopy.swift
//  STASH
//
//  Onboarding issue #46: Squirrel-Led First-Run Walkthrough
//  Persona-voiced dialogue strings for onboarding steps
//
//  Pattern follows ReminderCopy in SquirrelReminderService.swift
//

import Foundation

// MARK: - Onboarding Copy

/// Per-persona onboarding copy.
/// Returns persona-voiced strings for each step.
enum OnboardingCopy {

    // MARK: - Public API

    static func greeting(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "Hey there. I'm your companion in this space—here to listen, not to judge. Whatever's on your mind, I'm here for it."
        case SquirrelPersona.brainstormPartner.id:
            return "HELLO! I'm so pumped to meet you. We're going to catch SO many good ideas together. Ready?"
        case SquirrelPersona.socraticQuestioner.id:
            return "Welcome. I'm here to ask the questions you might be avoiding. Sound good?"
        case SquirrelPersona.journalGuide.id:
            return "Hi. I'm here to help you get out of your head and into what you're actually feeling. Take your time."
        case SquirrelPersona.devilsAdvocate.id:
            return "Hey. I'm here to poke holes in your thinking—respectfully. Let's make your ideas stronger."
        default:
            return "Welcome to STASH. I'm your AI companion, here to help you capture and explore your thoughts."
        }
    }

    static func capturePrompt(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "What's been on your mind? Anything at all. I'm listening."
        case SquirrelPersona.brainstormPartner.id:
            return "First thought! Doesn't have to be good. Just HAS to exist. Go."
        case SquirrelPersona.socraticQuestioner.id:
            return "Capture one thought. Make it something you're unsure about."
        case SquirrelPersona.journalGuide.id:
            return "What are you carrying right now? Put it into words."
        case SquirrelPersona.devilsAdvocate.id:
            return "Write something you're certain about. We'll stress-test it later."
        default:
            return "Capture your first thought. What's on your mind right now?"
        }
    }

    static func acornExplanation(for persona: SquirrelPersona) -> [String] {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return [
                "You just earned your first acorn! 🌰",
                "Every thought you capture adds to your stash.",
                "It's a gentle way to see your consistency over time."
            ]
        case SquirrelPersona.brainstormPartner.id:
            return [
                "ACORN ACQUIRED! 🌰",
                "You get acorns for every capture. Stack them up!",
                "Spend them in the Acorn Shop on accessories for your squirrel!"
            ]
        case SquirrelPersona.socraticQuestioner.id:
            return [
                "One acorn earned. 🌰",
                "Acorns track consistency. That's the metric that matters.",
                "Worth asking: what does this measurement change about your behavior?"
            ]
        case SquirrelPersona.journalGuide.id:
            return [
                "You earned an acorn. 🌰",
                "It's a small symbol of showing up for yourself.",
                "Not about collecting—just noticing."
            ]
        case SquirrelPersona.devilsAdvocate.id:
            return [
                "First acorn. 🌰",
                "Acorns measure captures, not quality. Keep that in mind.",
                "The question is: will you chase the number, or chase what matters?"
            ]
        default:
            return [
                "You earned your first acorn! 🌰",
                "Collect acorns by capturing thoughts and building streaks.",
                "Watch your stash grow over time."
            ]
        }
    }

    static func streakEncouragement(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "Your streak shows you've been showing up. That counts for something. One day at a time. 🔥"
        case SquirrelPersona.brainstormPartner.id:
            return "STREAK TRACKER! Capture daily to keep it alive. We're building momentum here! 🔥"
        case SquirrelPersona.socraticQuestioner.id:
            return "The streak is data. What does daily consistency reveal about what you actually value? 🔥"
        case SquirrelPersona.journalGuide.id:
            return "The streak is just a reminder to check in with yourself. Only if you want to. 🔥"
        case SquirrelPersona.devilsAdvocate.id:
            return "Streaks are useful until they're not. Don't let the number hijack the purpose. 🔥"
        default:
            return "Build streaks by capturing thoughts daily. Keep the flame alive! 🔥"
        }
    }

    static func permissionPitch(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "STASH can gather context from your location, calendar, and contacts to make your thoughts more meaningful. It's all optional, and it stays private."
        case SquirrelPersona.brainstormPartner.id:
            return "Want context superpowers? Let STASH see your location, calendar, and contacts. More context = better connections between ideas!"
        case SquirrelPersona.socraticQuestioner.id:
            return "Context permissions let STASH know where you were, who you were with, what you had scheduled. Worth asking: do you want that metadata attached?"
        case SquirrelPersona.journalGuide.id:
            return "If you'd like, STASH can gently note where you were, what you had planned, who was around. It's all local to your device."
        case SquirrelPersona.devilsAdvocate.id:
            return "Context permissions mean STASH tracks your location, calendar, contacts. More data, better insights—but also more surveillance. Your call."
        default:
            return "STASH can enrich your thoughts with context like location, calendar events, and contacts. All data stays private on your device."
        }
    }

    static func notificationPitch(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "I can send you gentle reminders when it feels like a good time to capture. Only if you want them."
        case SquirrelPersona.brainstormPartner.id:
            return "Let me ping you when it's idea-catching time! I'll learn your rhythm and nudge you at the right moments."
        case SquirrelPersona.socraticQuestioner.id:
            return "Notifications can remind you to capture daily. Question is: do you need external prompts, or will you do it anyway?"
        case SquirrelPersona.journalGuide.id:
            return "I can send soft reminders to check in with yourself. No pressure—just a gentle knock."
        case SquirrelPersona.devilsAdvocate.id:
            return "Notifications can help with consistency. Or they can become nagging you ignore. Decide which you think they'll be."
        default:
            return "Enable notifications to get persona-voiced reminders at the right time. Max one per day, based on your capture habits."
        }
    }

    static func futureTeaser(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "Soon I'll start surfacing your most meaningful thoughts—the ones with strong feelings, tasks, or real connections. The ones worth a second look. ✨"
        case SquirrelPersona.brainstormPartner.id:
            return "SHINY THOUGHTS ARE COMING! Soon the vault will automatically spot your best ideas—the ones with tasks, connections, or strong vibes. Can't wait! ✨"
        case SquirrelPersona.socraticQuestioner.id:
            return "Coming next: a scoring system for your captures—sentiment, actionability, connections, depth. Worth asking now what you think makes a thought worth revisiting. ✨"
        case SquirrelPersona.journalGuide.id:
            return "Soon, certain thoughts will glow a little brighter—the ones carrying real emotion, action, or connection. We'll find them together. ✨"
        case SquirrelPersona.devilsAdvocate.id:
            return "Not built yet. But coming: an algorithm that ranks what you've captured. Sentiment, tasks, connections, energy. We'll see if the machine knows what matters to you. ✨"
        default:
            return "Coming soon: shiny thoughts—your most meaningful captures will be automatically surfaced based on emotion, action, and connection. ✨"
        }
    }

    static func siriSetupIntro(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "You can reach me from anywhere — even without opening the app. Just tell Siri, and I'll catch it for you."
        case SquirrelPersona.brainstormPartner.id:
            return "Best ideas happen mid-run, mid-drive, mid-shower. Set this up so we never lose one."
        case SquirrelPersona.socraticQuestioner.id:
            return "What's the cost of a thought that slips away? Set this up so you can capture from anywhere."
        case SquirrelPersona.journalGuide.id:
            return "Sometimes a moment needs to be held right as it happens. This lets you do that hands-free."
        case SquirrelPersona.devilsAdvocate.id:
            return "You're going to forget it. You always do. Unless you tell Siri right now."
        default:
            return "Capture thoughts anywhere — just tell Siri."
        }
    }

    static func completionMessage(for persona: SquirrelPersona) -> String {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return "You're all set. Whenever you're ready, I'm here. Let's build your stash together."
        case SquirrelPersona.brainstormPartner.id:
            return "WE'RE LIVE! Time to catch some ideas. Let's GOOOO! 🌰"
        case SquirrelPersona.socraticQuestioner.id:
            return "Setup complete. Now the real question: will you actually use this?"
        case SquirrelPersona.journalGuide.id:
            return "All set. Come back whenever you need to put something down. I'll be here."
        case SquirrelPersona.devilsAdvocate.id:
            return "Done. Now let's see if you actually stick with this. Prove me wrong."
        default:
            return "Welcome to STASH! Start capturing your thoughts and building your personal knowledge base."
        }
    }
}
