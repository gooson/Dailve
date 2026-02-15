import Foundation
import Observation

@Observable
@MainActor
final class SleepViewModel {
    var todayStages: [SleepStage] = []
    var weeklyData: [DailySleep] = []
    var isLoading = false
    var errorMessage: String?
    var latestSleepDate: Date?

    private let sleepService: SleepQuerying
    private let sleepScoreUseCase = CalculateSleepScoreUseCase()

    init(sleepService: SleepQuerying? = nil) {
        self.sleepService = sleepService ?? SleepQueryService(manager: .shared)
    }

    private var todayOutput: CalculateSleepScoreUseCase.Output {
        sleepScoreUseCase.execute(input: .init(stages: todayStages))
    }

    var totalSleepMinutes: Double { todayOutput.totalMinutes }
    var sleepEfficiency: Double { todayOutput.efficiency }
    var sleepScore: Int { todayOutput.score }

    var isShowingHistoricalData: Bool {
        guard let latestSleepDate else { return false }
        return !Calendar.current.isDateInToday(latestSleepDate)
    }

    var stageBreakdown: [(stage: SleepStage.Stage, minutes: Double)] {
        let stages: [SleepStage.Stage] = [.deep, .core, .rem, .awake]
        return stages.map { stage in
            let minutes = todayStages
                .filter { $0.stage == stage }
                .map(\.duration)
                .reduce(0, +) / 60.0
            return (stage: stage, minutes: minutes)
        }
    }

    func loadData() async {
        isLoading = true
        do {
            let calendar = Calendar.current
            let today = Date()

            // Fetch today's sleep data
            let fetchedStages = try await sleepService.fetchSleepStages(for: today)

            // Fallback: if today has no sleep data, find most recent
            if !fetchedStages.isEmpty {
                todayStages = fetchedStages
                latestSleepDate = today
            } else if let latest = try await sleepService.fetchLatestSleepStages(withinDays: 7) {
                todayStages = latest.stages
                latestSleepDate = latest.date
            } else {
                todayStages = []
                latestSleepDate = nil
            }

            weeklyData = try await withThrowingTaskGroup(of: DailySleep?.self) { group in
                for dayOffset in 0..<7 {
                    group.addTask { [sleepService] in
                        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
                        let stages = try await sleepService.fetchSleepStages(for: date)
                        let totalMinutes = stages.filter { $0.stage != .awake }.map(\.duration).reduce(0, +) / 60.0
                        return DailySleep(date: date, totalMinutes: totalMinutes)
                    }
                }
                var results: [DailySleep] = []
                for try await result in group {
                    if let result { results.append(result) }
                }
                return results.sorted { $0.date < $1.date }
            }
        } catch {
            AppLogger.ui.error("Sleep data load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct DailySleep: Identifiable {
    let id = UUID()
    let date: Date
    let totalMinutes: Double
}
