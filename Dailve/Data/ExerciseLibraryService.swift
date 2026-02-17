import Foundation

protocol ExerciseLibraryQuerying: Sendable {
    func allExercises() -> [ExerciseDefinition]
    func exercise(byID id: String) -> ExerciseDefinition?
    func search(query: String) -> [ExerciseDefinition]
    func exercises(forMuscle muscle: MuscleGroup) -> [ExerciseDefinition]
    func exercises(forCategory category: ExerciseCategory) -> [ExerciseDefinition]
    func exercises(forEquipment equipment: Equipment) -> [ExerciseDefinition]
}

struct ExerciseLibraryService: ExerciseLibraryQuerying {
    private let exercises: [ExerciseDefinition]
    private let exerciseByID: [String: ExerciseDefinition]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ExerciseDefinition].self, from: data)
        else {
            self.exercises = []
            self.exerciseByID = [:]
            return
        }
        self.exercises = decoded
        self.exerciseByID = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }

    /// For testing: initialize with an explicit array
    init(exercises: [ExerciseDefinition]) {
        self.exercises = exercises
        self.exerciseByID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }

    func allExercises() -> [ExerciseDefinition] {
        exercises
    }

    func exercise(byID id: String) -> ExerciseDefinition? {
        exerciseByID[id]
    }

    func search(query: String) -> [ExerciseDefinition] {
        guard !query.isEmpty else { return exercises }
        return exercises.filter { exercise in
            exercise.localizedName.localizedCaseInsensitiveContains(query)
                || exercise.name.localizedCaseInsensitiveContains(query)
        }
    }

    func exercises(forMuscle muscle: MuscleGroup) -> [ExerciseDefinition] {
        exercises.filter { exercise in
            exercise.primaryMuscles.contains(muscle)
                || exercise.secondaryMuscles.contains(muscle)
        }
    }

    func exercises(forCategory category: ExerciseCategory) -> [ExerciseDefinition] {
        exercises.filter { $0.category == category }
    }

    func exercises(forEquipment equipment: Equipment) -> [ExerciseDefinition] {
        exercises.filter { $0.equipment == equipment }
    }
}
