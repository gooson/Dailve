import Foundation

extension HealthMetric {
    var formattedValue: String {
        switch category {
        case .hrv:
            return String(format: "%.0fms", value)
        case .rhr:
            return String(format: "%.0fbpm", value)
        case .sleep:
            let hours = Int(value) / 60
            let minutes = Int(value) % 60
            return "\(hours)h \(minutes)m"
        case .exercise:
            return String(format: "%.0fmin", value)
        case .steps:
            return String(format: "%.0f", value)
        case .weight:
            return String(format: "%.1fkg", value)
        }
    }

    var formattedChange: String? {
        guard let change else { return nil }
        let arrow = change > 0 ? "\u{25B2}" : "\u{25BC}"
        return "\(arrow)\(String(format: "%.1f", abs(change)))"
    }
}
