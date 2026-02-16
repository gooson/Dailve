import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case exercise
    case sleep
    case body

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Condition"
        case .exercise: "Activity"
        case .sleep: "Sleep"
        case .body: "Body"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "heart.text.clipboard"
        case .exercise: "flame"
        case .sleep: "moon.zzz"
        case .body: "figure.arms.open"
        }
    }

    /// Keyboard shortcut key equivalent (⌘1, ⌘2, ⌘3, ⌘4) for iPad sidebar.
    var keyEquivalent: Character {
        switch self {
        case .dashboard: "1"
        case .exercise: "2"
        case .sleep: "3"
        case .body: "4"
        }
    }
}
