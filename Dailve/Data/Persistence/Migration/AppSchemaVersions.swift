import Foundation
import SwiftData

// MARK: - Schema V1 (Original)

enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [V1ExerciseRecord.self, V1BodyCompositionRecord.self]
    }

    @Model
    final class V1ExerciseRecord {
        var id: UUID = UUID()
        var date: Date = Date()
        var exerciseType: String = ""
        var duration: TimeInterval = 0
        var calories: Double?
        var distance: Double?
        var memo: String = ""
        var isFromHealthKit: Bool = false
        var healthKitWorkoutID: String?
        var createdAt: Date = Date()

        init() {}
    }

    @Model
    final class V1BodyCompositionRecord {
        var id: UUID = UUID()
        var date: Date = Date()
        var weight: Double?
        var bodyFatPercentage: Double?
        var muscleMass: Double?
        var memo: String = ""
        var createdAt: Date = Date()

        init() {}
    }
}

// MARK: - Schema V2 (Activity Redesign)

enum AppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ExerciseRecord.self, BodyCompositionRecord.self, WorkoutSet.self]
    }
}

// MARK: - Migration Plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV2.self
    )
}
