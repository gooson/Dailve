import SwiftUI
import OSLog

@Observable
@MainActor
final class DashboardViewModel {
    var conditionScore: ConditionScore?
    var baselineStatus: BaselineStatus?
    var sortedMetrics: [HealthMetric] = []
    var recentScores: [ConditionScore] = []
    var isLoading = false
    var errorMessage: String?

    private let healthKitManager: HealthKitManager
    private let hrvService: HRVQuerying
    private let sleepService: SleepQuerying
    private let workoutService: WorkoutQuerying
    private let stepsService: StepsQuerying
    private let scoreUseCase = CalculateConditionScoreUseCase()

    init(
        healthKitManager: HealthKitManager = .shared,
        hrvService: HRVQuerying? = nil,
        sleepService: SleepQuerying? = nil,
        workoutService: WorkoutQuerying? = nil,
        stepsService: StepsQuerying? = nil
    ) {
        self.healthKitManager = healthKitManager
        self.hrvService = hrvService ?? HRVQueryService(manager: healthKitManager)
        self.sleepService = sleepService ?? SleepQueryService(manager: healthKitManager)
        self.workoutService = workoutService ?? WorkoutQueryService(manager: healthKitManager)
        self.stepsService = stepsService ?? StepsQueryService(manager: healthKitManager)
    }

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await healthKitManager.requestAuthorization()
            async let hrvTask = fetchHRVData()
            async let sleepTask = fetchSleepData()
            async let exerciseTask = fetchExerciseData()
            async let stepsTask = fetchStepsData()

            let (hrvMetrics, sleepMetric, exerciseMetric, stepsMetric) = await (
                try hrvTask, try sleepTask, try exerciseTask, try stepsTask
            )

            var allMetrics: [HealthMetric] = []
            allMetrics.append(contentsOf: hrvMetrics)
            if let sleepMetric { allMetrics.append(sleepMetric) }
            if let exerciseMetric { allMetrics.append(exerciseMetric) }
            if let stepsMetric { allMetrics.append(stepsMetric) }

            // Sort once at assignment time instead of on every access
            sortedMetrics = allMetrics.sorted { $0.changeSignificance > $1.changeSignificance }
        } catch {
            AppLogger.ui.error("Dashboard load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private

    private func fetchHRVData() async throws -> [HealthMetric] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        async let samplesTask = hrvService.fetchHRVSamples(days: 7)
        async let todayRHRTask = hrvService.fetchRestingHeartRate(for: today)
        async let yesterdayRHRTask = hrvService.fetchRestingHeartRate(for: yesterday)

        let (samples, todayRHR, yesterdayRHR) = try await (samplesTask, todayRHRTask, yesterdayRHRTask)

        let input = CalculateConditionScoreUseCase.Input(
            hrvSamples: samples,
            todayRHR: todayRHR,
            yesterdayRHR: yesterdayRHR
        )
        let output = scoreUseCase.execute(input: input)
        conditionScore = output.score
        baselineStatus = output.baselineStatus

        // Build 7-day score history — compute daily averages once, reuse
        recentScores = buildRecentScores(from: samples)

        var metrics: [HealthMetric] = []

        // Latest HRV
        if let latest = samples.first {
            let previousAvg = samples.dropFirst().prefix(7).map(\.value)
            let avgPrev = previousAvg.isEmpty ? nil : previousAvg.reduce(0, +) / Double(previousAvg.count)
            metrics.append(HealthMetric(
                id: "hrv",
                name: "HRV",
                value: latest.value,
                unit: "ms",
                change: avgPrev.map { latest.value - $0 },
                date: latest.date,
                category: .hrv
            ))
        }

        // RHR
        if let rhr = todayRHR {
            metrics.append(HealthMetric(
                id: "rhr",
                name: "RHR",
                value: rhr,
                unit: "bpm",
                change: yesterdayRHR.map { rhr - $0 },
                date: today,
                category: .rhr
            ))
        }

        return metrics
    }

    private let sleepScoreUseCase = CalculateSleepScoreUseCase()

    private func fetchSleepData() async throws -> HealthMetric? {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        async let todayTask = sleepService.fetchSleepStages(for: today)
        async let yesterdayTask = sleepService.fetchSleepStages(for: yesterday)

        let (stages, yesterdayStages) = try await (todayTask, yesterdayTask)
        guard !stages.isEmpty else { return nil }

        let todayOutput = sleepScoreUseCase.execute(input: .init(stages: stages))
        let yesterdayOutput = sleepScoreUseCase.execute(input: .init(stages: yesterdayStages))

        let change: Double? = yesterdayOutput.totalMinutes > 0
            ? todayOutput.totalMinutes - yesterdayOutput.totalMinutes
            : nil

        return HealthMetric(
            id: "sleep",
            name: "Sleep",
            value: todayOutput.totalMinutes,
            unit: "min",
            change: change,
            date: today,
            category: .sleep
        )
    }

    private func fetchExerciseData() async throws -> HealthMetric? {
        let workouts = try await workoutService.fetchWorkouts(days: 1)
        guard !workouts.isEmpty else { return nil }

        let totalMinutes = workouts.map(\.duration).reduce(0, +) / 60.0

        return HealthMetric(
            id: "exercise",
            name: "Exercise",
            value: totalMinutes,
            unit: "min",
            change: nil,
            date: Date(),
            category: .exercise
        )
    }

    private func fetchStepsData() async throws -> HealthMetric? {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        async let todayTask = stepsService.fetchSteps(for: today)
        async let yesterdayTask = stepsService.fetchSteps(for: yesterday)

        let (steps, yesterdaySteps) = try await (todayTask, yesterdayTask)
        guard let steps else { return nil }

        let change: Double? = yesterdaySteps.map { steps - $0 }

        return HealthMetric(
            id: "steps",
            name: "Steps",
            value: steps,
            unit: "",
            change: change,
            date: today,
            category: .steps
        )
    }

    private func buildRecentScores(from samples: [HRVSample]) -> [ConditionScore] {
        let calendar = Calendar.current

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) else {
                return nil
            }

            let relevantSamples = samples.filter { $0.date < nextDay }
            let input = CalculateConditionScoreUseCase.Input(
                hrvSamples: relevantSamples,
                todayRHR: nil,
                yesterdayRHR: nil
            )
            guard let score = scoreUseCase.execute(input: input).score else { return nil }
            return ConditionScore(score: score.score, date: calendar.startOfDay(for: date))
        }
    }
}
