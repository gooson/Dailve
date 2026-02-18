import Foundation

/// A single personal record entry for a specific workout activity type.
struct PersonalRecord: Codable, Sendable {
    let type: PersonalRecordType
    let value: Double
    let date: Date
    let workoutID: String
}

/// Training Load data point for a single day.
struct TrainingLoad: Identifiable, Sendable {
    let id: Date
    let date: Date
    let load: Double
    let source: LoadSource

    enum LoadSource: String, Codable, Sendable {
        case effort      // Apple Workout Effort Score
        case rpe         // User-entered RPE
        case trimp       // HR-based TRIMP calculation
    }
}
