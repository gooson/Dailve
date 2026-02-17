import SwiftUI

struct ExercisePickerView: View {
    let library: ExerciseLibraryQuerying
    let recentExerciseIDs: [String]
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?

    private var filteredExercises: [ExerciseDefinition] {
        var results: [ExerciseDefinition]

        if !searchText.isEmpty {
            results = library.search(query: searchText)
        } else if let category = selectedCategory {
            results = library.exercises(forCategory: category)
        } else {
            results = library.allExercises()
        }

        return results
    }

    private var recentExercises: [ExerciseDefinition] {
        recentExerciseIDs.compactMap { library.exercise(byID: $0) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Recent exercises section
                if searchText.isEmpty && selectedCategory == nil && !recentExercises.isEmpty {
                    Section("Recent") {
                        ForEach(recentExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }

                // Category filter
                if searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            categoryChip(nil, label: "All")
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                categoryChip(category, label: category.rawValue.capitalized)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.lg)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Exercise list
                Section {
                    ForEach(filteredExercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func exerciseRow(_ exercise: ExerciseDefinition) -> some View {
        Button {
            onSelect(exercise)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(exercise.localizedName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    HStack(spacing: DS.Spacing.xs) {
                        Text(exercise.primaryMuscles.map(\.rawValue.capitalized).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(exercise.equipment.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Image(systemName: WorkoutSummary.iconName(for: exercise.name))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func categoryChip(_ category: ExerciseCategory?, label: String) -> some View {
        Button {
            withAnimation(DS.Animation.snappy) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    selectedCategory == category
                        ? DS.Color.activity
                        : Color.secondary.opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(
                    selectedCategory == category ? .white : .primary
                )
        }
        .buttonStyle(.plain)
    }
}
