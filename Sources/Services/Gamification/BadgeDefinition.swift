//
//  BadgeDefinition.swift
//  STASH
//
//  Gamification issue #41: Discovery Badges
//
//  Static catalog of all badges. Criteria are NEVER shown before earning —
//  the reveal IS the reward. Secret badges hide name, icon, and criteria
//  entirely until earned.
//

import Foundation

// MARK: - Badge Definition

struct BadgeDefinition: Identifiable, Equatable {
    /// Stable string ID used for persistence
    let id: String
    /// Shown after earning (and in gallery for non-secret badges)
    let name: String
    /// SF Symbol — shown silhouetted until earned; secret badges show "questionmark.circle" instead
    let symbol: String
    /// One-line description of how the badge was earned. Shown ONLY after earning.
    let criteriaDescription: String
    /// If true, name + symbol + description are hidden until earned
    let isSecret: Bool
    /// Acorns awarded the moment the badge is earned
    let acornBonus: Int

    // MARK: - Catalog

    static let catalog: [BadgeDefinition] = [

        // ── Time-based ────────────────────────────────────────────────
        BadgeDefinition(
            id: "night_owl",
            name: "Night Owl",
            symbol: "moon.stars.fill",
            criteriaDescription: "Captured a thought after midnight",
            isSecret: false,
            acornBonus: 5
        ),
        BadgeDefinition(
            id: "early_bird",
            name: "Early Bird",
            symbol: "sunrise.fill",
            criteriaDescription: "Captured a thought before 6am",
            isSecret: false,
            acornBonus: 5
        ),
        BadgeDefinition(
            id: "monday",
            name: "Monday Is Fine",
            symbol: "cup.and.saucer.fill",
            criteriaDescription: "Captured a thought on a Monday morning before 9am",
            isSecret: false,
            acornBonus: 5
        ),

        // ── Volume-based ──────────────────────────────────────────────
        BadgeDefinition(
            id: "deep_roots",
            name: "Deep Roots",
            symbol: "tree.fill",
            criteriaDescription: "Captured 100 thoughts",
            isSecret: false,
            acornBonus: 20
        ),
        BadgeDefinition(
            id: "hoarder",
            name: "Hoarder",
            symbol: "cabinet.fill",
            criteriaDescription: "Captured 500 thoughts",
            isSecret: false,
            acornBonus: 50
        ),

        // ── Writing quality ───────────────────────────────────────────
        BadgeDefinition(
            id: "novelist",
            name: "The Novelist",
            symbol: "book.fill",
            criteriaDescription: "Wrote 3 thoughts each longer than 200 words",
            isSecret: false,
            acornBonus: 10
        ),
        BadgeDefinition(
            id: "overthinker",
            name: "Overthinker",
            symbol: "arrow.triangle.2.circlepath",
            criteriaDescription: "Wrote a single thought with more than 500 characters",
            isSecret: false,
            acornBonus: 5
        ),

        // ── Speed / habit ─────────────────────────────────────────────
        BadgeDefinition(
            id: "fast_thinker",
            name: "Fast Thinker",
            symbol: "bolt.fill",
            criteriaDescription: "Captured 5 thoughts within a 10-minute window",
            isSecret: false,
            acornBonus: 10
        ),
        BadgeDefinition(
            id: "long_game",
            name: "The Long Game",
            symbol: "calendar.badge.checkmark",
            criteriaDescription: "Reached a 30-day capture streak",
            isSecret: false,
            acornBonus: 25
        ),

        // ── Connection / emotion ──────────────────────────────────────
        BadgeDefinition(
            id: "connected",
            name: "Connected",
            symbol: "point.3.filled.connected.trianglepath.dotted",
            criteriaDescription: "A thought connected to 5 or more other thoughts",
            isSecret: false,
            acornBonus: 10
        ),
        BadgeDefinition(
            id: "feelings",
            name: "Feelings",
            symbol: "heart.fill",
            criteriaDescription: "Captured 10 thoughts with strong emotional sentiment",
            isSecret: false,
            acornBonus: 10
        ),

        // ── Gamification milestones ───────────────────────────────────
        BadgeDefinition(
            id: "first_shiny",
            name: "First Shiny",
            symbol: "sparkle",
            criteriaDescription: "Had a thought promoted to shiny status",
            isSecret: false,
            acornBonus: 15
        ),
        BadgeDefinition(
            id: "acorn_millionaire",
            name: "Acorn Millionaire",
            symbol: "bag.fill",
            criteriaDescription: "Earned 1,000 lifetime acorns",
            isSecret: false,
            acornBonus: 100
        ),

        // ── Secret ────────────────────────────────────────────────────
        BadgeDefinition(
            id: "secret_squirrel",
            name: "Secret Squirrel",
            symbol: "figure.detective",
            criteriaDescription: "Some secrets are best kept.",
            isSecret: true,
            acornBonus: 25
        ),
    ]

    // MARK: - Lookup

    static func badge(id: String) -> BadgeDefinition? {
        catalog.first { $0.id == id }
    }
}
