//
//  SubscriptionManager.swift
//  PersonalAI
//
//  StoreKit 2 subscription management
//

import Foundation
import StoreKit

// MARK: - Subscription Manager

/// Manages in-app purchases and subscription status using StoreKit 2
@MainActor
@Observable
class SubscriptionManager {

    // MARK: - Properties

    /// Current subscription status
    private(set) var status: SubscriptionStatus = .free

    /// Available products from App Store
    private(set) var products: [Product] = []

    /// Loading state
    private(set) var isLoading = false

    /// Purchase error
    private(set) var purchaseError: Error?

    /// Transaction listener task
    private var transactionListener: _Concurrency.Task<Void, Error>?

    // MARK: - Shared Instance

    static let shared = SubscriptionManager()

    // MARK: - Initialization

    private init() {
        // Load products and status
        _Concurrency.Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }

        // Start listening for transactions
        transactionListener = listenForTransactions()
    }

    // Note: deinit omitted - this is a singleton that lives for app lifetime

    // MARK: - Product Loading

    /// Load available subscription products from App Store
    func loadProducts() async {
        isLoading = true

        do {
            let productIds = SubscriptionProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIds)
            NSLog("✅ Loaded \(products.count) subscription products")
        } catch {
            NSLog("⚠️ Failed to load products: \(error)")
            purchaseError = error
        }

        isLoading = false
    }

    // MARK: - Purchase

    /// Purchase a subscription product
    func purchase(_ product: Product) async throws {
        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try Self.checkVerified(verification)

                // Update subscription status
                await updateSubscriptionStatus()

                // Finish the transaction
                await transaction.finish()

                NSLog("✅ Purchase successful: \(product.id)")

            case .userCancelled:
                NSLog("ℹ️ User cancelled purchase")

            case .pending:
                NSLog("⏳ Purchase pending approval")

            @unknown default:
                NSLog("⚠️ Unknown purchase result")
            }
        } catch {
            NSLog("⚠️ Purchase failed: \(error)")
            purchaseError = error
            throw error
        }

        isLoading = false
    }

    /// Restore purchases
    func restorePurchases() async {
        isLoading = true

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            NSLog("✅ Purchases restored")
        } catch {
            NSLog("⚠️ Failed to restore purchases: \(error)")
            purchaseError = error
        }

        isLoading = false
    }

    // MARK: - Subscription Status

    /// Update current subscription status
    func updateSubscriptionStatus() async {
        var currentStatus: SubscriptionStatus = .free

        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)

                // Check if this is a subscription product
                if let product = SubscriptionProduct(rawValue: transaction.productID) {
                    // User has an active subscription
                    currentStatus = SubscriptionStatus(
                        tier: product.tier,
                        expirationDate: transaction.expirationDate,
                        isActive: true,
                        productId: transaction.productID
                    )

                    // Only need one active subscription
                    break
                }
            } catch {
                NSLog("⚠️ Failed to verify transaction: \(error)")
            }
        }

        status = currentStatus
        NSLog("ℹ️ Subscription status: \(status.tier.displayName)")
    }

    // MARK: - Transaction Listening

    /// Listen for transaction updates
    private func listenForTransactions() -> _Concurrency.Task<Void, Error> {
        _Concurrency.Task { @MainActor [weak self] in
            guard let self = self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)

                    // Update subscription status
                    await self.updateSubscriptionStatus()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    NSLog("⚠️ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    /// Verify a transaction is legitimate
    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Entitlements

    /// Current entitlements based on subscription
    var entitlements: SubscriptionEntitlements {
        status.entitlements
    }

    /// Check if user can capture more thoughts this month
    func canCaptureThought(usage: SubscriptionUsage) -> Bool {
        usage.isWithinLimit(for: entitlements)
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
