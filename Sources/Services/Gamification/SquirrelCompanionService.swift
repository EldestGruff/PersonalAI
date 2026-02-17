//
//  SquirrelCompanionService.swift
//  STASH
//
//  Gamification issue #44: Tamagotchi Layer
//
//  Tracks the squirrelsona's life stage, owned accessories, and adventure
//  mode. The squirrel NEVER dies, gets sick, or shows negative states.
//  It naps. It forages. It waits. It celebrates.
//

import Foundation
import Observation

// MARK: - Life Stage

enum SquirrelLifeStage: String, CaseIterable, Codable {
    case sprout    // 0–24 captures
    case curious   // 25–99
    case seasoned  // 100–499
    case elder     // 500–999
    case legendary // 1 000+

    static func from(captureCount: Int) -> SquirrelLifeStage {
        switch captureCount {
        case 0..<25:   return .sprout
        case 25..<100: return .curious
        case 100..<500: return .seasoned
        case 500..<1000: return .elder
        default:       return .legendary
        }
    }

    var displayName: String {
        switch self {
        case .sprout:    return "Sprout"
        case .curious:   return "Curious"
        case .seasoned:  return "Seasoned"
        case .elder:     return "Elder"
        case .legendary: return "Legendary"
        }
    }

    var description: String {
        switch self {
        case .sprout:    return "Just getting started — tiny, wide-eyed, full of wonder."
        case .curious:   return "Finding a rhythm — alert, energetic, collecting ideas."
        case .seasoned:  return "A seasoned forager — carries a little acorn pouch everywhere."
        case .elder:     return "Distinguished and wise — has seen some things."
        case .legendary: return "A living legend — glowing with the light of a thousand captured thoughts."
        }
    }

    /// Asset catalog image name for this stage
    var imageName: String {
        switch self {
        case .sprout:    return "squirrel-sprout"
        case .curious:   return "squirrel-curious"
        case .seasoned:  return "squirrel-seasoned"
        case .elder:     return "squirrel-elder"
        case .legendary: return "squirrel-legendary"
        }
    }

    /// Base emoji representation. Accessories layer on top.
    var baseEmoji: String {
        switch self {
        case .sprout:    return "🌱"
        case .curious:   return "🐿️"
        case .seasoned:  return "🐿️"
        case .elder:     return "🐿️"
        case .legendary: return "🐿️"
        }
    }

    /// Decorative overlay shown for the stage itself (not accessories)
    var stageOverlay: String {
        switch self {
        case .sprout:    return ""
        case .curious:   return ""
        case .seasoned:  return "🎒"
        case .elder:     return "🧣"
        case .legendary: return "✨"
        }
    }

    /// Next stage milestone, nil if already legendary
    var nextMilestone: Int? {
        switch self {
        case .sprout:    return 25
        case .curious:   return 100
        case .seasoned:  return 500
        case .elder:     return 1000
        case .legendary: return nil
        }
    }
}

// MARK: - Accessory

struct SquirrelAccessory: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let cost: Int
    /// nil = available to purchase; non-nil = unlocked via milestone condition
    let unlockCondition: String?

    var isForSale: Bool { unlockCondition == nil }
}

extension SquirrelAccessory {
    static let catalog: [SquirrelAccessory] = [
        // Purchasable with acorns
        SquirrelAccessory(id: "santa_hat",     name: "Santa Hat",      emoji: "🎅", cost: 50,  unlockCondition: nil),
        SquirrelAccessory(id: "flower_crown",  name: "Flower Crown",   emoji: "🌸", cost: 50,  unlockCondition: nil),
        SquirrelAccessory(id: "sunglasses",    name: "Sunglasses",     emoji: "🕶️", cost: 75,  unlockCondition: nil),
        SquirrelAccessory(id: "tiny_backpack", name: "Tiny Backpack",  emoji: "🎒", cost: 100, unlockCondition: nil),
        SquirrelAccessory(id: "spectacles",    name: "Spectacles",     emoji: "🤓", cost: 100, unlockCondition: nil),
        SquirrelAccessory(id: "explorer_hat",  name: "Explorer Hat",   emoji: "🪖", cost: 150, unlockCondition: nil),
        SquirrelAccessory(id: "party_hat",     name: "Party Hat",      emoji: "🎉", cost: 75,  unlockCondition: nil),
        SquirrelAccessory(id: "scarf",         name: "Cozy Scarf",     emoji: "🧣", cost: 80,  unlockCondition: nil),
        // Milestone-unlocked (free once condition met)
        SquirrelAccessory(id: "golden_necklace", name: "Golden Acorn Necklace", emoji: "🏅",
                          cost: 0, unlockCondition: "Earn 500 lifetime acorns"),
        SquirrelAccessory(id: "detective_coat",  name: "Detective Coat",        emoji: "🕵️",
                          cost: 0, unlockCondition: "Find 10 shiny thoughts"),
    ]

    static func find(_ id: String) -> SquirrelAccessory? {
        catalog.first { $0.id == id }
    }
}

// MARK: - Adventure Recap Tables

/// Per-persona voice lines for returning from adventure mode (3+ day gap).
private enum AdventureRecap {
    static func line(for persona: SquirrelPersona, daysMissed: Int) -> String {
        let lines = recapLines(for: persona)
        // Prefer "long trip" lines for 7+ days
        let pool = daysMissed >= 7
            ? (lines.longTrip.isEmpty ? lines.short : lines.longTrip)
            : lines.short
        return pool.randomElement() ?? "I went on quite the adventure while you were away."
    }

    private struct RecapSet {
        let short: [String]       // 3–6 days
        let longTrip: [String]    // 7+ days
    }

    private static func recapLines(for persona: SquirrelPersona) -> RecapSet {
        switch persona.id {
        case SquirrelPersona.supportiveListener.id:
            return RecapSet(
                short: [
                    "I was just resting. Saving energy for when you came back.",
                    "I thought about you while you were gone. I'm glad you're here.",
                    "I kept your spot warm. I always do.",
                    "Life gets full sometimes. I get it. I'm here now.",
                ],
                longTrip: [
                    "I was starting to wonder, but I never doubted you'd come back.",
                    "A lot can happen in a week. I'd love to hear about it.",
                    "You were living your life. That's the whole point, isn't it?",
                ]
            )
        case SquirrelPersona.brainstormPartner.id:
            return RecapSet(
                short: [
                    "I discovered THREE whole meadows while you were gone. Ideas everywhere.",
                    "The waiting was actually productive — I have theories now.",
                    "I was brainstorming without you and honestly the ideas got a little weird.",
                    "YOUR TIMING. I was JUST about to send a search party.",
                ],
                longTrip: [
                    "Okay I have an ENTIRE BACKLOG of ideas from this foraging trip. Where do we start.",
                    "I foraged so many idea-forests while you were gone. The acorns were INCREDIBLE.",
                    "A week?? I have enough material to fuel us for a month. Buckle up.",
                ]
            )
        case SquirrelPersona.socraticQuestioner.id:
            return RecapSet(
                short: [
                    "Interesting. What finally brought you back?",
                    "The gap has data in it. What happened?",
                    "I used the time to examine my own assumptions. What did you examine?",
                    "You paused. Intentional or circumstantial?",
                ],
                longTrip: [
                    "A week away. What question did you come back with?",
                    "Something pulled you back today specifically. What was it?",
                    "Absence is a form of data. What does yours tell you?",
                ]
            )
        case SquirrelPersona.journalGuide.id:
            return RecapSet(
                short: [
                    "I held space for you. Still am.",
                    "No rush. You're back, and that's what matters.",
                    "The quiet had its own texture. Did you feel it too?",
                    "You went somewhere for a few days. What moved through you?",
                ],
                longTrip: [
                    "A week is a long conversation with yourself. What did you find?",
                    "I've been sitting quietly. Waiting, but not anxiously. Just... present.",
                    "Some gaps mean something. Some are just life. Either is okay.",
                ]
            )
        case SquirrelPersona.devilsAdvocate.id:
            return RecapSet(
                short: [
                    "You're back. What broke the pattern?",
                    "Three days away. What went unquestioned?",
                    "I'd challenge you on the gap but honestly — life interrupts. Fair.",
                    "The streak broke. Now what?",
                ],
                longTrip: [
                    "A week. The question isn't why you left — it's what you're bringing back.",
                    "Long break. Is that a choice or a drift? Worth examining.",
                    "You returned. What's the argument for staying consistent now?",
                ]
            )
        default:
            return RecapSet(
                short: ["I went on quite the adventure while you were away."],
                longTrip: ["Quite the foraging trip! Glad you're back."]
            )
        }
    }
}

// MARK: - Squirrel Companion Service

@Observable
@MainActor
final class SquirrelCompanionService {
    static let shared = SquirrelCompanionService()

    // MARK: - Keys

    private enum Keys {
        static let lifetimeCaptures  = "companion.lifetimeCaptures"
        static let ownedAccessories  = "companion.ownedAccessories"
        static let equippedAccessory = "companion.equippedAccessory"
        static let adventureShown    = "companion.adventureReturnShown"
    }

    // MARK: - State

    private(set) var lifetimeCaptureCount: Int
    private(set) var ownedAccessoryIds: Set<String>
    /// One accessory shown on the avatar at a time (nil = none)
    var equippedAccessoryId: String? {
        didSet {
            UserDefaults.standard.set(equippedAccessoryId, forKey: Keys.equippedAccessory)
        }
    }

    // MARK: - Computed

    var currentLifeStage: SquirrelLifeStage {
        SquirrelLifeStage.from(captureCount: lifetimeCaptureCount)
    }

    var isOnAdventure: Bool {
        (StreakTracker.shared.daysSinceLastCapture ?? 0) >= 3
    }

    var daysSinceLastCapture: Int {
        StreakTracker.shared.daysSinceLastCapture ?? 0
    }

    var equippedAccessory: SquirrelAccessory? {
        equippedAccessoryId.flatMap { SquirrelAccessory.find($0) }
    }

    /// Milestone unlocks that are now available based on current progress
    var unlockedMilestoneAccessories: [SquirrelAccessory] {
        let ledger = AcornLedger.shared
        let shinyCount = UserDefaults.standard.integer(forKey: "companion.shinyCount")
        return SquirrelAccessory.catalog.filter { accessory in
            guard !accessory.isForSale else { return false }
            switch accessory.id {
            case "golden_necklace": return ledger.lifetimeEarned >= 500
            case "detective_coat":  return shinyCount >= 10
            default:                return false
            }
        }
    }

    // MARK: - Init

    private init() {
        lifetimeCaptureCount = UserDefaults.standard.integer(forKey: Keys.lifetimeCaptures)
        let saved = UserDefaults.standard.stringArray(forKey: Keys.ownedAccessories) ?? []
        ownedAccessoryIds = Set(saved)
        equippedAccessoryId = UserDefaults.standard.string(forKey: Keys.equippedAccessory)
    }

    // MARK: - Capture Hook

    /// Call after every successful capture.
    func recordCapture() {
        lifetimeCaptureCount += 1
        UserDefaults.standard.set(lifetimeCaptureCount, forKey: Keys.lifetimeCaptures)
        // Clear "adventure shown" flag so next return triggers recap
        UserDefaults.standard.set(false, forKey: Keys.adventureShown)
    }

    // MARK: - Adventure Recap

    /// Returns an adventure recap line if the user is returning from 3+ days away
    /// and the recap hasn't been shown yet this return.
    func adventureRecapIfNeeded(for persona: SquirrelPersona) -> String? {
        guard isOnAdventure else { return nil }
        let alreadyShown = UserDefaults.standard.bool(forKey: Keys.adventureShown)
        guard !alreadyShown else { return nil }
        UserDefaults.standard.set(true, forKey: Keys.adventureShown)
        return AdventureRecap.line(for: persona, daysMissed: daysSinceLastCapture)
    }

    // MARK: - Accessories

    func isOwned(_ accessory: SquirrelAccessory) -> Bool {
        ownedAccessoryIds.contains(accessory.id) ||
        unlockedMilestoneAccessories.contains { $0.id == accessory.id }
    }

    /// Purchase an accessory with acorns. Returns true if successful.
    func purchase(_ accessory: SquirrelAccessory) -> Bool {
        guard accessory.isForSale else { return false }
        guard !isOwned(accessory) else { return true }
        guard AcornLedger.shared.currentBalance >= accessory.cost else { return false }
        _ = AcornLedger.shared.spend(accessory.cost)
        ownedAccessoryIds.insert(accessory.id)
        UserDefaults.standard.set(Array(ownedAccessoryIds), forKey: Keys.ownedAccessories)
        return true
    }

    func equip(_ accessory: SquirrelAccessory) {
        guard isOwned(accessory) else { return }
        equippedAccessoryId = accessory.id
    }

    func unequip() {
        equippedAccessoryId = nil
    }

    /// Update shiny count (called from ShinyService after promotions)
    func updateShinyCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "companion.shinyCount")
    }
}
