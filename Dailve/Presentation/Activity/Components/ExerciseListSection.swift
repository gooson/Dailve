import SwiftUI

/// Compact list of recent workouts with "See All" link.
/// Enriched with set summary data from ExerciseRecord when available.
struct ExerciseListSection: View {
    let workouts: [WorkoutSummary]
    let exerciseRecords: [ExerciseRecord]
    let library: ExerciseLibraryQuerying
    let limit: Int

    init(
        workouts: [WorkoutSummary],
        exerciseRecords: [ExerciseRecord] = [],
        library: ExerciseLibraryQuerying = ExerciseLibraryService(),
        limit: Int = 5
    ) {
        self.workouts = workouts
        self.exerciseRecords = exerciseRecords
        self.library = library
        self.limit = limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Section header
            HStack {
                Text("Recent Workouts")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if workouts.count > limit || !exerciseRecords.isEmpty {
                    NavigationLink {
                        ExerciseView()
                    } label: {
                        Text("See All")
                            .font(.caption)
                            .foregroundStyle(DS.Color.activity)
                    }
                }
            }

            // Manual records with set data (newest first)
            let setRecords = exerciseRecords.filter(\.hasSetData).prefix(limit)
            ForEach(Array(setRecords)) { record in
                setRecordRow(record)
            }

            // HealthKit workouts
            let remaining = max(limit - setRecords.count, 0)
            if remaining > 0 {
                ForEach(workouts.prefix(remaining)) { workout in
                    workoutRow(workout)
                }
            }

            if workouts.isEmpty && setRecords.isEmpty {
                InlineCard {
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundStyle(.secondary)
                        Text("No recent workouts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Set Record Row (new format)

    private func setRecordRow(_ record: ExerciseRecord) -> some View {
        InlineCard {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: WorkoutSummary.iconName(for: record.exerciseType))
                    .foregroundStyle(DS.Color.activity)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(record.exerciseType)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: DS.Spacing.xs) {
                        Text(record.date, format: .dateTime.weekday(.wide).hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Set summary line
                    if let summary = setSummary(for: record) {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DS.Spacing.xxs) {
                    Text("\(Int(record.duration / 60)) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let cal = record.bestCalories {
                        Text("~\(Int(cal)) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Legacy Workout Row (HealthKit)

    private func workoutRow(_ workout: WorkoutSummary) -> some View {
        InlineCard {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: WorkoutSummary.iconName(for: workout.type))
                    .foregroundStyle(DS.Color.activity)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(workout.type)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(workout.date, format: .dateTime.weekday(.wide).hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DS.Spacing.xxs) {
                    Text("\(Int(workout.duration / 60)) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let cal = workout.calories {
                        Text("\(Int(cal)) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func setSummary(for record: ExerciseRecord) -> String? {
        let completed = record.completedSets
        guard !completed.isEmpty else { return nil }

        var parts: [String] = []
        parts.append("\(completed.count) sets")

        let weights = completed.compactMap(\.weight).filter { $0 > 0 }
        if let minW = weights.min(), let maxW = weights.max() {
            if minW == maxW {
                parts.append("\(minW.formatted(.number.precision(.fractionLength(0...1))))kg")
            } else {
                parts.append("\(minW.formatted(.number.precision(.fractionLength(0...1))))-\(maxW.formatted(.number.precision(.fractionLength(0...1))))kg")
            }
        }

        let totalReps = completed.compactMap(\.reps).reduce(0, +)
        if totalReps > 0 {
            parts.append("\(totalReps) reps")
        }

        return parts.joined(separator: " · ")
    }
}
