//
//  Subscription.swift
//  STASH
//
//  Subscription models and entitlements for StoreKit 2
//

import Foundation

// MARK: - Subscription Tier

/// Available subscription tiers
enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free = "free"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free: return "$0"
        case .pro: return "$4.99"
        }
    }
}

// MARK: - Product Identifiers

/// StoreKit product identifiers
enum SubscriptionProduct: String, CaseIterable {
    case proMonthly = "com.withershins.stash.pro.monthly"
    case proAnnual = "com.withershins.stash.pro.annual"

    var tier: SubscriptionTier {
        switch self {
        case .proMonthly, .proAnnual:
            return .pro
        }
    }

    var displayName: String {
        switch self {
        case .proMonthly: return "Pro Monthly"
        case .proAnnual: return "Pro Annual"
        }
    }
}

// MARK: - Entitlements

/// Monthly thought limit for the free tier.
/// Warning shown at (freeMonthlyThoughtLimit - 5) captures.
/// Adjust here as needed while monitoring beta analytics.
let freeMonthlyThoughtLimit = 45
let freeMonthlyThoughtWarningThreshold = 40

/// Feature entitlements based on subscription tier
struct SubscriptionEntitlements: Codable, Sendable {
    let tier: SubscriptionTier
    let thoughtLimit: Int?  // nil = unlimited
    let hasAdvancedAnalytics: Bool
    let hasExport: Bool
    let hasAIInsights: Bool
    let hasStateOfMindTracking: Bool

    static let free = SubscriptionEntitlements(
        tier: .free,
        thoughtLimit: freeMonthlyThoughtLimit,
        hasAdvancedAnalytics: false,
        hasExport: false,
        hasAIInsights: true,  // Basic AI insights for everyone
        hasStateOfMindTracking: true  // State of Mind for everyone
    )

    static let pro = SubscriptionEntitlements(
        tier: .pro,
        thoughtLimit: nil,  // Unlimited
        hasAdvancedAnalytics: true,
        hasExport: true,
        hasAIInsights: true,
        hasStateOfMindTracking: true
    )

    static func entitlements(for tier: SubscriptionTier) -> SubscriptionEntitlements {
        switch tier {
        case .free: return .free
        case .pro: return .pro
        }
    }
}

// MARK: - Subscription Status

/// Current subscription status
struct SubscriptionStatus: Codable, Sendable {
    let tier: SubscriptionTier
    let expirationDate: Date?
    let isActive: Bool
    let productId: String?

    static let free = SubscriptionStatus(
        tier: .free,
        expirationDate: nil,
        isActive: true,
        productId: nil
    )

    var entitlements: SubscriptionEntitlements {
        SubscriptionEntitlements.entitlements(for: tier)
    }
}

// MARK: - Usage Tracking

/// Tracks usage against subscription limits
struct SubscriptionUsage: Codable {
    let thoughtsThisMonth: Int
    let currentPeriodStart: Date
    let currentPeriodEnd: Date

    /// Calculate usage from a list of thoughts
    static func calculate(from thoughts: [Thought]) -> SubscriptionUsage {
        let calendar = Calendar.current
        let now = Date()

        // Get start of current month
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let periodStart = calendar.date(from: components) else {
            return SubscriptionUsage(
                thoughtsThisMonth: 0,
                currentPeriodStart: now,
                currentPeriodEnd: now
            )
        }

        // Calculate end of current month (start of next month minus 1 second)
        guard let nextMonthStart = calendar.date(byAdding: DateComponents(month: 1), to: periodStart) else {
            return SubscriptionUsage(
                thoughtsThisMonth: 0,
                currentPeriodStart: periodStart,
                currentPeriodEnd: now
            )
        }

        let periodEnd = calendar.date(byAdding: .second, value: -1, to: nextMonthStart) ?? now

        // Count thoughts in current month
        let thoughtsThisMonth = thoughts.filter { thought in
            thought.createdAt >= periodStart && thought.createdAt < nextMonthStart
        }.count

        return SubscriptionUsage(
            thoughtsThisMonth: thoughtsThisMonth,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
    }

    func isWithinLimit(for entitlements: SubscriptionEntitlements) -> Bool {
        guard let limit = entitlements.thoughtLimit else {
            return true  // Unlimited
        }
        return thoughtsThisMonth < limit
    }

    func remainingThoughts(for entitlements: SubscriptionEntitlements) -> Int? {
        guard let limit = entitlements.thoughtLimit else {
            return nil  // Unlimited
        }
        return max(0, limit - thoughtsThisMonth)
    }
}
