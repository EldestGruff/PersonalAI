//
//  VariableRewardService.swift
//  STASH
//
//  Gamification issue #42: Variable Reward Schedule
//
//  Variable ratio reinforcement — the same psychology slot machines exploit,
//  applied ethically: always positive, never punishing, never telegraphed.
//
//  One roll per app session. Four tiers. Pure random — no progress bar,
//  no "X captures until next reward." The surprise IS the reward.
//

import Foundation
import Observation

// MARK: - VRS Tier

enum VRSTier: String, CaseIterable {
    case common    = "common"
    case uncommon  = "uncommon"
    case rare      = "rare"
    case legendary = "legendary"

    // MARK: Rewards

    var acorns: Int {
        switch self {
        case .common:    return 3
        case .uncommon:  return 10
        case .rare:      return 25
        case .legendary: return 50
        }
    }

    // MARK: Display

    var title: String {
        switch self {
        case .common:    return "Bonus Acorns"
        case .uncommon:  return "Lucky Capture!"
        case .rare:      return "Rare Find"
        case .legendary: return "LEGENDARY"
        }
    }

    var emoji: String {
        switch self {
        case .common:    return "🌰"
        case .uncommon:  return "🎊"
        case .rare:      return "✨"
        case .legendary: return "🎉"
        }
    }

    /// Squirrelsona commentary — varies per tier
    var commentary: String {
        let lines: [String]
        switch self {
        case .common:
            lines = [
                "Found a little something extra.",
                "Your squirrel felt generous today.",
                "A bonus, just because.",
                "The acorn tree gave a little more.",
            ]
        case .uncommon:
            lines = [
                "Lucky capture! The universe approves.",
                "Something in the air today. Take it.",
                "The acorn tree is feeling generous.",
                "Not every capture does this. This one did.",
            ]
        case .rare:
            lines = [
                "This one had real magic in it.",
                "A rare gem in the stash. Cherished.",
                "Some thoughts are just worth more. This was one.",
                "The squirrel sat up straight for this one.",
            ]
        case .legendary:
            lines = [
                "LEGENDARY. The squirrel is losing its mind.",
                "This is the one they'll tell stories about.",
                "The rarest of captures. The cosmos noticed.",
                "Once in a very long while, something like this happens.",
            ]
        }
        return lines.randomElement() ?? lines[0]
    }

    /// How long to keep the screen up so the user can see the reward
    var dismissDelay: Int {
        switch self {
        case .common:    return 1200
        case .uncommon:  return 1600
        case .rare:      return 2200
        case .legendary: return 3200
        }
    }
}

// MARK: - Variable Reward Service

/// Rolls for a variable reward after each capture.
///
/// Fires at most once per app session to prevent gaming.
/// Rewards are always positive — no punishment for not triggering.
@Observable
@MainActor
final class VariableRewardService {
    static let shared = VariableRewardService()

    // MARK: - State

    /// Number of VRS events ever triggered (all tiers)
    private(set) var lifetimeCount: Int

    /// True once a reward has fired this session — blocks further rolls
    private var hasRewardedThisSession = false

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let lifetimeCount = "vrs.lifetimeCount"
    }

    // MARK: - Init

    private init() {
        lifetimeCount = UserDefaults.standard.integer(forKey: Keys.lifetimeCount)
    }

    // MARK: - Public API

    /// Rolls for a variable reward. Returns a tier if the roll wins, nil otherwise.
    ///
    /// Approximate frequencies (single roll 1–150):
    ///   - Legendary : 1/150  (~0.67%)   → roll == 1
    ///   - Rare      : 1/75   (~1.33%)   → roll 2–3
    ///   - Uncommon  : 1/30   (~3.33%)   → roll 4–8
    ///   - Common    : 1/15   (~6.67%)   → roll 9–18
    ///   - Nothing   : ~88%              → roll 19–150
    @discardableResult
    func roll() async -> VRSTier? {
        guard !hasRewardedThisSession else { return nil }

        let n = Int.random(in: 1...150)
        let tier: VRSTier?

        switch n {
        case 1:     tier = .legendary
        case 2...3: tier = .rare
        case 4...8: tier = .uncommon
        case 9...18: tier = .common
        default:    tier = nil
        }

        guard let tier else { return nil }

        hasRewardedThisSession = true
        lifetimeCount += 1
        UserDefaults.standard.set(lifetimeCount, forKey: Keys.lifetimeCount)

        // Award acorns via the existing economy layer
        _ = await AcornService.shared.processVariableReward(acorns: tier.acorns)

        return tier
    }
}
