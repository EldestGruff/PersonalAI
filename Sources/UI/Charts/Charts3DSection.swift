//
//  Charts3DSection.swift
//  STASH
//
//  Issue #25: 3D Visualizations - Section Container
//  Displays all 3D chart visualizations with type picker
//

import SwiftUI

@available(iOS 26.0, *)
struct Charts3DSection: View {
    @State private var selectedChartType: Chart3DType = .thoughtSpace
    @State private var dataService: Chart3DDataService?
    @State private var dateRange: ChartDateRange = .month
    @State private var themeEngine = ThemeEngine.shared

    // Data states
    @State private var thoughtSpaceData: [ThoughtSpace3DPoint] = []
    @State private var healthCorrelationData: [HealthCorrelation3DPoint] = []
    @State private var trendSurfaceData: TrendSurface3DData?
    @State private var tagSemanticData: [TagSemantic3DPoint] = []

    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(spacing: 16) {
            // iOS 26+ requirement banner
            requirementBanner(theme: theme)

            // Chart type picker
            chartTypePicker(theme: theme)

            // Loading/Error/Content
            if isLoading {
                ProgressView("Loading 3D data...")
                    .foregroundStyle(theme.secondaryTextColor)
                    .frame(height: 400)
            } else if let error = loadError {
                errorView(error: error, theme: theme)
            } else {
                // Chart based on selected type
                switch selectedChartType {
                case .thoughtSpace:
                    ThoughtSpace3D(dataPoints: thoughtSpaceData)
                case .healthCorrelation:
                    HealthCorrelation3D(dataPoints: healthCorrelationData)
                case .trendSurface:
                    if let surfaceData = trendSurfaceData {
                        TrendSurface3D(surfaceData: surfaceData)
                    } else {
                        emptyView(for: .trendSurface, theme: theme)
                    }
                case .tagSemantic:
                    TagSemantic3D(dataPoints: tagSemanticData)
                }
            }
        }
        .onAppear {
            setupService()
            loadData()
        }
        .onChange(of: selectedChartType) { _, _ in
            loadData()
        }
        .onChange(of: dateRange) { _, _ in
            loadData()
        }
    }

    // MARK: - Requirement Banner

    private func requirementBanner(theme: any ThemeVariant) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.fill")
                .font(.title3)
                .foregroundStyle(theme.primaryColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("3D Visualizations")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                Text("Explore your thoughts in immersive 3D space")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.primaryColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Chart Type Picker

    private func chartTypePicker(theme: any ThemeVariant) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Chart3DType.allCases) { chartType in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedChartType = chartType
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: chartType.icon)
                                .font(.title3)
                                .foregroundStyle(
                                    selectedChartType == chartType
                                        ? .white
                                        : theme.primaryColor
                                )

                            Text(chartType.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    selectedChartType == chartType
                                        ? .white
                                        : theme.textColor
                                )
                        }
                        .frame(width: 100, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    selectedChartType == chartType
                                        ? theme.primaryColor
                                        : theme.surfaceColor
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedChartType == chartType
                                        ? theme.primaryColor
                                        : theme.dividerColor,
                                    lineWidth: selectedChartType == chartType ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Error View

    private func errorView(error: String, theme: any ThemeVariant) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(theme.warningColor)

            Text("Unable to load 3D data")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text(error)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                loadData()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.primaryColor)
        }
        .frame(height: 400)
        .padding()
    }

    // MARK: - Empty View

    private func emptyView(for chartType: Chart3DType, theme: any ThemeVariant) -> some View {
        VStack(spacing: 16) {
            Image(systemName: chartType.icon)
                .font(.system(size: 60))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))

            Text("No data available")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("Not enough data to generate this visualization")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 400)
    }

    // MARK: - Data Loading

    private func setupService() {
        dataService = Chart3DDataService(
            thoughtService: ThoughtService.shared,
            healthKitService: HealthKitService()
        )
    }

    private func loadData() {
        guard let service = dataService else { return }

        isLoading = true
        loadError = nil

        _Concurrency.Task.init {
            do {
                switch selectedChartType {
                case .thoughtSpace:
                    thoughtSpaceData = try await service.getThoughtSpace3D(dateRange: dateRange)
                    print("📊 Loaded \(thoughtSpaceData.count) thought space points")

                case .healthCorrelation:
                    healthCorrelationData = try await service.getHealthCorrelation3D(dateRange: dateRange)
                    print("📊 Loaded \(healthCorrelationData.count) health correlation points")

                case .trendSurface:
                    trendSurfaceData = try await service.getTrendSurface3D(dateRange: dateRange)
                    print("📊 Loaded \(trendSurfaceData?.points.count ?? 0) trend surface points")

                case .tagSemantic:
                    tagSemanticData = try await service.getTagSemantic3D(dateRange: dateRange)
                    print("📊 Loaded \(tagSemanticData.count) tag semantic points")
                }

                isLoading = false
            } catch {
                print("❌ Chart data loading error: \(error)")
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Fallback for iOS < 26

struct Charts3DSectionFallback: View {
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

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

            Text("Update your device to iOS 26 to explore your thoughts in immersive 3D space.")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 400)
        .padding()
    }
}

// MARK: - Previews

#Preview("3D Section - iOS 26+") {
    if #available(iOS 26.0, *) {
        Charts3DSection()
    } else {
        Charts3DSectionFallback()
    }
}
