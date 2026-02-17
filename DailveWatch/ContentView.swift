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
        .onChange(of: connectivity.activeWorkout?.exerciseID) { oldValue, newValue in
            // When iPhone starts a workout (nil → exerciseID), pop QuickStartView
            // so root switches from WorkoutIdleView to WorkoutActiveView.
            // Without this, pushed views remain on stack and cover the transition.
            if oldValue == nil, newValue != nil {
                navigationPath = NavigationPath()
            }
        }
    }
}
