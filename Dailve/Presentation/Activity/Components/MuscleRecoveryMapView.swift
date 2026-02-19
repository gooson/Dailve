import SwiftUI

/// Hero section: muscle recovery grid grouped by upper/lower body + integrated workout suggestion.
struct MuscleRecoveryMapView: View {
    let fatigueStates: [MuscleFatigueState]
    let suggestion: WorkoutSuggestion?
    let onStartExercise: (ExerciseDefinition) -> Void
    let onMuscleSelected: (MuscleGroup) -> Void

    private var fatigueByMuscle: [MuscleGroup: MuscleFatigueState] {
        Dictionary(uniqueKeysWithValues: fatigueStates.map { ($0.muscle, $0) })
    }

    private static let upperBody: [MuscleGroup] = [
        .chest, .back, .shoulders, .lats, .traps, .biceps, .triceps, .forearms
    ]
    private static let lowerBody: [MuscleGroup] = [
        .quadriceps, .hamstrings, .glutes, .calves, .core
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.sm), count: 4)

    var body: some View {
        HeroCard(tintColor: DS.Color.activity) {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                headerSection
                muscleGridSection
                suggestionSection
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text("Muscle Recovery")
                .font(.headline)
            Text(recoverySubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var recoverySubtitle: String {
        let recovered = fatigueStates.filter(\.isRecovered).count
        let total = fatigueStates.count
        guard total > 0 else { return "Start training to track recovery" }
        if recovered == total { return "All \(total) muscle groups ready" }
        return "\(recovered)/\(total) muscle groups ready"
    }

    // MARK: - Muscle Grid

    private var muscleGridSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            muscleGroupRow(title: "Upper Body", muscles: Self.upperBody)
            muscleGroupRow(title: "Lower Body", muscles: Self.lowerBody)
        }
    }

    private func muscleGroupRow(title: String, muscles: [MuscleGroup]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
                ForEach(muscles, id: \.self) { muscle in
                    MuscleRecoveryCell(
                        muscle: muscle,
                        state: fatigueByMuscle[muscle],
                        onTap: { onMuscleSelected(muscle) }
                    )
                }
            }
        }
    }

    // MARK: - Suggestion

    @ViewBuilder
    private var suggestionSection: some View {
        if let suggestion {
            Divider().opacity(0.3)
            if suggestion.isRestDay {
                restDaySection(suggestion: suggestion)
            } else {
                workoutSection(suggestion: suggestion)
            }
        }
    }

    private func workoutSection(suggestion: WorkoutSuggestion) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(DS.Color.activity)
                Text("Suggested Workout")
                    .font(.subheadline.weight(.semibold))
            }

            if !suggestion.focusMuscles.isEmpty {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(suggestion.focusMuscles, id: \.self) { muscle in
                        Text(muscle.displayName)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xxs)
                            .background(DS.Color.activity.opacity(0.12), in: Capsule())
                            .foregroundStyle(DS.Color.activity)
                    }
                }
            }

            ForEach(suggestion.exercises) { exercise in
                SuggestedExerciseRow(
                    exercise: exercise,
                    onStart: { onStartExercise(exercise.definition) },
                    onAlternativeSelected: { alt in onStartExercise(alt) }
                )
            }
        }
    }

    private func restDaySection(suggestion: WorkoutSuggestion) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "bed.double.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("Recovery Day")
                    .font(.subheadline.weight(.semibold))
            }

            Text(suggestion.reasoning)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let next = suggestion.nextReadyMuscle {
                nextReadyLabel(muscle: next.muscle, date: next.readyDate)
            }

            if !suggestion.activeRecoverySuggestions.isEmpty {
                ActiveRecoveryCard(suggestions: suggestion.activeRecoverySuggestions)
            }
        }
    }

    private func nextReadyLabel(muscle: MuscleGroup, date: Date) -> some View {
        let hours = Swift.max(0, date.timeIntervalSince(Date()) / 3600)
        let timeText: String
        if hours < 1 {
            timeText = "soon"
        } else if hours < 24 {
            timeText = "in ~\(Int(hours))h"
        } else {
            let days = Int(hours / 24)
            timeText = "in ~\(days)d"
        }

        return HStack(spacing: DS.Spacing.xs) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(muscle.displayName) ready \(timeText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Muscle Recovery Cell

private struct MuscleRecoveryCell: View {
    let muscle: MuscleGroup
    let state: MuscleFatigueState?
    let onTap: () -> Void

    private var recoveryPercent: Double {
        guard let state, state.lastTrainedDate != nil else { return -1 } // -1 = no data
        return state.recoveryPercent
    }

    private var statusColor: Color {
        let pct = recoveryPercent
        guard pct >= 0 else { return .secondary.opacity(0.15) }
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .yellow }
        return .red
    }

    private var percentText: String {
        let pct = recoveryPercent
        guard pct >= 0 else { return "—" }
        return "\(Int(pct * 100))%"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DS.Spacing.xs) {
                // Recovery indicator circle
                ZStack {
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: recoveryPercent >= 0 ? recoveryPercent : 0)
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(percentText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(recoveryPercent >= 0 ? .primary : .secondary)
                }
                .frame(width: 36, height: 36)

                // Muscle name
                Text(muscle.displayName)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .background(statusColor.opacity(0.06), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        }
        .buttonStyle(.plain)
    }
}
