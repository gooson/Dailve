import SwiftUI

struct ContentView: View {
    @Environment(WatchConnectivityManager.self) private var connectivity
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if let activeWorkout = connectivity.activeWorkout {
                WorkoutActiveView(workout: activeWorkout)
            } else {
                WorkoutIdleView()
            }
        }
        .onChange(of: connectivity.activeWorkout?.exerciseID) {
            // Pop all pushed views when workout state changes
            navigationPath = NavigationPath()
        }
    }
}
