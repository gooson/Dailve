import SwiftUI
import SwiftData

struct ConfirmDeleteRecordModifier: ViewModifier {
    @Binding var recordToDelete: ExerciseRecord?
    let modelContext: ModelContext

    func body(content: Content) -> some View {
        content
            .alert(
                "Delete Exercise?",
                isPresented: Binding(
                    get: { recordToDelete != nil },
                    set: { if !$0 { recordToDelete = nil } }
                ),
                presenting: recordToDelete
            ) { record in
                Button("Delete", role: .destructive) {
                    // Guard against stale reference (record may have been deleted via CloudKit sync)
                    guard record.modelContext != nil else {
                        recordToDelete = nil
                        return
                    }
                    // Delete linked HKWorkout from HealthKit (fire-and-forget)
                    if let workoutID = record.healthKitWorkoutID, !workoutID.isEmpty {
                        Task {
                            let deleteService = WorkoutDeleteService(manager: .shared)
                            try? await deleteService.deleteWorkout(uuid: workoutID)
                        }
                    }
                    modelContext.delete(record)
                    try? modelContext.save()
                    recordToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    recordToDelete = nil
                }
            } message: { record in
                Text("\(record.exerciseType) on \(record.date.formatted(date: .abbreviated, time: .omitted)) will be permanently deleted from all your devices.")
            }
    }
}

extension View {
    func confirmDeleteRecord(_ record: Binding<ExerciseRecord?>, context: ModelContext) -> some View {
        modifier(ConfirmDeleteRecordModifier(recordToDelete: record, modelContext: context))
    }
}
