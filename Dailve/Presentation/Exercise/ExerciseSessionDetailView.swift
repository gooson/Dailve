import SwiftUI
import SwiftData

/// Detail view for a single exercise session, showing set data + HealthKit heart rate chart.
struct ExerciseSessionDetailView: View {
    let record: ExerciseRecord

    @State private var heartRateSummary: HeartRateSummary?
    @State private var isLoadingHR = false
    @State private var hrError: String?
    @AppStorage(WeightUnit.storageKey) private var weightUnitRaw = WeightUnit.kg.rawValue

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                sessionHeader
                setsList
                heartRateSection
                calorieSection
            }
            .padding(.horizontal, DS.Spacing.lg)
        }
        .navigationTitle(record.exerciseType)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHeartRate()
        }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(record.date, style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(record.date, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)

            if record.duration > 0 {
                Text(formattedDuration(record.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, DS.Spacing.sm)
    }

    // MARK: - Sets

    private var setsList: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Sets")
                .font(.headline)

            let sets = record.completedSets
            if sets.isEmpty {
                Text("No set data recorded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sets, id: \.id) { workoutSet in
                    setRow(workoutSet)
                }
            }
        }
    }

    private func setRow(_ workoutSet: WorkoutSet) -> some View {
        HStack {
            Text("Set \(workoutSet.setNumber)")
                .font(.subheadline.weight(.medium))

            Spacer()

            HStack(spacing: DS.Spacing.md) {
                if let weight = workoutSet.weight {
                    Text("\(formattedWeight(weight)) \(weightUnit.displayName)")
                        .font(.subheadline.monospacedDigit())
                }
                if let reps = workoutSet.reps {
                    Text("\(reps) reps")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    // MARK: - Heart Rate

    private var heartRateSection: some View {
        Group {
            if record.healthKitWorkoutID != nil && !(record.healthKitWorkoutID?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Label("Heart Rate", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if isLoadingHR {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                    } else if let summary = heartRateSummary, !summary.isEmpty {
                        HeartRateChartView(
                            samples: summary.samples,
                            averageBPM: summary.average,
                            maxBPM: summary.max
                        )
                    } else if let error = hrError {
                        hrErrorView(error)
                    } else {
                        noHRDataView
                    }
                }
                .padding(DS.Spacing.md)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
        }
    }

    private var noHRDataView: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "waveform.path.ecg")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No heart rate data available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    private func hrErrorView(_ error: String) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Calories

    private var calorieSection: some View {
        Group {
            if let calories = record.bestCalories, calories > 0 {
                HStack {
                    Label("Calories", systemImage: "flame.fill")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(calories)) kcal")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(DS.Spacing.md)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            }
        }
    }

    // MARK: - Data Loading

    private func loadHeartRate() async {
        guard let workoutID = record.healthKitWorkoutID,
              !workoutID.isEmpty else { return }

        isLoadingHR = true
        defer { isLoadingHR = false }

        do {
            let service = HeartRateQueryService(manager: .shared)
            heartRateSummary = try await service.fetchHeartRateSummary(forWorkoutID: workoutID)
        } catch {
            hrError = "Could not load heart rate data"
        }
    }

    // MARK: - Formatting

    private func formattedWeight(_ kg: Double) -> String {
        weightUnit.fromKg(kg).formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
