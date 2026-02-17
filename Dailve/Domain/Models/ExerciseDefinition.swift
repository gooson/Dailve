import Foundation

struct ExerciseDefinition: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let localizedName: String
    let category: ExerciseCategory
    let inputType: ExerciseInputType
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: Equipment
    let metValue: Double
}
