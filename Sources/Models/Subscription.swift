//
//  Subscription.swift
//  PersonalAI
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
    case proMonthly = "com.personalai.pro.monthly"
    case proAnnual = "com.personalai.pro.annual"

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
        thoughtLimit: 50,  // 50 thoughts per month
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
