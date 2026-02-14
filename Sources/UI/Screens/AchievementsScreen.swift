//
//  AchievementsScreen.swift
//  STASH
//
//  Gamification achievements hub: stats overview + all achievements,
//  showing which have been earned and which are still locked.
//

import SwiftUI

// MARK: - Achievements Screen

struct AchievementsScreen: View {
    @State var viewModel: AchievementsViewModel
    @Environment(\.themeEngine) private var themeEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingView("Loading achievements...")
                } else {
                    content
                }
            }
            .navigationTitle("Achievements")
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
            .task { await viewModel.load() }
        }
    }

    // MARK: - Main Content

    private var content: some View {
        let theme = themeEngine.getCurrentTheme()

        return List {
            // ── Stats header ──────────────────────────────────────────
            Section {
                statsGrid
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            // ── Progress summary ──────────────────────────────────────
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.earnedCount) of \(viewModel.totalCount) earned")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.textColor)
                        Text("\(viewModel.totalCount - viewModel.earnedCount) remaining")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    Spacer()
                    // Progress ring
                    progressRing
                }
                .padding(.vertical, 4)
            }

            // ── Achievements by category ──────────────────────────────
            ForEach(AchievementCategory.allCases, id: \.self) { category in
                let items = viewModel.achievements(for: category)
                if !items.isEmpty {
                    Section(header: categoryHeader(category)) {
                        ForEach(items) { achievement in
                            AchievementRowView(achievement: achievement)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.backgroundColor)
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(emoji: "🔥", value: "\(viewModel.currentStreak)", label: "Current Streak")
            StatCard(emoji: "📈", value: "\(viewModel.longestStreak)", label: "Longest Streak")
            StatCard(emoji: "📅", value: "\(viewModel.totalCaptureDays)", label: "Capture Days")
            StatCard(emoji: "🌰", value: "\(viewModel.currentAcorns)", label: "Current Acorns")
            StatCard(emoji: "💰", value: "\(viewModel.lifetimeAcorns)", label: "Lifetime Acorns")
            StatCard(emoji: "✨", value: "\(viewModel.shinyCount)", label: "Shinies Found")
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        let theme = themeEngine.getCurrentTheme()
        let progress = viewModel.totalCount > 0
            ? Double(viewModel.earnedCount) / Double(viewModel.totalCount)
            : 0.0

        return ZStack {
            Circle()
                .stroke(theme.dividerColor, lineWidth: 5)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(theme.primaryColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.textColor)
        }
        .animation(.easeInOut(duration: 0.6), value: progress)
    }

    // MARK: - Category Header

    private func categoryHeader(_ category: AchievementCategory) -> some View {
        HStack(spacing: 6) {
            if category == .acorns {
                Text(category.icon)
                    .font(.caption)
            } else {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(category.rawValue)
                .font(.footnote.weight(.semibold))
                .textCase(nil)
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let emoji: String
    let value: String
    let label: String

    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 4) {
            Text(emoji)
                .font(.title3)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(theme.textColor)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Achievement Row

private struct AchievementRowView: View {
    let achievement: Achievement

    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isEarned
                          ? theme.primaryColor.opacity(0.15)
                          : theme.dividerColor.opacity(0.5))
                    .frame(width: 42, height: 42)

                if achievement.isEarned {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(theme.primaryColor)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.5))
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(achievement.isEarned ? theme.textColor : theme.secondaryTextColor)

                Text(achievement.isEarned ? achievement.description : achievement.goalLabel)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()

            // Earned badge
            if achievement.isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.successColor)
                    .font(.title3)
                    .accessibilityLabel("Earned")
            }
        }
        .padding(.vertical, 4)
        .opacity(achievement.isEarned ? 1.0 : 0.65)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(achievement.isEarned
            ? "\(achievement.title), earned. \(achievement.description)"
            : "\(achievement.title), locked. Goal: \(achievement.goalLabel)")
    }
}

// MARK: - Preview

#Preview("Achievements") {
    AchievementsScreen(
        viewModel: AchievementsViewModel(thoughtService: ThoughtService.shared)
    )
}
