//
//  SubscriptionManager.swift
//  STASH
//
//  StoreKit 2 subscription management
//

import Foundation
import OSLog
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
            AppLogger.store.info("Loaded \(products.count) subscription products")
        } catch {
            AppLogger.store.warning("Failed to load products: \(error)")
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

                AppLogger.store.info("Purchase successful: \(product.id)")

            case .userCancelled:
                AppLogger.store.debug("User cancelled purchase")

            case .pending:
                AppLogger.store.debug("Purchase pending approval")

            @unknown default:
                AppLogger.store.warning("Unknown purchase result")
            }
        } catch {
            AppLogger.store.warning("Purchase failed: \(error)")
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
            AppLogger.store.info("Purchases restored")
        } catch {
            AppLogger.store.warning("Failed to restore purchases: \(error)")
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
                AppLogger.store.warning("Failed to verify transaction: \(error)")
            }
        }

        status = currentStatus
        AppLogger.store.debug("Subscription status: \(status.tier.displayName)")
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
                    AppLogger.store.warning("Transaction verification failed: \(error)")
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
