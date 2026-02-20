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
                "Future feature: spend them on shiny upgrades. For now? Hoard them."
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
            return "Soon, some of your thoughts will earn 'shiny' status—the ones that matter most. I'll help you spot them. ✨"
        case SquirrelPersona.brainstormPartner.id:
            return "Coming soon: SHINY THOUGHTS. The vault will surface your best ideas automatically. It's gonna be SO GOOD. ✨"
        case SquirrelPersona.socraticQuestioner.id:
            return "Future feature: shiny thoughts. The system will identify high-signal captures. Worth asking: what metric defines 'high-signal'? ✨"
        case SquirrelPersona.journalGuide.id:
            return "Eventually, certain thoughts will glow brighter—the ones that want more attention. We'll notice them together. ✨"
        case SquirrelPersona.devilsAdvocate.id:
            return "Shiny thoughts are coming: algorithmic ranking of your 'best' captures. Could be useful. Could be noise. We'll see. ✨"
        default:
            return "Coming soon: Shiny thoughts—your most important captures, automatically surfaced. ✨"
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
