//
//  SquirrelCompanionCard.swift
//  STASH
//
//  Gamification issue #44: Tamagotchi Layer
//
//  The main companion widget shown on BrowseScreen.
//  Displays life stage, equipped accessories, emotional state,
//  adventure mode recap, and a button to open the Acorn Shop.
//

import SwiftUI

// MARK: - Squirrel Companion Card

struct SquirrelCompanionCard: View {
    let persona: SquirrelPersona

    @Environment(\.themeEngine) private var themeEngine
    @State private var companionService = SquirrelCompanionService.shared
    @State private var stateEngine = SquirrelStateEngine.shared
    @State private var adventureImageName: String = "squirrel-adventuring"

    private static let adventureImages = [
        "squirrel-adventuring",
        "squirrel-adventuring-chef",
        "squirrel-adventuring-painter",
        "squirrel-adventuring-pilot",
        "squirrel-adventuring-professor",
    ]

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        let stage = companionService.currentLifeStage
        let state = stateEngine.currentState
        let imageName = companionService.isOnAdventure ? adventureImageName : state.imageName

        // Two equal halves — each centers its content independently
        HStack(spacing: 0) {
            // ── Left half: Mood squirrel ───────────────────────────────
            VStack(spacing: 6) {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)

                    if let accessory = companionService.equippedAccessory {
                        Text(accessory.emoji)
                            .font(.system(size: 18))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                    if companionService.isOnAdventure {
                        Text("🗺️")
                            .font(.system(size: 12))
                            .padding(3)
                            .background(Circle().fill(theme.surfaceColor))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
                .frame(width: 90, height: 100)

                HStack(spacing: 3) {
                    Text(state.emoji).font(.caption2)
                    Text(state.label)
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)

            // ── Right half: Growth tree ────────────────────────────────
            VStack(spacing: 4) {
                Text(treeEmoji(stage))
                    .font(.system(size: 60))

                Text(stage.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(stageColor(stage, theme: theme))

                if let next = stage.nextMilestone {
                    let progress = Double(companionService.lifetimeCaptureCount) / Double(next)
                    ProgressView(value: min(progress, 1.0))
                        .tint(stageColor(stage, theme: theme))
                        .frame(maxWidth: 80)
                    Text("\(companionService.lifetimeCaptureCount) / \(next)")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryTextColor)
                } else {
                    Text("🌟 Max level")
                        .font(.caption2)
                        .foregroundStyle(stageColor(stage, theme: theme))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceColor.opacity(0.6))
                .shadow(color: theme.shadowColor, radius: 4, y: 2)
        )
        .onAppear {
            adventureImageName = Self.adventureImages.randomElement() ?? "squirrel-adventuring"
        }
    }

    // MARK: - Helpers

    private func treeEmoji(_ stage: SquirrelLifeStage) -> String {
        switch stage {
        case .sprout:    return "🌰"
        case .curious:   return "🌱"
        case .seasoned:  return "🪴"
        case .elder:     return "🌳"
        case .legendary: return "🌳"
        }
    }

    private func stageColor(_ stage: SquirrelLifeStage, theme: any ThemeVariant) -> Color {
        switch stage {
        case .sprout:    return Color.green
        case .curious:   return theme.primaryColor
        case .seasoned:  return Color.orange
        case .elder:     return Color.purple
        case .legendary: return Color(red: 1.0, green: 0.78, blue: 0.1)
        }
    }
}

// MARK: - Accessory Shop View

struct AccessoryShopView: View {
    let persona: SquirrelPersona

    @Environment(\.themeEngine) private var themeEngine
    @Environment(\.dismiss) private var dismiss
    @State private var companionService = SquirrelCompanionService.shared
    @State private var acornLedger = AcornService.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                List {
                    // Balance header
                    Section {
                        HStack {
                            Text("🌰")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(acornLedger.currentBalance) acorns available")
                                    .font(.headline)
                                    .foregroundStyle(theme.textColor)
                                Text("Earn more by capturing thoughts")
                                    .font(.caption)
                                    .foregroundStyle(theme.secondaryTextColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(theme.surfaceColor)

                    // Currently equipped
                    if let equipped = companionService.equippedAccessory {
                        Section("Equipped") {
                            accessoryRow(equipped, theme: theme)
                        }
                        .listRowBackground(theme.surfaceColor)
                    }

                    // Owned accessories
                    let owned = SquirrelAccessory.catalog.filter { companionService.isOwned($0) && $0.id != companionService.equippedAccessoryId }
                    if !owned.isEmpty {
                        Section("Your Collection") {
                            ForEach(owned) { accessory in
                                accessoryRow(accessory, theme: theme)
                            }
                        }
                        .listRowBackground(theme.surfaceColor)
                    }

                    // For sale
                    let forSale = SquirrelAccessory.catalog.filter { $0.isForSale && !companionService.isOwned($0) }
                    if !forSale.isEmpty {
                        Section("Available to Buy") {
                            ForEach(forSale) { accessory in
                                accessoryRow(accessory, theme: theme)
                            }
                        }
                        .listRowBackground(theme.surfaceColor)
                    }

                    // Milestone accessories
                    let milestoneAccessories = SquirrelAccessory.catalog.filter { !$0.isForSale }
                    if !milestoneAccessories.isEmpty {
                        Section {
                            ForEach(milestoneAccessories) { accessory in
                                accessoryRow(accessory, theme: theme)
                            }
                        } header: {
                            Text("Milestone Unlocks")
                        } footer: {
                            Text("These unlock automatically when you hit the milestone.")
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        .listRowBackground(theme.surfaceColor)
                    }
                }
                .scrollContentBackground(.hidden)
                #if os(iOS)
                .listStyle(.insetGrouped)
                #endif
            }
            .navigationTitle("Acorn Shop 🌰")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func accessoryRow(_ accessory: SquirrelAccessory, theme: any ThemeVariant) -> some View {
        let isOwned = companionService.isOwned(accessory)
        let isEquipped = companionService.equippedAccessoryId == accessory.id
        let canAfford = acornLedger.currentBalance >= accessory.cost

        HStack(spacing: 12) {
            Text(accessory.emoji)
                .font(.title2)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(accessory.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.textColor)
                if let condition = accessory.unlockCondition {
                    Text(condition)
                        .font(.caption)
                        .foregroundStyle(isOwned ? theme.successColor : theme.secondaryTextColor)
                } else {
                    Text(isOwned ? "Owned" : "\(accessory.cost) 🌰")
                        .font(.caption)
                        .foregroundStyle(isOwned ? theme.successColor : (canAfford ? theme.primaryColor : theme.secondaryTextColor))
                }
            }

            Spacer()

            if isEquipped {
                Button("Unequip") {
                    companionService.unequip()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(theme.secondaryTextColor)
            } else if isOwned {
                Button("Equip") {
                    companionService.equip(accessory)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(theme.primaryColor)
            } else if accessory.isForSale {
                Button("Buy") {
                    _ = companionService.purchase(accessory)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(canAfford ? theme.primaryColor : theme.dividerColor)
                .disabled(!canAfford)
            } else {
                Image(systemName: isOwned ? "lock.open.fill" : "lock.fill")
                    .foregroundStyle(isOwned ? theme.successColor : theme.secondaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Companion Card") {
    SquirrelCompanionCard(persona: .brainstormPartner)
        .padding()
}

#Preview("Accessory Shop") {
    AccessoryShopView(persona: .brainstormPartner)
}
