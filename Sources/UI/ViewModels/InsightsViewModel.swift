//
//  InsightsViewModel.swift
//  PersonalAI
//
//  Aggregates thought data for Swift Charts visualization
//

import Foundation
import SwiftUI

/// Data point for thought count over time chart
struct ThoughtCountDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

/// Data point for sentiment trends chart
struct SentimentDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let averageSentiment: Double
    let stateOfMindValence: Double?
}

/// Data point for type distribution chart
struct TypeDistributionDataPoint: Identifiable {
    let id = UUID()
    let type: ClassificationType
    let count: Int

    var typeName: String {
        switch type {
        case .note: return "Notes"
        case .idea: return "Ideas"
        case .reminder: return "Tasks"
        case .event: return "Events"
        case .question: return "Questions"
        }
    }
}

/// Data point for energy/state of mind correlation
struct EnergyCorrelationDataPoint: Identifiable {
    let id = UUID()
    let energy: EnergyLevel
    let thoughtCount: Int
    let averageValence: Double?

    var energyName: String {
        switch energy {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .peak: return "Peak"
        }
    }
}

/// View model for insights and analytics
@MainActor
@Observable
class InsightsViewModel {

    // MARK: - Dependencies

    private let thoughtService: ThoughtServiceProtocol

    // MARK: - State

    var isLoading = false
    var error: Error?

    // Chart data
    var thoughtCountData: [ThoughtCountDataPoint] = []
    var sentimentData: [SentimentDataPoint] = []
    var typeDistributionData: [TypeDistributionDataPoint] = []
    var energyCorrelationData: [EnergyCorrelationDataPoint] = []

    // Date range for filtering
    var dateRange: DateRange = .last30Days

    enum DateRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case allTime = "All Time"

        var startDate: Date? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .last7Days:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: now)
            case .last90Days:
                return calendar.date(byAdding: .day, value: -90, to: now)
            case .allTime:
                return nil
            }
        }
    }

    // MARK: - Initialization

    init(thoughtService: ThoughtServiceProtocol) {
        self.thoughtService = thoughtService
    }

    // MARK: - Data Loading

    func loadInsights() async {
        isLoading = true
        error = nil

        do {
            let thoughts = try await thoughtService.list(filter: nil)

            // Filter by date range
            let filteredThoughts: [Thought]
            if let startDate = dateRange.startDate {
                filteredThoughts = thoughts.filter { $0.createdAt >= startDate }
            } else {
                filteredThoughts = thoughts
            }

            // Generate all chart data
            thoughtCountData = generateThoughtCountData(from: filteredThoughts)
            sentimentData = generateSentimentData(from: filteredThoughts)
            typeDistributionData = generateTypeDistributionData(from: filteredThoughts)
            energyCorrelationData = generateEnergyCorrelationData(from: filteredThoughts)

            isLoading = false

        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Data Aggregation

    private func generateThoughtCountData(from thoughts: [Thought]) -> [ThoughtCountDataPoint] {
        let calendar = Calendar.current

        // Group thoughts by day
        let grouped = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        // Create data points
        return grouped.map { date, thoughts in
            ThoughtCountDataPoint(date: date, count: thoughts.count)
        }
        .sorted { $0.date < $1.date }
    }

    private func generateSentimentData(from thoughts: [Thought]) -> [SentimentDataPoint] {
        let calendar = Calendar.current

        // Group thoughts by day
        let grouped = Dictionary(grouping: thoughts) { thought in
            calendar.startOfDay(for: thought.createdAt)
        }

        // Calculate average sentiment and state of mind per day
        return grouped.compactMap { date, dayThoughts in
            // Average sentiment from AI classification (convert enum to numerical value)
            let sentiments = dayThoughts.compactMap { thought -> Double? in
                guard let sentiment = thought.classification?.sentiment else { return nil }
                switch sentiment {
                case .very_negative: return -1.0
                case .negative: return -0.5
                case .neutral: return 0.0
                case .positive: return 0.5
                case .very_positive: return 1.0
                }
            }
            guard !sentiments.isEmpty else { return nil }
            let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)

            // Average state of mind valence for the day
            let valences = dayThoughts.compactMap { $0.context.stateOfMind?.valence }
            let avgValence = valences.isEmpty ? nil : valences.reduce(0.0, +) / Double(valences.count)

            return SentimentDataPoint(
                date: date,
                averageSentiment: avgSentiment,
                stateOfMindValence: avgValence
            )
        }
        .sorted { $0.date < $1.date }
    }

    private func generateTypeDistributionData(from thoughts: [Thought]) -> [TypeDistributionDataPoint] {
        // Group by classification type
        let grouped = Dictionary(grouping: thoughts) { thought in
            thought.classification?.type ?? .note
        }

        return grouped.map { type, thoughts in
            TypeDistributionDataPoint(type: type, count: thoughts.count)
        }
        .sorted { $0.count > $1.count }
    }

    private func generateEnergyCorrelationData(from thoughts: [Thought]) -> [EnergyCorrelationDataPoint] {
        // Group by energy level
        let grouped = Dictionary(grouping: thoughts) { thought in
            thought.context.energy
        }

        return grouped.map { energy, thoughts in
            // Calculate average state of mind valence for this energy level
            let valences = thoughts.compactMap { $0.context.stateOfMind?.valence }
            let avgValence = valences.isEmpty ? nil : valences.reduce(0.0, +) / Double(valences.count)

            return EnergyCorrelationDataPoint(
                energy: energy,
                thoughtCount: thoughts.count,
                averageValence: avgValence
            )
        }
        .sorted { energyOrder($0.energy) < energyOrder($1.energy) }
    }

    private func energyOrder(_ energy: EnergyLevel) -> Int {
        switch energy {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .peak: return 3
        }
    }
}

// MARK: - Mock Insights View Model

@MainActor
@Observable
class MockInsightsViewModel: InsightsViewModel {
    init() {
        super.init(thoughtService: MockThoughtService())

        // Pre-populate with mock data
        let calendar = Calendar.current
        let today = Date()

        // Mock thought count data (last 7 days)
        thoughtCountData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return ThoughtCountDataPoint(
                date: calendar.startOfDay(for: date),
                count: Int.random(in: 3...15)
            )
        }.reversed()

        // Mock sentiment data
        sentimentData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return SentimentDataPoint(
                date: calendar.startOfDay(for: date),
                averageSentiment: Double.random(in: -0.5...0.8),
                stateOfMindValence: Double.random(in: -0.3...0.7)
            )
        }.reversed()

        // Mock type distribution
        typeDistributionData = [
            TypeDistributionDataPoint(type: .note, count: 45),
            TypeDistributionDataPoint(type: .reminder, count: 32),
            TypeDistributionDataPoint(type: .idea, count: 28),
            TypeDistributionDataPoint(type: .question, count: 15),
            TypeDistributionDataPoint(type: .event, count: 8)
        ]

        // Mock energy correlation
        energyCorrelationData = [
            EnergyCorrelationDataPoint(energy: .low, thoughtCount: 12, averageValence: -0.2),
            EnergyCorrelationDataPoint(energy: .medium, thoughtCount: 45, averageValence: 0.3),
            EnergyCorrelationDataPoint(energy: .high, thoughtCount: 38, averageValence: 0.6),
            EnergyCorrelationDataPoint(energy: .peak, thoughtCount: 15, averageValence: 0.8)
        ]
    }
}
