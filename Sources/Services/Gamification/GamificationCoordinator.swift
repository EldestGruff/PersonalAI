//
//  GamificationCoordinator.swift
//  STASH
//
//  Coordinates post-capture gamification hooks for all capture paths.
//  Single source of truth — add new hooks here, not in individual ViewModels.
//

import Foundation

/// Coordinates all gamification side-effects that fire after a successful thought capture.
///
/// Extracts the duplicated gamification logic from CaptureViewModel and VoiceCaptureViewModel
/// into one place. Both capture paths call this after a thought is saved.
@MainActor
enum GamificationCoordinator {

    struct CaptureResult {
        let acornReward: AcornReward
        let earnedBadges: [BadgeDefinition]
        let variableReward: VRSTier?
    }

    /// Run all post-capture hooks and return UI feedback values.
    ///
    /// - Parameters:
    ///   - thought: The newly saved thought.
    ///   - hadContext: Whether location context was available (affects acorn award).
    ///   - thoughtService: Used by BadgeService to count thoughts.
    static func processCapture(
        thought: Thought,
        hadContext: Bool,
        thoughtService: ThoughtService
    ) async -> CaptureResult {
        // Acorn reward (must run before streak so the streak milestone bonus stacks on top)
        let acornReward = await AcornService.shared.processCapture(hadContext: hadContext)

        // Streak — milestone acorn bonus fires on top of capture reward
        let streakUpdate = StreakTracker.shared.recordCapture()
        if let milestone = streakUpdate.milestone {
            _ = await AcornService.shared.processStreakMilestone(days: milestone.rawValue)
            SquirrelStateEngine.shared.triggerCelebrating()
        }

        // Badge check
        let earnedBadges = await BadgeService.shared.checkAll(
            newThought: thought,
            thoughtService: thoughtService
        )

        // Variable reward roll
        let variableReward = await VariableRewardService.shared.roll()

        // Companion hooks
        SquirrelReminderService.shared.onCaptureCompleted()
        SquirrelCompanionService.shared.recordCapture()

        return CaptureResult(
            acornReward: acornReward,
            earnedBadges: earnedBadges,
            variableReward: variableReward
        )
    }
}
