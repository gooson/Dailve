import Foundation
import HealthKit

enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case strength
    case cardio
    case hiit
    case flexibility
    case bodyweight

    /// Default HKWorkoutActivityType for this category.
    var hkWorkoutActivityType: HKWorkoutActivityType {
        switch self {
        case .strength:    .traditionalStrengthTraining
        case .cardio:      .other
        case .hiit:        .highIntensityIntervalTraining
        case .flexibility: .flexibility
        case .bodyweight:  .functionalStrengthTraining
        }
    }

    /// Resolve HKWorkoutActivityType using exercise name first, then category fallback.
    static func hkActivityType(category: ExerciseCategory, exerciseName: String) -> HKWorkoutActivityType {
        switch exerciseName.lowercased() {
        case let n where n.contains("running") || n.contains("run"):  return .running
        case let n where n.contains("walking") || n.contains("walk"): return .walking
        case let n where n.contains("cycling") || n.contains("bike"): return .cycling
        case let n where n.contains("swimming") || n.contains("swim"): return .swimming
        case let n where n.contains("hiking") || n.contains("hike"):  return .hiking
        case let n where n.contains("yoga"):      return .yoga
        case let n where n.contains("rowing") || n.contains("row"):   return .rowing
        case let n where n.contains("elliptical"): return .elliptical
        case let n where n.contains("pilates"):   return .pilates
        case let n where n.contains("dance") || n.contains("dancing"): return .socialDance
        case let n where n.contains("core"):      return .coreTraining
        default: return category.hkWorkoutActivityType
        }
    }
}

enum ExerciseInputType: String, Codable, Sendable {
    /// Strength: sets x reps x weight (kg)
    case setsRepsWeight
    /// Bodyweight: sets x reps (weight optional)
    case setsReps
    /// Cardio: duration + distance
    case durationDistance
    /// Flexibility: duration + intensity (1-10)
    case durationIntensity
    /// HIIT: rounds x time + rest
    case roundsBased
}

enum SetType: String, Codable, Sendable {
    case warmup
    case working
    case drop
    case failure
}

enum CalorieSource: String, Codable, Sendable {
    case healthKit
    case met
    case manual
}
