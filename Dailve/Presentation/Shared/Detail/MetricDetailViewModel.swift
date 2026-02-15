import Foundation
import Observation
import OSLog

/// ViewModel for MetricDetailView — loads period-based chart data and summary stats.
/// Uses `import Observation` only (no SwiftUI per layer rules).
@Observable
@MainActor
final class MetricDetailViewModel {
    var selectedPeriod: TimePeriod = .week {
        didSet { if oldValue != selectedPeriod { triggerReload() } }
    }
    var chartData: [ChartDataPoint] = []
    var rangeData: [RangeDataPoint] = []
    var stackedData: [StackedDataPoint] = []
    var summaryStats: MetricSummary?
    var highlights: [Highlight] = []
    var isLoading = false
    var errorMessage: String?

    private(set) var category: HealthMetric.Category = .hrv
    private(set) var currentValue: Double = 0
    private(set) var lastUpdated: Date?

    private let hrvService: HRVQuerying
    private let sleepService: SleepQuerying
    private let stepsService: StepsQuerying
    private let workoutService: WorkoutQuerying
    private let bodyService: BodyCompositionQuerying

    private var needsReload = false

    init(
        hrvService: HRVQuerying? = nil,
        sleepService: SleepQuerying? = nil,
        stepsService: StepsQuerying? = nil,
        workoutService: WorkoutQuerying? = nil,
        bodyService: BodyCompositionQuerying? = nil,
        healthKitManager: HealthKitManager = .shared
    ) {
        self.hrvService = hrvService ?? HRVQueryService(manager: healthKitManager)
        self.sleepService = sleepService ?? SleepQueryService(manager: healthKitManager)
        self.stepsService = stepsService ?? StepsQueryService(manager: healthKitManager)
        self.workoutService = workoutService ?? WorkoutQueryService(manager: healthKitManager)
        self.bodyService = bodyService ?? BodyCompositionQueryService(manager: healthKitManager)
    }

    func configure(category: HealthMetric.Category, currentValue: Double, lastUpdated: Date?) {
        self.category = category
        self.currentValue = currentValue
        self.lastUpdated = lastUpdated
    }

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            switch category {
            case .hrv:      try await loadHRVData()
            case .rhr:      try await loadRHRData()
            case .sleep:    try await loadSleepData()
            case .steps:    try await loadStepsData()
            case .exercise: try await loadExerciseData()
            case .weight:   try await loadWeightData()
            }
            buildHighlights()
        } catch {
            AppLogger.ui.error("MetricDetail load failed for \(self.category.rawValue): \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private Reload Trigger

    private func triggerReload() {
        needsReload = true
        Task { await loadData() }
    }

    // MARK: - HRV

    private func loadHRVData() async throws {
        let range = selectedPeriod.dateRange
        let dayCount = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 7
        let samples = try await hrvService.fetchHRVSamples(days: dayCount)

        let aggregated = aggregateChartData(
            from: samples.map { ChartDataPoint(date: $0.date, value: $0.value) },
            period: selectedPeriod
        )
        chartData = aggregated
        summaryStats = computeSummary(from: aggregated.map(\.value))
    }

    // MARK: - RHR

    private func loadRHRData() async throws {
        let range = selectedPeriod.dateRange
        let dayCount = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 7

        // Fetch daily RHR values
        let calendar = Calendar.current
        var points: [ChartDataPoint] = []

        try await withThrowingTaskGroup(of: (Date, Double?).self) { group in
            for dayOffset in 0..<dayCount {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                group.addTask { [hrvService] in
                    let rhr = try await hrvService.fetchRestingHeartRate(for: date)
                    return (date, rhr)
                }
            }

            for try await (date, rhr) in group {
                if let rhr {
                    points.append(ChartDataPoint(date: date, value: rhr))
                }
            }
        }

        points.sort(by: { $0.date < $1.date })

        // Build range data from daily values (for now using same value for min/max/avg)
        rangeData = points.map {
            RangeDataPoint(date: $0.date, min: $0.value - 2, max: $0.value + 2, average: $0.value)
        }
        chartData = points
        summaryStats = computeSummary(from: points.map(\.value))
    }

    // MARK: - Sleep

    private func loadSleepData() async throws {
        let range = selectedPeriod.dateRange
        let calendar = Calendar.current
        let dayCount = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 7

        if selectedPeriod == .day {
            // Day mode: show raw sleep stages
            let stages = try await sleepService.fetchSleepStages(for: Date())
            let totalMinutes = stages.reduce(0.0) { $0 + $1.duration } / 60.0
            chartData = [ChartDataPoint(date: Date(), value: totalMinutes)]
            summaryStats = computeSummary(from: [totalMinutes])
        } else {
            // Week+ mode: daily total sleep as stacked data
            var dailyPoints: [ChartDataPoint] = []

            try await withThrowingTaskGroup(of: (Date, [SleepStage]).self) { group in
                for dayOffset in 0..<dayCount {
                    guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                    group.addTask { [sleepService] in
                        let stages = try await sleepService.fetchSleepStages(for: date)
                        return (date, stages)
                    }
                }

                for try await (date, stages) in group {
                    let totalMinutes = stages.reduce(0.0) { $0 + $1.duration } / 60.0
                    if totalMinutes > 0 {
                        dailyPoints.append(ChartDataPoint(date: date, value: totalMinutes))
                    }
                }
            }

            dailyPoints.sort(by: { $0.date < $1.date })
            chartData = dailyPoints
            summaryStats = computeSummary(from: dailyPoints.map(\.value))
        }
    }

    // MARK: - Steps

    private func loadStepsData() async throws {
        let range = selectedPeriod.dateRange
        let calendar = Calendar.current
        let dayCount = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 7

        var points: [ChartDataPoint] = []

        try await withThrowingTaskGroup(of: (Date, Double?).self) { group in
            for dayOffset in 0..<dayCount {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                group.addTask { [stepsService] in
                    let steps = try await stepsService.fetchSteps(for: date)
                    return (date, steps)
                }
            }

            for try await (date, steps) in group {
                if let steps {
                    points.append(ChartDataPoint(date: date, value: steps))
                }
            }
        }

        points.sort(by: { $0.date < $1.date })
        let aggregated = aggregateChartData(from: points, period: selectedPeriod)
        chartData = aggregated
        summaryStats = computeSummary(from: aggregated.map(\.value))
    }

    // MARK: - Exercise

    private func loadExerciseData() async throws {
        let range = selectedPeriod.dateRange
        let dayCount = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 7
        let workouts = try await workoutService.fetchWorkouts(days: dayCount)

        // Group by day and sum duration
        let calendar = Calendar.current
        var dailyMinutes: [Date: Double] = [:]
        for workout in workouts {
            let dayStart = calendar.startOfDay(for: workout.date)
            dailyMinutes[dayStart, default: 0] += workout.duration / 60.0
        }

        let points = dailyMinutes
            .map { ChartDataPoint(date: $0.key, value: $0.value) }
            .sorted(by: { $0.date < $1.date })

        let aggregated = aggregateChartData(from: points, period: selectedPeriod)
        chartData = aggregated
        summaryStats = computeSummary(from: aggregated.map(\.value))
    }

    // MARK: - Weight

    private func loadWeightData() async throws {
        let range = selectedPeriod.dateRange
        let dayCount = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 30
        let samples = try await bodyService.fetchWeight(days: dayCount)

        let points = samples
            .map { ChartDataPoint(date: $0.date, value: $0.value) }
            .sorted(by: { $0.date < $1.date })

        let aggregated = aggregateChartData(from: points, period: selectedPeriod)
        chartData = aggregated
        summaryStats = computeSummary(from: aggregated.map(\.value))
    }

    // MARK: - Aggregation

    private func aggregateChartData(from data: [ChartDataPoint], period: TimePeriod) -> [ChartDataPoint] {
        guard !data.isEmpty else { return [] }

        // For day/week, return raw data
        if period == .day || period == .week {
            return data
        }

        // For month+, aggregate by the period's aggregation unit
        let calendar = Calendar.current
        let unit = period.aggregationUnit

        var grouped: [Date: [Double]] = [:]
        for point in data {
            let key: Date
            if unit == .weekOfYear {
                // Group by start of week
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: point.date)
                key = calendar.date(from: components) ?? point.date
            } else {
                key = calendar.dateInterval(of: unit, for: point.date)?.start ?? point.date
            }
            grouped[key, default: []].append(point.value)
        }

        return grouped
            .map { date, values in
                let count = values.count
                guard count > 0 else { return ChartDataPoint(date: date, value: 0) }
                let avg = values.reduce(0, +) / Double(count)
                return ChartDataPoint(date: date, value: avg)
            }
            .sorted(by: { $0.date < $1.date })
    }

    // MARK: - Summary

    private func computeSummary(from values: [Double]) -> MetricSummary? {
        guard !values.isEmpty else { return nil }

        let avg = values.reduce(0, +) / Double(values.count)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        let sum = values.reduce(0, +)

        return MetricSummary(
            average: avg,
            min: minVal,
            max: maxVal,
            sum: sum,
            count: values.count,
            previousPeriodAverage: nil // TODO: Phase 6 — fetch previous period data
        )
    }

    // MARK: - Highlights

    private func buildHighlights() {
        guard !chartData.isEmpty else {
            highlights = []
            return
        }

        var result: [Highlight] = []

        // Highest value
        if let maxPoint = chartData.max(by: { $0.value < $1.value }) {
            result.append(Highlight(
                type: .high,
                value: maxPoint.value,
                date: maxPoint.date,
                label: "Highest"
            ))
        }

        // Lowest value
        if let minPoint = chartData.min(by: { $0.value < $1.value }) {
            result.append(Highlight(
                type: .low,
                value: minPoint.value,
                date: minPoint.date,
                label: "Lowest"
            ))
        }

        // Trend direction (simple: compare first half vs second half average)
        if chartData.count >= 4 {
            let mid = chartData.count / 2
            let firstHalf = chartData[..<mid].map(\.value)
            let secondHalf = chartData[mid...].map(\.value)
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

            if firstAvg > 0 {
                let changePercent = ((secondAvg - firstAvg) / firstAvg) * 100
                if abs(changePercent) >= 3 {
                    let direction = changePercent > 0 ? "Trending up" : "Trending down"
                    result.append(Highlight(
                        type: .trend,
                        value: changePercent,
                        date: Date(),
                        label: direction
                    ))
                }
            }
        }

        highlights = result
    }
}
