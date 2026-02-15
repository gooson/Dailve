import SwiftUI
import SwiftData

@main
struct DailveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            BodyCompositionRecord.self,
            ExerciseRecord.self
        ], isAutosaveEnabled: true)
    }
}
