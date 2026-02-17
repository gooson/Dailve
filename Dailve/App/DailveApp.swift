import SwiftUI
import SwiftData

@main
struct DailveApp: App {
    @AppStorage("hasShownCloudSyncConsent") private var hasShownConsent = false
    @AppStorage("isCloudSyncEnabled") private var isCloudSyncEnabled = false
    @State private var showConsentSheet = false

    let modelContainer: ModelContainer

    init() {
        let cloudSyncEnabled = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        let config = ModelConfiguration(
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )
        do {
            modelContainer = try ModelContainer(
                for: ExerciseRecord.self, BodyCompositionRecord.self, WorkoutSet.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !hasShownConsent {
                        showConsentSheet = true
                    }
                }
                .sheet(isPresented: $showConsentSheet) {
                    CloudSyncConsentView(isPresented: $showConsentSheet)
                }
        }
        .modelContainer(modelContainer)
    }
}
