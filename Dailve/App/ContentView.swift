import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPhone

    private var iPhoneLayout: some View {
        TabView {
            Tab(AppSection.dashboard.title, systemImage: AppSection.dashboard.icon) {
                DashboardView()
            }
            Tab(AppSection.exercise.title, systemImage: AppSection.exercise.icon) {
                ActivityView()
            }
            Tab(AppSection.sleep.title, systemImage: AppSection.sleep.icon) {
                SleepView()
            }
            Tab(AppSection.body.title, systemImage: AppSection.body.icon) {
                BodyCompositionView()
            }
        }
    }

    // MARK: - iPad

    @State private var selectedSection: AppSection? = .dashboard

    private var iPadLayout: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .accessibilityIdentifier("sidebar-\(section.rawValue)")
            }
            .accessibilityIdentifier("sidebar-list")
            .navigationTitle("Dailve")
        } detail: {
            NavigationStack {
                switch selectedSection {
                case .dashboard:
                    DashboardView()
                case .exercise:
                    ActivityView()
                case .sleep:
                    SleepView()
                case .body:
                    BodyCompositionView()
                case .none:
                    ContentUnavailableView(
                        "Select a Section",
                        systemImage: "heart.text.clipboard",
                        description: Text("Choose a category from the sidebar.")
                    )
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .keyboardShortcut(for: .dashboard, selection: $selectedSection)
        .keyboardShortcut(for: .exercise, selection: $selectedSection)
        .keyboardShortcut(for: .sleep, selection: $selectedSection)
        .keyboardShortcut(for: .body, selection: $selectedSection)
    }
}

// MARK: - Keyboard Shortcuts

private extension View {
    func keyboardShortcut(for section: AppSection, selection: Binding<AppSection?>) -> some View {
        background {
            Button("") { selection.wrappedValue = section }
                .keyboardShortcut(KeyEquivalent(section.keyEquivalent), modifiers: .command)
                .hidden()
        }
    }
}

#Preview {
    ContentView()
}
