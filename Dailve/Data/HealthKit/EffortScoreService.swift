import HealthKit

/// Reads and writes Workout Effort Scores via HealthKit.
struct EffortScoreService: Sendable {
    private let manager: HealthKitManager

    init(manager: HealthKitManager) {
        self.manager = manager
    }

    /// Fetches the effort score (user-rated or estimated) for a given workout UUID.
    /// Returns the user-rated score if available, otherwise falls back to the estimated score.
    func fetchEffortScore(for workoutID: String) async throws -> Double? {
        guard let uuid = UUID(uuidString: workoutID) else { return nil }

        let workout = try await fetchWorkout(uuid: uuid)
        guard let workout else { return nil }

        // Try user-rated effort first
        if let userEffort = try await fetchEffort(
            type: HKQuantityType(.workoutEffortScore),
            workout: workout
        ) {
            return userEffort
        }

        // Fallback to estimated effort
        return try await fetchEffort(
            type: HKQuantityType(.estimatedWorkoutEffortScore),
            workout: workout
        )
    }

    /// Saves a user-rated effort score (1-10) and relates it to the given workout.
    func saveEffortScore(_ score: Double, forWorkoutID workoutID: String) async throws {
        guard score >= 1, score <= 10, score.isFinite else { return }
        guard let uuid = UUID(uuidString: workoutID) else { return }
        guard let workout = try await fetchWorkout(uuid: uuid) else { return }

        let store = await manager.healthStore
        let type = HKQuantityType(.workoutEffortScore)
        let quantity = HKQuantity(unit: .appleEffortScore(), doubleValue: score)
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: workout.startDate,
            end: workout.endDate
        )

        try await store.save(sample)
        try await store.relateWorkoutEffortSample(sample, with: workout, activity: nil)
    }

    // MARK: - Private

    private func fetchWorkout(uuid: UUID) async throws -> HKWorkout? {
        let predicate = HKQuery.predicateForObject(with: uuid)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        let results = try await manager.execute(descriptor)
        return results.first
    }

    private func fetchEffort(type: HKQuantityType, workout: HKWorkout) async throws -> Double? {
        let predicate = HKQuery.predicateForWorkoutEffortSamplesRelated(
            workout: workout,
            activity: nil
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        let samples = try await manager.execute(descriptor)
        guard let sample = samples.first else { return nil }
        let value = sample.quantity.doubleValue(for: .appleEffortScore())
        guard value >= 1, value <= 10, value.isFinite else { return nil }
        return value
    }
}
