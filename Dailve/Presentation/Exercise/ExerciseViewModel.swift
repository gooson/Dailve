import SwiftUI
import SwiftData

@Observable
@MainActor
final class ExerciseViewModel {
    var healthKitWorkouts: [WorkoutSummary] = []
    var manualRecords: [ExerciseRecord] = []
    var isLoading = false
    var isShowingAddSheet = false
    var errorMessage: String?

    // Add form fields
    var newExerciseType = ""
    var newDuration: TimeInterval = 30 * 60
    var newCalories: String = ""
    var newDistance: String = ""
    var newMemo = ""

    private let workoutService = WorkoutQueryService()

    var allExercises: [ExerciseListItem] {
        var items: [ExerciseListItem] = []

        for workout in healthKitWorkouts {
            items.append(ExerciseListItem(
                id: workout.id,
                type: workout.type,
                duration: workout.duration,
                calories: workout.calories,
                distance: workout.distance,
                date: workout.date,
                source: .healthKit
            ))
        }

        for record in manualRecords {
            items.append(ExerciseListItem(
                id: record.id.uuidString,
                type: record.exerciseType,
                duration: record.duration,
                calories: record.calories,
                distance: record.distance,
                date: record.date,
                source: .manual
            ))
        }

        return items.sorted { $0.date > $1.date }
    }

    func loadHealthKitWorkouts() async {
        isLoading = true
        do {
            healthKitWorkouts = try await workoutService.fetchWorkouts(days: 30)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveManualRecord(context: ModelContext) {
        let record = ExerciseRecord(
            date: Date(),
            exerciseType: newExerciseType,
            duration: newDuration,
            calories: Double(newCalories),
            distance: Double(newDistance),
            memo: newMemo
        )
        context.insert(record)
        resetForm()
        isShowingAddSheet = false
    }

    func deleteRecord(_ record: ExerciseRecord, context: ModelContext) {
        context.delete(record)
    }

    private func resetForm() {
        newExerciseType = ""
        newDuration = 30 * 60
        newCalories = ""
        newDistance = ""
        newMemo = ""
    }
}

struct ExerciseListItem: Identifiable {
    let id: String
    let type: String
    let duration: TimeInterval
    let calories: Double?
    let distance: Double?
    let date: Date
    let source: Source

    enum Source {
        case healthKit
        case manual
    }

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}
