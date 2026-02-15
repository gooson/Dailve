import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "heart.text.clipboard") {
                DashboardView()
            }
            Tab("Exercise", systemImage: "figure.run") {
                ExerciseView()
            }
            Tab("Sleep", systemImage: "bed.double") {
                SleepView()
            }
            Tab("Body", systemImage: "figure.stand") {
                BodyCompositionView()
            }
        }
    }
}

#Preview {
    ContentView()
}
