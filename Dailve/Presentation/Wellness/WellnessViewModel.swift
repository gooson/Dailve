import Foundation
import Observation

// MARK: - VitalCardData DTO

struct VitalCardData: Identifiable, Hashable, Sendable {
    let id: String
    let category: HealthMetric.Category
    let title: String
    let value: String
    let unit: String
    let change: String?
    let changeIsPositive: Bool?
    let sparklineData: [Double]
    let metric: HealthMetric
    let lastUpdated: Date
    let isStale: Bool

    static func == (lhs: VitalCardData, rhs: VitalCardData) -> Bool {
        lhs.id == rhs.id && lhs.value == rhs.value && lhs.lastUpdated == rhs.lastUpdated
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(value)
        hasher.combine(lastUpdated)
    }
}

// MARK: - WellnessViewModel

@Observable
@MainActor
final class WellnessViewModel {
    // MARK: - Published State

    var wellnessScore: WellnessScore?
    var vitalCards: [VitalCardData] = []
    var isLoading = false
    var partialFailureMessage: String?

    // Sleep sub-state (consumed by hero card)
    var sleepScore: Int?
    var conditionScore: Int?
    var bodyScore: Int?

    // MARK: - Dependencies

    private let sleepService: SleepQuerying
    private let bodyService: BodyCompositionQuerying
    private let hrvService: HRVQuerying
    private let vitalsService: VitalsQuerying
    private let wellnessScoreUseCase: WellnessScoreCalculating
    private let sleepScoreUseCase: SleepScoreCalculating
    private let conditionScoreUseCase: ConditionScoreCalculating

    // MARK: - Internal State

    private var loadTask: Task<Void, Never>?
    private static let staleDays = 3

    // MARK: - Init

    init(
        sleepService: SleepQuerying? = nil,
        bodyService: BodyCompositionQuerying? = nil,
        hrvService: HRVQuerying? = nil,
        vitalsService: VitalsQuerying? = nil,
        wellnessScoreUseCase: WellnessScoreCalculating? = nil,
        sleepScoreUseCase: SleepScoreCalculating? = nil,
        conditionScoreUseCase: ConditionScoreCalculating? = nil
    ) {
        let manager = HealthKitManager.shared
        self.sleepService = sleepService ?? SleepQueryService(manager: manager)
        self.bodyService = bodyService ?? BodyCompositionQueryService(manager: manager)
        self.hrvService = hrvService ?? HRVQueryService(manager: manager)
        self.vitalsService = vitalsService ?? VitalsQueryService(manager: manager)
        self.wellnessScoreUseCase = wellnessScoreUseCase ?? CalculateWellnessScoreUseCase()
        self.sleepScoreUseCase = sleepScoreUseCase ?? CalculateSleepScoreUseCase()
        self.conditionScoreUseCase = conditionScoreUseCase ?? CalculateConditionScoreUseCase()
    }

    // MARK: - Public

    func loadData() {
        // Cancel-before-spawn (Correction #16)
        loadTask?.cancel()
        loadTask = Task { await performLoad() }
    }

    /// Async entry point for `.refreshable` — awaits load completion so spinner persists.
    func performRefresh() async {
        loadTask?.cancel()
        let task = Task { await performLoad() }
        loadTask = task
        await task.value
    }

    // MARK: - Loading

    private func performLoad() async {
        isLoading = true
        partialFailureMessage = nil

        // Collect results using TaskGroup for 10+ parallel queries (Correction #5)
        let results = await fetchAllData()

        guard !Task.isCancelled else { // Correction #17
            isLoading = false
            return
        }

        // Build cards from results
        var cards: [VitalCardData] = []
        var failureCount = 0
        let totalSources = 8 // sleep, condition, weight, spo2, respRate, vo2Max, hrRecovery, wristTemp

        // --- Sleep ---
        if let sleep = results.sleep {
            sleepScore = sleep.score
            let sparkline = results.sleepWeekly.map(\.totalMinutes)
            cards.append(buildCard(
                category: .sleep,
                title: "Sleep",
                rawValue: sleep.totalMinutes,
                formattedValue: Self.formatSleepMinutes(sleep.totalMinutes),
                unit: "",
                change: nil,
                sparkline: sparkline,
                date: results.sleepDate ?? Date(),
                isHistorical: results.sleepIsHistorical
            ))
        } else {
            sleepScore = nil
            failureCount += 1
        }

        // --- Condition (HRV/RHR) ---
        if let condition = results.condition {
            conditionScore = condition.score
        } else {
            conditionScore = nil
            failureCount += 1
        }

        // --- Body Composition (Weight) ---
        if let weight = results.latestWeight {
            let change = results.weightWeekAgo.map { weight.value - $0 }
            let sparkline = results.weightHistory.map(\.value)
            cards.append(buildCard(
                category: .weight,
                title: "Weight",
                rawValue: weight.value,
                formattedValue: String(format: "%.1f", weight.value),
                unit: "kg",
                change: change,
                sparkline: sparkline,
                date: weight.date,
                isHistorical: false
            ))
        } else {
            failureCount += 1
        }

        // --- BMI ---
        if let bmi = results.latestBMI {
            cards.append(buildCard(
                category: .bmi,
                title: "BMI",
                rawValue: bmi.value,
                formattedValue: String(format: "%.1f", bmi.value),
                unit: "",
                change: nil,
                sparkline: [],
                date: bmi.date,
                isHistorical: false
            ))
        }

        // --- SpO2 ---
        if let spo2 = results.latestSpO2 {
            let displayValue = spo2.value * 100
            let sparkline = results.spo2History.map { $0.value * 100 }
            cards.append(buildCard(
                category: .spo2,
                title: "Blood Oxygen",
                rawValue: displayValue,
                formattedValue: String(format: "%.0f", displayValue),
                unit: "%",
                change: nil,
                sparkline: sparkline,
                date: spo2.date,
                isHistorical: false
            ))
        } else {
            failureCount += 1
        }

        // --- Respiratory Rate ---
        if let resp = results.latestRespRate {
            let sparkline = results.respRateHistory.map(\.value)
            cards.append(buildCard(
                category: .respiratoryRate,
                title: "Respiratory Rate",
                rawValue: resp.value,
                formattedValue: String(format: "%.0f", resp.value),
                unit: "breaths/min",
                change: nil,
                sparkline: sparkline,
                date: resp.date,
                isHistorical: false
            ))
        } else {
            failureCount += 1
        }

        // --- VO2 Max ---
        if let vo2 = results.latestVO2Max {
            let sparkline = results.vo2MaxHistory.map(\.value)
            cards.append(buildCard(
                category: .vo2Max,
                title: "VO2 Max",
                rawValue: vo2.value,
                formattedValue: String(format: "%.1f", vo2.value),
                unit: "ml/kg/min",
                change: nil,
                sparkline: sparkline,
                date: vo2.date,
                isHistorical: false
            ))
        } else {
            failureCount += 1
        }

        // --- HR Recovery ---
        if let hrr = results.latestHRRecovery {
            let sparkline = results.hrRecoveryHistory.map(\.value)
            cards.append(buildCard(
                category: .heartRateRecovery,
                title: "HR Recovery",
                rawValue: hrr.value,
                formattedValue: String(format: "%.0f", hrr.value),
                unit: "bpm",
                change: nil,
                sparkline: sparkline,
                date: hrr.date,
                isHistorical: false
            ))
        } else {
            failureCount += 1
        }

        // --- Wrist Temperature ---
        if let temp = results.latestWristTemp, let baseline = results.wristTempBaseline {
            let delta = temp.value - baseline
            let sparkline = results.wristTempHistory.map { $0.value - baseline }
            cards.append(buildCard(
                category: .wristTemperature,
                title: "Wrist Temp",
                rawValue: delta,
                formattedValue: String(format: "%+.1f", delta),
                unit: "°C",
                change: nil,
                sparkline: sparkline,
                date: temp.date,
                isHistorical: false
            ))
        } else {
            failureCount += 1
        }

        guard !Task.isCancelled else {
            isLoading = false
            return
        }

        // --- Body Trend for Wellness Score ---
        let bodyTrend = buildBodyTrend(results: results)
        bodyScore = bodyTrend?.score

        // --- Compute Wellness Score ---
        wellnessScore = wellnessScoreUseCase.execute(input: .init(
            sleepScore: sleepScore,
            conditionScore: conditionScore,
            bodyTrend: bodyTrend
        ))

        // Dynamic sort: cards with data sorted by recency (most recent first)
        vitalCards = cards.sorted { a, b in
            if a.isStale != b.isStale { return !a.isStale }
            return a.lastUpdated > b.lastUpdated
        }

        // Partial failure message (Correction #25)
        if failureCount > 0, failureCount < totalSources {
            partialFailureMessage = "Some data could not be loaded (\(failureCount) of \(totalSources) sources)"
        }

        isLoading = false
    }

    // MARK: - Parallel Fetch

    private struct FetchResults: Sendable {
        // Sleep
        var sleep: CalculateSleepScoreUseCase.Output?
        var sleepDate: Date?
        var sleepIsHistorical: Bool = false
        var sleepWeekly: [DailySleep] = []
        // Condition
        var condition: ConditionScore?
        // Body
        var latestWeight: (value: Double, date: Date)?
        var weightWeekAgo: Double?
        var weightHistory: [BodyCompositionSample] = []
        var latestBMI: (value: Double, date: Date)?
        var latestBodyFat: (value: Double, date: Date)?
        var bodyFatWeekAgo: Double?
        // Vitals
        var latestSpO2: VitalSample?
        var spo2History: [VitalSample] = []
        var latestRespRate: VitalSample?
        var respRateHistory: [VitalSample] = []
        var latestVO2Max: VitalSample?
        var vo2MaxHistory: [VitalSample] = []
        var latestHRRecovery: VitalSample?
        var hrRecoveryHistory: [VitalSample] = []
        var latestWristTemp: VitalSample?
        var wristTempBaseline: Double?
        var wristTempHistory: [VitalSample] = []
    }

    private enum FetchKey: Sendable {
        case sleep
        case sleepWeekly
        case condition
        case weight
        case weightHistory
        case bmi
        case bodyFat
        case spo2
        case spo2History
        case respRate
        case respRateHistory
        case vo2Max
        case vo2MaxHistory
        case hrRecovery
        case hrRecoveryHistory
        case wristTemp
        case wristTempBaseline
        case wristTempHistory
    }

    private enum FetchValue: Sendable {
        case sleepResult(output: CalculateSleepScoreUseCase.Output?, date: Date?, isHistorical: Bool)
        case sleepWeekly([DailySleep])
        case conditionResult(ConditionScore?)
        case weightResult(value: Double, date: Date)
        case weightHistoryResult([BodyCompositionSample])
        case bmiResult(value: Double, date: Date)
        case bodyFatResult(value: Double, date: Date)
        case vitalSample(VitalSample?)
        case vitalHistory([VitalSample])
        case baselineResult(Double?)
        case empty
    }

    private func fetchAllData() async -> FetchResults {
        var results = FetchResults()

        await withTaskGroup(of: (FetchKey, FetchValue).self) { [
            sleepService, bodyService, hrvService, vitalsService,
            sleepScoreUseCase, conditionScoreUseCase
        ] group in

            // --- Sleep ---
            group.addTask {
                guard !Task.isCancelled else { return (.sleep, .empty) }
                do {
                    let today = Date()
                    var stages = try await sleepService.fetchSleepStages(for: today)
                    var sleepDate: Date? = today
                    var isHistorical = false

                    if stages.isEmpty {
                        if let latest = try await sleepService.fetchLatestSleepStages(withinDays: 7) {
                            stages = latest.stages
                            sleepDate = latest.date
                            isHistorical = true
                        } else {
                            sleepDate = nil
                        }
                    }

                    let output = stages.isEmpty ? nil : sleepScoreUseCase.execute(input: .init(stages: stages))
                    return (.sleep, .sleepResult(output: output, date: sleepDate, isHistorical: isHistorical))
                } catch {
                    return (.sleep, .sleepResult(output: nil, date: nil, isHistorical: false))
                }
            }

            // --- Sleep Weekly ---
            group.addTask {
                guard !Task.isCancelled else { return (.sleepWeekly, .empty) }
                do {
                    let calendar = Calendar.current
                    let today = Date()
                    var weekly: [DailySleep] = []

                    // Use TaskGroup for parallel daily queries
                    let dailyData = try await withThrowingTaskGroup(of: DailySleep?.self) { inner in
                        for dayOffset in 0..<7 {
                            inner.addTask { [sleepService] in
                                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
                                let stages = try await sleepService.fetchSleepStages(for: date)
                                let totalMinutes = stages.filter { $0.stage != .awake }.map(\.duration).reduce(0, +) / 60.0
                                return DailySleep(date: date, totalMinutes: totalMinutes)
                            }
                        }
                        var collected: [DailySleep] = []
                        for try await item in inner {
                            if let item { collected.append(item) }
                        }
                        return collected
                    }
                    weekly = dailyData.sorted { $0.date < $1.date }
                    return (.sleepWeekly, .sleepWeekly(weekly))
                } catch {
                    return (.sleepWeekly, .sleepWeekly([]))
                }
            }

            // --- Condition (HRV + RHR) ---
            group.addTask {
                guard !Task.isCancelled else { return (.condition, .empty) }
                do {
                    let hrvSamples = try await hrvService.fetchHRVSamples(days: 14)
                    let todayRHR = try await hrvService.fetchRestingHeartRate(for: Date())
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    let yesterdayRHR = try await hrvService.fetchRestingHeartRate(for: yesterday)

                    let output = conditionScoreUseCase.execute(input: .init(
                        hrvSamples: hrvSamples,
                        todayRHR: todayRHR,
                        yesterdayRHR: yesterdayRHR
                    ))
                    return (.condition, .conditionResult(output.score))
                } catch {
                    return (.condition, .conditionResult(nil))
                }
            }

            // --- Weight ---
            group.addTask {
                guard !Task.isCancelled else { return (.weight, .empty) }
                do {
                    if let w = try await bodyService.fetchLatestWeight(withinDays: 30) {
                        return (.weight, .weightResult(value: w.value, date: w.date))
                    }
                    return (.weight, .empty)
                } catch {
                    return (.weight, .empty)
                }
            }

            // --- Weight History (sparkline) ---
            group.addTask {
                guard !Task.isCancelled else { return (.weightHistory, .empty) }
                do {
                    let history = try await bodyService.fetchWeight(days: 7)
                    return (.weightHistory, .weightHistoryResult(history))
                } catch {
                    return (.weightHistory, .weightHistoryResult([]))
                }
            }

            // --- BMI ---
            group.addTask {
                guard !Task.isCancelled else { return (.bmi, .empty) }
                do {
                    if let b = try await bodyService.fetchLatestBMI(withinDays: 30) {
                        return (.bmi, .bmiResult(value: b.value, date: b.date))
                    }
                    return (.bmi, .empty)
                } catch {
                    return (.bmi, .empty)
                }
            }

            // --- Body Fat ---
            group.addTask {
                guard !Task.isCancelled else { return (.bodyFat, .empty) }
                do {
                    let bfHistory = try await bodyService.fetchBodyFat(days: 7)
                    if let latest = bfHistory.last {
                        return (.bodyFat, .bodyFatResult(value: latest.value, date: latest.date))
                    }
                    return (.bodyFat, .empty)
                } catch {
                    return (.bodyFat, .empty)
                }
            }

            // --- SpO2 ---
            group.addTask {
                guard !Task.isCancelled else { return (.spo2, .empty) }
                do {
                    let sample = try await vitalsService.fetchLatestSpO2(withinDays: 7)
                    return (.spo2, .vitalSample(sample))
                } catch {
                    return (.spo2, .vitalSample(nil))
                }
            }

            // --- SpO2 History ---
            group.addTask {
                guard !Task.isCancelled else { return (.spo2History, .empty) }
                do {
                    let history = try await vitalsService.fetchSpO2Collection(days: 7)
                    return (.spo2History, .vitalHistory(history))
                } catch {
                    return (.spo2History, .vitalHistory([]))
                }
            }

            // --- Respiratory Rate ---
            group.addTask {
                guard !Task.isCancelled else { return (.respRate, .empty) }
                do {
                    let sample = try await vitalsService.fetchLatestRespiratoryRate(withinDays: 7)
                    return (.respRate, .vitalSample(sample))
                } catch {
                    return (.respRate, .vitalSample(nil))
                }
            }

            // --- Respiratory Rate History ---
            group.addTask {
                guard !Task.isCancelled else { return (.respRateHistory, .empty) }
                do {
                    let history = try await vitalsService.fetchRespiratoryRateCollection(days: 7)
                    return (.respRateHistory, .vitalHistory(history))
                } catch {
                    return (.respRateHistory, .vitalHistory([]))
                }
            }

            // --- VO2 Max ---
            group.addTask {
                guard !Task.isCancelled else { return (.vo2Max, .empty) }
                do {
                    let sample = try await vitalsService.fetchLatestVO2Max(withinDays: 180)
                    return (.vo2Max, .vitalSample(sample))
                } catch {
                    return (.vo2Max, .vitalSample(nil))
                }
            }

            // --- VO2 Max History ---
            group.addTask {
                guard !Task.isCancelled else { return (.vo2MaxHistory, .empty) }
                do {
                    let history = try await vitalsService.fetchVO2MaxHistory(days: 90)
                    return (.vo2MaxHistory, .vitalHistory(history))
                } catch {
                    return (.vo2MaxHistory, .vitalHistory([]))
                }
            }

            // --- HR Recovery ---
            group.addTask {
                guard !Task.isCancelled else { return (.hrRecovery, .empty) }
                do {
                    let sample = try await vitalsService.fetchLatestHeartRateRecovery(withinDays: 30)
                    return (.hrRecovery, .vitalSample(sample))
                } catch {
                    return (.hrRecovery, .vitalSample(nil))
                }
            }

            // --- HR Recovery History ---
            group.addTask {
                guard !Task.isCancelled else { return (.hrRecoveryHistory, .empty) }
                do {
                    let history = try await vitalsService.fetchHeartRateRecoveryHistory(days: 90)
                    return (.hrRecoveryHistory, .vitalHistory(history))
                } catch {
                    return (.hrRecoveryHistory, .vitalHistory([]))
                }
            }

            // --- Wrist Temperature ---
            group.addTask {
                guard !Task.isCancelled else { return (.wristTemp, .empty) }
                do {
                    let sample = try await vitalsService.fetchLatestWristTemperature(withinDays: 7)
                    return (.wristTemp, .vitalSample(sample))
                } catch {
                    return (.wristTemp, .vitalSample(nil))
                }
            }

            // --- Wrist Temperature Baseline ---
            group.addTask {
                guard !Task.isCancelled else { return (.wristTempBaseline, .empty) }
                do {
                    let baseline = try await vitalsService.fetchWristTemperatureBaseline(days: 14)
                    return (.wristTempBaseline, .baselineResult(baseline))
                } catch {
                    return (.wristTempBaseline, .baselineResult(nil))
                }
            }

            // --- Wrist Temperature History ---
            group.addTask {
                guard !Task.isCancelled else { return (.wristTempHistory, .empty) }
                do {
                    let history = try await vitalsService.fetchWristTemperatureCollection(days: 7)
                    return (.wristTempHistory, .vitalHistory(history))
                } catch {
                    return (.wristTempHistory, .vitalHistory([]))
                }
            }

            // Collect all results
            for await (key, value) in group {
                switch (key, value) {
                case let (.sleep, .sleepResult(output, date, isHistorical)):
                    results.sleep = output
                    results.sleepDate = date
                    results.sleepIsHistorical = isHistorical
                case let (.sleepWeekly, .sleepWeekly(weekly)):
                    results.sleepWeekly = weekly
                case let (.condition, .conditionResult(score)):
                    results.condition = score
                case let (.weight, .weightResult(value, date)):
                    results.latestWeight = (value, date)
                case let (.weightHistory, .weightHistoryResult(history)):
                    results.weightHistory = history
                case let (.bmi, .bmiResult(value, date)):
                    results.latestBMI = (value, date)
                case let (.bodyFat, .bodyFatResult(value, date)):
                    results.latestBodyFat = (value, date)
                case let (.spo2, .vitalSample(sample)):
                    results.latestSpO2 = sample
                case let (.spo2History, .vitalHistory(history)):
                    results.spo2History = history
                case let (.respRate, .vitalSample(sample)):
                    results.latestRespRate = sample
                case let (.respRateHistory, .vitalHistory(history)):
                    results.respRateHistory = history
                case let (.vo2Max, .vitalSample(sample)):
                    results.latestVO2Max = sample
                case let (.vo2MaxHistory, .vitalHistory(history)):
                    results.vo2MaxHistory = history
                case let (.hrRecovery, .vitalSample(sample)):
                    results.latestHRRecovery = sample
                case let (.hrRecoveryHistory, .vitalHistory(history)):
                    results.hrRecoveryHistory = history
                case let (.wristTemp, .vitalSample(sample)):
                    results.latestWristTemp = sample
                case let (.wristTempBaseline, .baselineResult(baseline)):
                    results.wristTempBaseline = baseline
                case let (.wristTempHistory, .vitalHistory(history)):
                    results.wristTempHistory = history
                default:
                    break
                }
            }
        }

        // Compute weight week-ago for change calculation
        if let latestWeight = results.latestWeight {
            let weekAgoWeight = results.weightHistory
                .filter { Calendar.current.dateComponents([.day], from: $0.date, to: latestWeight.date).day ?? 0 >= 6 }
                .last
            results.weightWeekAgo = weekAgoWeight?.value
        }

        // TODO: Body fat weekly delta requires separate history fetch — bodyFatChange is always nil for now

        return results
    }

    // MARK: - Helpers

    private func buildCard(
        category: HealthMetric.Category,
        title: String,
        rawValue: Double,
        formattedValue: String,
        unit: String,
        change: Double?,
        sparkline: [Double],
        date: Date,
        isHistorical: Bool
    ) -> VitalCardData {
        let daysSince = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        let isStale = daysSince >= Self.staleDays

        var changeStr: String?
        var changePositive: Bool?
        if let change, !isHistorical { // Correction #24: skip change for historical data
            let absChange = abs(change)
            if absChange >= 0.1 {
                changeStr = String(format: "%@%.1f", change >= 0 ? "+" : "", change)
                changePositive = change > 0
            }
        }

        let metric = HealthMetric(
            id: category.rawValue,
            name: title,
            value: rawValue,
            unit: unit,
            change: isHistorical ? nil : change,
            date: date,
            category: category,
            isHistorical: isHistorical
        )

        return VitalCardData(
            id: category.rawValue,
            category: category,
            title: title,
            value: formattedValue,
            unit: unit,
            change: changeStr,
            changeIsPositive: changePositive,
            sparklineData: sparkline,
            metric: metric,
            lastUpdated: date,
            isStale: isStale
        )
    }

    private func buildBodyTrend(results: FetchResults) -> CalculateWellnessScoreUseCase.BodyTrend? {
        let weightChange: Double?
        if let current = results.latestWeight, let weekAgo = results.weightWeekAgo {
            weightChange = current.value - weekAgo
        } else {
            weightChange = nil
        }

        let bodyFatChange: Double?
        if let current = results.latestBodyFat {
            // Simplified: use available data, nil if insufficient
            bodyFatChange = nil // Body fat weekly comparison requires separate fetch
        } else {
            bodyFatChange = nil
        }

        guard weightChange != nil || bodyFatChange != nil else { return nil }

        return CalculateWellnessScoreUseCase.BodyTrend(
            weightChange: weightChange,
            bodyFatChange: bodyFatChange
        )
    }

    private static func formatSleepMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}
