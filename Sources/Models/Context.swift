//
//  Context.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Situational context captured when a thought is created
//

import Foundation

/// Contextual information captured at the moment a thought is created.
///
/// Context enables pattern recognition and context-aware suggestions by recording
/// the user's situation when they captured a thought. This includes time of day,
/// location, energy level, calendar state, and other environmental factors.
///
/// All context fields except `timestamp` are optional, as not all information
/// may be available or authorized (e.g., location services disabled).
///
/// - Note: Context gathering logic is implemented in Spec 2 (ContextService).
///         This struct is a pure data container.
///
/// - Important: Context is stored as JSON in Core Data for flexibility.
struct Context: Codable, Equatable, Sendable {
    /// Exact time when the thought was captured
    let timestamp: Date

    /// Geographic location (if available and authorized)
    let location: Location?

    /// Broad time period of day
    let timeOfDay: TimeOfDay

    /// User's energy level (inferred or manually set)
    let energy: EnergyLevel

    /// User's current focus state
    let focusState: UserFocusState

    /// Calendar context (upcoming events, free time)
    let calendar: CalendarContext?

    /// Physical activity data from HealthKit
    let activity: ActivityContext?

    /// Weather conditions (if available)
    let weather: WeatherContext?

    /// Creates an empty/default context with current timestamp.
    ///
    /// Used when context gathering is unavailable or fails.
    static func empty() -> Context {
        Context(
            timestamp: Date(),
            location: nil,
            timeOfDay: TimeOfDay.from(date: Date()),
            energy: .medium,
            focusState: .scattered,
            calendar: nil,
            activity: nil,
            weather: nil
        )
    }
}

/// Geographic location information.
///
/// Contains both precise coordinates and optional human-readable metadata.
struct Location: Codable, Equatable, Sendable {
    /// Latitude in decimal degrees (-90 to +90)
    let latitude: Double

    /// Longitude in decimal degrees (-180 to +180)
    let longitude: Double

    /// Human-readable location name (e.g., "New York", "Home", "Office")
    let name: String?

    /// Identifier for a user-defined geofence (e.g., "work", "gym")
    let geofenceId: String?
}

/// Broad time period classification.
///
/// Used for pattern recognition (e.g., "User captures ideas in early morning").
/// Automatically derived from timestamp using `from(date:)` method.
enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    /// 5:00 AM - 8:59 AM
    case early_morning

    /// 9:00 AM - 11:59 AM
    case morning

    /// 12:00 PM - 4:59 PM
    case afternoon

    /// 5:00 PM - 8:59 PM
    case evening

    /// 9:00 PM - 4:59 AM
    case night

    /// Derives time of day from a given date.
    ///
    /// - Parameter date: The date to classify
    /// - Returns: The appropriate time period
    nonisolated static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<9:
            return .early_morning
        case 9..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<21:
            return .evening
        default:
            return .night
        }
    }
}

/// User's energy level.
///
/// Can be inferred from HealthKit data (sleep, activity) combined with
/// circadian rhythm patterns, or manually set by the user.
///
/// - `low`: Tired, low motivation
/// - `medium`: Normal baseline energy
/// - `high`: Alert and energetic
/// - `peak`: Maximum energy and focus (flow state potential)
enum EnergyLevel: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    case peak
}

/// Debug information about how energy level was calculated.
///
/// Used for testing and diagnostics to understand energy calculation.
struct EnergyBreakdown: Codable, Equatable, Sendable {
    /// Sleep quality score (0.0-1.0)
    let sleepScore: Double

    /// Activity level score (0.0-1.0)
    let activityScore: Double

    /// HRV/Recovery score (0.0-1.0)
    let hrvScore: Double

    /// Time of day bonus (0.0-1.0)
    let timeBonus: Double

    /// Combined weighted score
    let totalScore: Double

    /// Final energy level
    let level: EnergyLevel

    /// Raw HRV value in milliseconds (optional, for debugging)
    let hrvValueMs: Double?

    /// Sleep hours (optional, for debugging)
    let sleepHours: Double?

    /// Step count (optional, for debugging)
    let stepCount: Int?
}

/// User's focus state.
///
/// Indicates the user's mental state and ability to concentrate.
/// Can be inferred from app usage patterns or manually set.
///
/// - `deep_work`: Concentrated focus on a single task
/// - `interrupted`: Frequent context switches, many notifications
/// - `scattered`: Unfocused, browsing mode
/// - `flow_state`: Peak focus, highly productive
enum UserFocusState: String, Codable, CaseIterable, Sendable {
    case deep_work
    case interrupted
    case scattered
    case flow_state
}

/// Calendar and scheduling context.
///
/// Provides information about the user's schedule to help with
/// task prioritization and reminder timing.
struct CalendarContext: Codable, Equatable, Sendable {
    /// Minutes until the next calendar event (nil if no upcoming events)
    let nextEventMinutes: Int?

    /// Whether the user is in a free time block (no events for next 2 hours)
    let isFreetime: Bool

    /// Number of events scheduled for today
    let eventCount: Int
}

/// Physical activity context from HealthKit and Core Motion.
///
/// Tracks the user's movement and exercise data.
struct ActivityContext: Codable, Equatable, Sendable {
    /// Step count today
    let stepCount: Int

    /// Calories burned today
    let caloriesBurned: Double

    /// Minutes of active movement today
    let activeMinutes: Int
}

/// Weather conditions at the time of thought capture.
///
/// Optional external data from weather API.
struct WeatherContext: Codable, Equatable, Sendable {
    /// Weather condition description (e.g., "sunny", "rainy", "cloudy")
    let condition: String?

    /// Temperature in Celsius
    let temperature: Double?
}
