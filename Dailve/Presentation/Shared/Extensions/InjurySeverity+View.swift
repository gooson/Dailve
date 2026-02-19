import SwiftUI

extension InjurySeverity {
    var displayName: String {
        switch self {
        case .minor: "Minor"
        case .moderate: "Moderate"
        case .severe: "Severe"
        }
    }

    var localizedDisplayName: String {
        switch self {
        case .minor: "경미"
        case .moderate: "보통"
        case .severe: "심각"
        }
    }

    var color: Color {
        switch self {
        case .minor: .yellow
        case .moderate: .orange
        case .severe: .red
        }
    }

    var iconName: String {
        switch self {
        case .minor: "exclamationmark.circle"
        case .moderate: "exclamationmark.triangle"
        case .severe: "xmark.octagon.fill"
        }
    }
}
