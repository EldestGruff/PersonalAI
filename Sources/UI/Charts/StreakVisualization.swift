//
//  StreakVisualization.swift
//  STASH
//
//  Issue #18: Swift Charts - Streak Gamification
//  Shows capture consistency and streaks
//

import SwiftUI

/// Gamification component showing capture streaks
struct StreakVisualization: View {
    let streakData: StreakData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Label("Capture Streak", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.orange)
                .accessibilityAddTraits(.isHeader)

            // Current streak hero
            HStack(spacing: 20) {
                // Current streak
                VStack(spacing: 4) {
                    Text("\(streakData.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(streakColor)
                        .contentTransition(.numericText())

                    Text("day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(streakData.currentStreak) day current streak")

                Divider()
                    .frame(height: 60)

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("\(streakData.longestStreak) best")
                            .font(.subheadline)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(streakData.longestStreak) days is your longest streak")

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(streakData.totalDaysWithThoughts) total days")
                            .font(.subheadline)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("You've captured thoughts on \(streakData.totalDaysWithThoughts) total days")
                }
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )

            // Streak history (last 90 days GitHub-style)
            if !streakData.streakHistory.isEmpty {
                contributionGrid
            }

            // Encouragement message
            encouragementMessage
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var contributionGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 90 Days")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Simplified contribution squares (7 rows x ~13 columns)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 13),
                spacing: 4
            ) {
                ForEach(contributionDays, id: \.date) { day in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(contributionColor(for: day))
                        .frame(width: 12, height: 12)
                        .accessibilityLabel(accessibilityLabel(for: day))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var encouragementMessage: some View {
        let tracker = StreakTracker.shared
        let days = tracker.daysSinceLastCapture ?? 999

        return Group {
            if streakData.currentStreak == 0 && days >= 3 {
                // Squirrel went on an adventure — no shame
                HStack(spacing: 6) {
                    Text("🌰")
                    Text("Your squirrel went foraging. Welcome back — let's capture something.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if streakData.currentStreak == 0 {
                HStack(spacing: 6) {
                    Text("🌿")
                    Text("Ready when you are. Capture a thought to start a new streak.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if streakData.currentStreak == 1 {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Day one. The hardest and most important one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if streakData.currentStreak >= 30 {
                HStack(spacing: 6) {
                    Text("🏆")
                    Text("\(streakData.currentStreak) days. This is who you are now.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if streakData.currentStreak >= 7 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(streakData.currentStreak) days — that's a real habit forming.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward")
                        .foregroundStyle(.green)
                    Text("\(streakData.currentStreak) days and building. Keep it going.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private var streakColor: Color {
        switch streakData.currentStreak {
        case 0: return .gray
        case 1...2: return .orange
        case 3...6: return .yellow
        case 7...13: return .green
        case 14...29: return .blue
        default: return .purple
        }
    }

    private struct ContributionDay {
        let date: Date
        let hasThought: Bool
    }

    private var contributionDays: [ContributionDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get dates with thoughts
        let datesWithThoughts = Set(
            streakData.streakHistory.flatMap { period -> [Date] in
                var dates: [Date] = []
                var current = calendar.startOfDay(for: period.startDate)
                let end = calendar.startOfDay(for: period.endDate)

                while current <= end {
                    dates.append(current)
                    guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                    current = next
                }
                return dates
            }
        )

        // Generate 91 days (including today)
        return (0...90).map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return ContributionDay(date: today, hasThought: false)
            }
            return ContributionDay(
                date: date,
                hasThought: datesWithThoughts.contains(date)
            )
        }
        .reversed()
    }

    private func contributionColor(for day: ContributionDay) -> Color {
        if day.hasThought {
            return Color.accentColor.opacity(0.8)
        } else {
            return Color(.systemGray5)
        }
    }

    private func accessibilityLabel(for day: ContributionDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if day.hasThought {
            return "Captured thoughts on \(formatter.string(from: day.date))"
        } else {
            return "No thoughts on \(formatter.string(from: day.date))"
        }
    }
}

// MARK: - Previews

#Preview("Active Streak") {
    StreakVisualization(
        streakData: StreakData(
            currentStreak: 12,
            longestStreak: 15,
            totalDaysWithThoughts: 45,
            streakHistory: [
                StreakPeriod(
                    startDate: Date().addingTimeInterval(-12 * 86400),
                    endDate: Date(),
                    length: 12
                ),
                StreakPeriod(
                    startDate: Date().addingTimeInterval(-30 * 86400),
                    endDate: Date().addingTimeInterval(-20 * 86400),
                    length: 10
                )
            ]
        )
    )
}

#Preview("No Streak") {
    StreakVisualization(
        streakData: StreakData(
            currentStreak: 0,
            longestStreak: 5,
            totalDaysWithThoughts: 20,
            streakHistory: [
                StreakPeriod(
                    startDate: Date().addingTimeInterval(-10 * 86400),
                    endDate: Date().addingTimeInterval(-6 * 86400),
                    length: 5
                )
            ]
        )
    )
}

#Preview("New User") {
    StreakVisualization(
        streakData: StreakData(
            currentStreak: 1,
            longestStreak: 1,
            totalDaysWithThoughts: 1,
            streakHistory: [
                StreakPeriod(
                    startDate: Date(),
                    endDate: Date(),
                    length: 1
                )
            ]
        )
    )
}
