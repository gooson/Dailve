import SwiftUI

/// Watch exercise picker for Quick Start — starts a single-exercise workout without a template.
/// Uses `WatchConnectivityManager.exerciseLibrary` synced from iPhone.
struct QuickStartPickerView: View {
    @Environment(WatchConnectivityManager.self) private var connectivity

    @State private var searchText = ""

    private var filteredExercises: [WatchExerciseInfo] {
        let library = connectivity.exerciseLibrary
        guard !searchText.isEmpty else { return library }
        return library.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if connectivity.exerciseLibrary.isEmpty {
                emptyState
            } else {
                exerciseList
            }
        }
        .navigationTitle("Quick Start")
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        List {
            ForEach(filteredExercises, id: \.id) { exercise in
                NavigationLink(value: WatchRoute.workoutPreview(
                    snapshotFromExercise(exercise)
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        Text("\(exercise.defaultSets) sets · \(exercise.defaultReps ?? 10) reps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.right.inward")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No Exercises")
                .font(.headline)
            Text("Open the Dailve app\non your iPhone to sync")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Helpers

    private func snapshotFromExercise(_ exercise: WatchExerciseInfo) -> WorkoutSessionTemplate {
        let entry = TemplateEntry(
            exerciseDefinitionID: exercise.id,
            exerciseName: exercise.name,
            defaultSets: exercise.defaultSets,
            defaultReps: exercise.defaultReps ?? 10,
            defaultWeightKg: exercise.defaultWeightKg
        )
        return WorkoutSessionTemplate(
            name: exercise.name,
            entries: [entry]
        )
    }
}
