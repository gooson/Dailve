import Foundation
import SwiftData

@Model
final class ExerciseRecord {
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

    init(
        date: Date = Date(),
        exerciseType: String = "",
        duration: TimeInterval = 0,
        calories: Double? = nil,
        distance: Double? = nil,
        memo: String = "",
        isFromHealthKit: Bool = false,
        healthKitWorkoutID: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.exerciseType = exerciseType
        self.duration = duration
        self.calories = calories
        self.distance = distance
        self.memo = memo
        self.isFromHealthKit = isFromHealthKit
        self.healthKitWorkoutID = healthKitWorkoutID
        self.createdAt = Date()
    }
}
