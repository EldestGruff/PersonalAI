//
//  PaywallScreen.swift
//  PersonalAI
//
//  Subscription paywall with StoreKit 2 integration
//

import SwiftUI
import StoreKit

struct PaywallScreen: View {

    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    header

                    // Features
                    features

                    // Product selection
                    if subscriptionManager.isLoading {
                        ProgressView("Loading subscription options...")
                    } else {
                        productCards
                    }

                    // Purchase button
                    purchaseButton

                    // Footer
                    footer
                }
                .padding()
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Unlock Unlimited Thoughts")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Capture unlimited thoughts, export your data, and access advanced analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Thoughts",
                description: "Capture as many thoughts as you need"
            )

            FeatureRow(
                icon: "chart.xyaxis.line",
                title: "Advanced Analytics",
                description: "Deep insights into your patterns and productivity"
            )

            FeatureRow(
                icon: "square.and.arrow.up",
                title: "Export Your Data",
                description: "Download thoughts as JSON, CSV, or PDF"
            )

            FeatureRow(
                icon: "lock.shield",
                title: "100% Private",
                description: "All features work on-device with zero cloud costs"
            )

            FeatureRow(
                icon: "sparkles",
                title: "AI-Powered Insights",
                description: "Foundation Models analyzes your thought patterns"
            )

            FeatureRow(
                icon: "heart.text.square",
                title: "State of Mind Tracking",
                description: "Correlate HealthKit mood data with your thoughts"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Product Cards

    private var productCards: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id
                ) {
                    selectedProduct = product
                }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            if let product = selectedProduct {
                Button {
                    _Concurrency.Task {
                        do {
                            try await subscriptionManager.purchase(product)
                            dismiss()
                        } catch {
                            // Error shown in manager
                        }
                    }
                } label: {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Subscribe Now")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .disabled(subscriptionManager.isLoading)
            }

            Button("Restore Purchases") {
                _Concurrency.Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Text("Subscriptions auto-renew unless cancelled. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }

                Button("Terms of Service") {
                    // Open terms
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)

                    if isAnnual {
                        Text("Save 20%")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var isAnnual: Bool {
        product.id.contains("annual")
    }
}

// MARK: - Previews

#Preview {
    PaywallScreen()
}
