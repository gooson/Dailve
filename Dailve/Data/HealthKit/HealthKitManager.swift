import HealthKit

actor HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private let readTypes: Set<HKSampleType> = [
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.stepCount),
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.distanceWalkingRunning)
    ]

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        try await store.requestAuthorization(
            toShare: [],
            read: readTypes.union([HKObjectType.workoutType()])
        )
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        store.authorizationStatus(for: type)
    }

    func execute<T>(_ query: T) async throws -> [T.Sample] where T: HKSampleQueryDescriptor {
        try await query.result(for: store)
    }

    func executeStatistics(_ query: HKStatisticsQueryDescriptor) async throws -> HKStatistics? {
        try await query.result(for: store)
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization was not granted"
        case .queryFailed(let message):
            return "HealthKit query failed: \(message)"
        }
    }
}
