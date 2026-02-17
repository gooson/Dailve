import Foundation

extension ExerciseCategory {
    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .cardio: "Cardio"
        case .hiit: "HIIT"
        case .flexibility: "Flexibility"
        case .bodyweight: "Bodyweight"
        }
    }
}
