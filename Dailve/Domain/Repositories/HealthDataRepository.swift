import Foundation

protocol HealthDataRepository: Sendable {
    func requestAuthorization() async throws
    func fetchHRVSamples(days: Int) async throws -> [HRVSample]
    func fetchRestingHeartRate(for date: Date) async throws -> Double?
    func fetchSleepStages(for date: Date) async throws -> [SleepStage]
    func fetchWorkouts(days: Int) async throws -> [WorkoutSummary]
    func fetchSteps(for date: Date) async throws -> Double?
}

struct WorkoutSummary: Identifiable, Sendable {
    let id: String
    let type: String
    let duration: TimeInterval
    let calories: Double?
    let distance: Double?
    let date: Date
}
