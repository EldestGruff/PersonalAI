//
//  PaywallScreen.swift
//  STASH
//
//  Subscription paywall with StoreKit 2 integration
//

import SwiftUI
import StoreKit

struct PaywallScreen: View {

    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                // Theme background
                theme.backgroundColor
                    .ignoresSafeArea()

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
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.warningColor)

            Text("Unlock Unlimited Thoughts")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)

            Text("Capture unlimited thoughts, export your data, and access advanced analytics")
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var features: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 16) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Thoughts",
                description: "Capture as many thoughts as you need",
                theme: theme
            )

            FeatureRow(
                icon: "chart.xyaxis.line",
                title: "Advanced Analytics",
                description: "Deep insights into your patterns and productivity",
                theme: theme
            )

            FeatureRow(
                icon: "square.and.arrow.up",
                title: "Export Your Data",
                description: "Download thoughts as JSON, CSV, or PDF",
                theme: theme
            )

            FeatureRow(
                icon: "lock.shield",
                title: "100% Private",
                description: "All features work on-device with zero cloud costs",
                theme: theme
            )

            FeatureRow(
                icon: "sparkles",
                title: "AI-Powered Insights",
                description: "Foundation Models analyzes your thought patterns",
                theme: theme
            )

            FeatureRow(
                icon: "heart.text.square",
                title: "State of Mind Tracking",
                description: "Correlate HealthKit mood data with your thoughts",
                theme: theme
            )
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }

    // MARK: - Product Cards

    private var productCards: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 12) {
            ForEach(subscriptionManager.products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    theme: theme
                ) {
                    selectedProduct = product
                }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 12) {
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
                .background(theme.primaryColor)
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
            .foregroundColor(theme.secondaryTextColor)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 8) {
            Text("Subscriptions auto-renew unless cancelled. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
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
            .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let theme: any ThemeVariant

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(theme.primaryColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)

                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let theme: any ThemeVariant
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(theme.textColor)

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textColor)

                    if isAnnual {
                        Text("Save 20%")
                            .font(.caption2)
                            .foregroundStyle(theme.successColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.successColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? theme.primaryColor : theme.secondaryTextColor)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
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
