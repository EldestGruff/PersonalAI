//
//  Chart3DPreviewScreen.swift
//  STASH
//
//  Temporary preview screen for testing 3D visualizations
//

import SwiftUI

@available(iOS 26.0, *)
struct Chart3DPreviewScreen: View {
    @State private var themeEngine = ThemeEngine.shared
    @State private var dataService: Chart3DDataService?
    @State private var thoughtSpaceData: [ThoughtSpace3DPoint] = []
    @State private var isLoading = true
    @State private var dateRange: ChartDateRange = .month

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Date range picker
                        Picker("Time Range", selection: $dateRange) {
                            Text("Week").tag(ChartDateRange.week)
                            Text("Month").tag(ChartDateRange.month)
                            Text("Quarter").tag(ChartDateRange.quarter)
                            Text("Year").tag(ChartDateRange.year)
                            Text("All").tag(ChartDateRange.all)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: dateRange) { _, _ in
                            loadData()
                        }

                        // 3D Chart
                        if isLoading {
                            ProgressView()
                                .frame(height: 400)
                        } else {
                            ThoughtSpace3D(dataPoints: thoughtSpaceData)
                        }

                        // Stats
                        statsSection(theme: theme)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("3D Visualization Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            setupService()
            loadData()
        }
    }

    // MARK: - Stats Section

    private func statsSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Summary")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            HStack(spacing: 16) {
                StatCard(
                    title: "Total Points",
                    value: "\(thoughtSpaceData.count)",
                    icon: "cube.fill",
                    theme: theme
                )

                StatCard(
                    title: "Avg Sentiment",
                    value: averageSentiment,
                    icon: "heart.fill",
                    theme: theme
                )

                StatCard(
                    title: "Avg Energy",
                    value: averageEnergy,
                    icon: "bolt.fill",
                    theme: theme
                )
            }
        }
        .padding(.horizontal)
    }

    private var averageSentiment: String {
        guard !thoughtSpaceData.isEmpty else { return "—" }
        let avg = thoughtSpaceData.map { $0.sentiment }.reduce(0, +) / Double(thoughtSpaceData.count)
        return String(format: "%.2f", avg)
    }

    private var averageEnergy: String {
        guard !thoughtSpaceData.isEmpty else { return "—" }
        let avg = thoughtSpaceData.map { $0.energyLevel }.reduce(0, +) / Double(thoughtSpaceData.count)
        return String(format: "%.2f", avg)
    }

    // MARK: - Data Loading

    private func setupService() {
        dataService = Chart3DDataService(
            thoughtService: ThoughtService.shared,
            healthKitService: HealthKitService()
        )
    }

    private func loadData() {
        isLoading = true

        _Concurrency.Task {
            do {
                if let service = dataService {
                    thoughtSpaceData = try await service.getThoughtSpace3D(dateRange: dateRange)
                }
                isLoading = false
            } catch {
                print("Error loading 3D data: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let theme: Theme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(theme.primaryColor)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(theme.textColor)

            Text(title)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceColor)
        )
    }
}

// MARK: - Fallback for iOS < 26

struct Chart3DPreviewScreenFallback: View {
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.secondaryTextColor)

                Text("iOS 26+ Required")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.textColor)

                Text("3D visualizations require iOS 26 or later with Swift Charts 3D support.")
                    .font(.body)
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Previews

#Preview("3D Preview - iOS 26+") {
    if #available(iOS 26.0, *) {
        Chart3DPreviewScreen()
    } else {
        Chart3DPreviewScreenFallback()
    }
}
