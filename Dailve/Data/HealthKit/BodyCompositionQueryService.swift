import HealthKit

struct BodyCompositionSample: Sendable {
    let value: Double
    let date: Date
}

protocol BodyCompositionQuerying: Sendable {
    func fetchWeight(days: Int) async throws -> [BodyCompositionSample]
    func fetchBodyFat(days: Int) async throws -> [BodyCompositionSample]
    func fetchLeanBodyMass(days: Int) async throws -> [BodyCompositionSample]
    func fetchWeight(start: Date, end: Date) async throws -> [BodyCompositionSample]
}

struct BodyCompositionQueryService: BodyCompositionQuerying, Sendable {
    private let manager: HealthKitManager

    init(manager: HealthKitManager) {
        self.manager = manager
    }

    func fetchWeight(days: Int) async throws -> [BodyCompositionSample] {
        try await fetchQuantitySamples(
            type: HKQuantityType(.bodyMass),
            unit: .gramUnit(with: .kilo),
            days: days
        )
    }

    func fetchBodyFat(days: Int) async throws -> [BodyCompositionSample] {
        try await fetchQuantitySamples(
            type: HKQuantityType(.bodyFatPercentage),
            unit: .percent(),
            days: days,
            valueTransform: { $0 * 100 } // HealthKit stores as 0.0-1.0
        )
    }

    func fetchLeanBodyMass(days: Int) async throws -> [BodyCompositionSample] {
        try await fetchQuantitySamples(
            type: HKQuantityType(.leanBodyMass),
            unit: .gramUnit(with: .kilo),
            days: days
        )
    }

    func fetchWeight(start: Date, end: Date) async throws -> [BodyCompositionSample] {
        try await fetchQuantitySamples(
            type: HKQuantityType(.bodyMass),
            unit: .gramUnit(with: .kilo),
            start: start,
            end: end
        )
    }

    // MARK: - Private

    private func fetchQuantitySamples(
        type: HKQuantityType,
        unit: HKUnit,
        days: Int,
        valueTransform: @Sendable (Double) -> Double = { $0 }
    ) async throws -> [BodyCompositionSample] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        return try await fetchQuantitySamples(
            type: type, unit: unit, start: startDate, end: endDate, valueTransform: valueTransform
        )
    }

    private func fetchQuantitySamples(
        type: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date,
        valueTransform: @Sendable (Double) -> Double = { $0 }
    ) async throws -> [BodyCompositionSample] {
        try await manager.ensureNotDenied(for: type)

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        let samples = try await manager.execute(descriptor)

        return samples.map { sample in
            BodyCompositionSample(
                value: valueTransform(sample.quantity.doubleValue(for: unit)),
                date: sample.startDate
            )
        }
    }
}
