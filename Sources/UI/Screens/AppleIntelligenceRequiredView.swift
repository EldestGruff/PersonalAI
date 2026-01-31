//
//  AppleIntelligenceRequiredView.swift
//  PersonalAI
//
//  Screen shown when Apple Intelligence is not available
//  iOS 26+ requirement
//

import SwiftUI

struct AppleIntelligenceRequiredView: View {

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 60)

                // Icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundStyle(.teal)
                    .symbolRenderingMode(.hierarchical)

                // Title & Description
                VStack(spacing: 16) {
                    Text("Apple Intelligence Required")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("PersonalAI uses on-device AI to classify and organize your thoughts privately.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Requirements Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("System Requirements")
                        .font(.headline)
                        .padding(.bottom, 4)

                    RequirementRow(
                        icon: "iphone",
                        title: "Device",
                        description: "iPhone 17 Pro or later\nMac with Apple Silicon (M1+)"
                    )

                    Divider()

                    RequirementRow(
                        icon: "apps.iphone",
                        title: "Software",
                        description: "iOS 26.0 or later\nmacOS 26.0 (Tahoe) or later"
                    )

                    Divider()

                    RequirementRow(
                        icon: "gearshape.2",
                        title: "Apple Intelligence",
                        description: "Must be enabled in Settings"
                    )
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Why This Matters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why Apple Intelligence?")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 10) {
                        FeatureBullet(
                            icon: "lock.shield",
                            text: "100% private — your thoughts never leave your device"
                        )
                        FeatureBullet(
                            icon: "bolt.fill",
                            text: "Instant classification — no waiting for cloud AI"
                        )
                        FeatureBullet(
                            icon: "wifi.slash",
                            text: "Works offline — no internet required"
                        )
                        FeatureBullet(
                            icon: "dollarsign.circle",
                            text: "Zero cost — no API fees or subscriptions"
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
                    .frame(height: 20)

                // Action Button
                Button {
                    openAppleIntelligenceSettings()
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Help Text
                Text("If Apple Intelligence is already enabled, try restarting your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Setup Required")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openAppleIntelligenceSettings() {
        // Try to open Apple Intelligence settings
        // Note: This URL scheme may need to be updated based on actual iOS 26 structure
        if let url = URL(string: "App-prefs:APPLE_INTELLIGENCE") {
            openURL(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Supporting Views

struct RequirementRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.teal)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppleIntelligenceRequiredView()
    }
}
