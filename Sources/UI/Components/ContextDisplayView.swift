//
//  ContextDisplayView.swift
//  STASH
//
//  Phase 3A Spec 3: Context Display Component
//  Shows captured context information
//

import SwiftUI

// MARK: - Context Display View

/// Displays context information captured with a thought.
///
/// Shows time of day, location, energy level, focus state,
/// and activity in a readable format.
struct ContextDisplayView: View {
    let context: Context
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(theme.primaryColor)
                    .accessibilityHidden(true)

                Text("Context")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)

                Spacer()

                Text(context.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
            }

            // Context items
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                // Time of day
                ContextItem(
                    icon: context.timeOfDay.icon,
                    label: "Time",
                    value: context.timeOfDay.displayName
                )

                // Energy
                ContextItem(
                    icon: context.energy.icon,
                    label: "Energy",
                    value: context.energy.rawValue.capitalized
                )

                // Focus
                ContextItem(
                    icon: context.focusState.icon,
                    label: "Focus",
                    value: context.focusState.displayName
                )

                // Location
                if let location = context.location {
                    ContextItem(
                        icon: "location.fill",
                        label: "Location",
                        value: location.name ?? "Unknown"
                    )
                }

                // Activity
                if let activity = context.activity {
                    ContextItem(
                        icon: "figure.walk",
                        label: "Steps",
                        value: "\(activity.stepCount)"
                    )
                }

                // Calendar
                if let calendar = context.calendar {
                    ContextItem(
                        icon: "calendar",
                        label: "Availability",
                        value: calendar.isFreetime ? "Free" : "Busy"
                    )
                }
            }
        }
        .padding(12)
        .background(theme.primaryColor.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Context Item

/// A single context item with icon, label, and value.
struct ContextItem: View {
    let icon: String
    let label: String
    let value: String
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.primaryColor)
                .frame(width: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)

                Text(value)
                    .font(.caption)
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
            }

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Context Compact View

/// A compact context summary for list views.
struct ContextCompactView: View {
    let context: Context
    @Environment(\.themeEngine) private var themeEngine

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        HStack(spacing: 8) {
            // Time of day icon
            Image(systemName: context.timeOfDay.icon)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)

            // Location if available
            if let location = context.location, let name = location.name {
                HStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(name)
                        .font(.caption)
                }
                .foregroundColor(theme.secondaryTextColor)
            }

            // Energy
            Image(systemName: context.energy.icon)
                .font(.caption)
                .foregroundColor(context.energy.color(theme: theme))
        }
    }
}

// MARK: - Time of Day Extensions

extension TimeOfDay {
    var icon: String {
        switch self {
        case .early_morning: return "sunrise.fill"
        case .morning: return "sun.and.horizon.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Energy Level Extensions

extension EnergyLevel {
    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.75"
        case .peak: return "battery.100"
        }
    }

    func color(theme: any ThemeVariant) -> Color {
        switch self {
        case .low: return theme.errorColor
        case .medium: return theme.warningColor
        case .high: return theme.successColor
        case .peak: return theme.successColor.opacity(0.8)
        }
    }
}

// MARK: - Focus State Extensions

extension UserFocusState {
    var icon: String {
        switch self {
        case .deep_work: return "brain"
        case .interrupted: return "exclamationmark.triangle"
        case .scattered: return "arrow.triangle.branch"
        case .flow_state: return "sparkles"
        }
    }

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Previews

#Preview("Context Display") {
    ContextDisplayView(
        context: Context(
            timestamp: Date(),
            location: Location(
                latitude: 37.7749,
                longitude: -122.4194,
                name: "San Francisco",
                geofenceId: nil
            ),
            timeOfDay: .afternoon,
            energy: .high,
            focusState: .deep_work,
            calendar: CalendarContext(
                nextEventMinutes: 60,
                isFreetime: true,
                eventCount: 3
            ),
            activity: ActivityContext(
                stepCount: 5000,
                caloriesBurned: 250.0,
                activeMinutes: 45
            ),
            weather: nil,
            stateOfMind: nil,
            energyBreakdown: nil
        )
    )
    .padding()
}

#Preview("Context Compact") {
    ContextCompactView(
        context: Context(
            timestamp: Date(),
            location: Location(
                latitude: 37.7749,
                longitude: -122.4194,
                name: "Office",
                geofenceId: nil
            ),
            timeOfDay: .morning,
            energy: .medium,
            focusState: .scattered,
            calendar: nil,
            activity: nil,
            weather: nil,
            stateOfMind: nil,
            energyBreakdown: nil
        )
    )
    .padding()
}
