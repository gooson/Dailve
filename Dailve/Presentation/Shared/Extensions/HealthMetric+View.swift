import SwiftUI

extension HealthMetric {
    /// Formatted numeric value only (no unit). Use with `category.unitLabel` for display.
    var formattedNumericValue: String {
        switch category {
        case .hrv:
            return String(format: "%.0f", value)
        case .rhr:
            return String(format: "%.0f", value)
        case .sleep:
            return value.hoursMinutesFormatted
        case .exercise:
            switch unit {
            case "km":  return String(format: "%.1f", value)
            case "m":   return String(format: "%.0f", value)
            default:    return String(format: "%.0f", value)
            }
        case .steps:
            return String(format: "%.0f", value)
        case .weight:
            return String(format: "%.1f", value)
        case .bmi:
            return String(format: "%.1f", value)
        }
    }

    /// Combined value+unit for contexts needing a single string (accessibility, etc.).
    var formattedValue: String {
        // Sleep already includes "h m" in its formatted value
        if category == .sleep { return formattedNumericValue }
        let unit = resolvedUnitLabel
        if unit.isEmpty { return formattedNumericValue }
        return "\(formattedNumericValue) \(unit)"
    }

    /// Unit label resolved from override or category default.
    var resolvedUnitLabel: String {
        if !unit.isEmpty { return unit }
        return category.unitLabel
    }

    /// Absolute change value formatted (no arrow).
    var formattedChangeValue: String? {
        guard let change else { return nil }
        return String(format: "%.1f", abs(change))
    }

    /// SF Symbol name for change direction.
    var changeDirectionIcon: String? {
        guard let change else { return nil }
        return change > 0 ? "arrow.up.right" : "arrow.down.right"
    }

    /// Legacy combined format for backward compatibility.
    var formattedChange: String? {
        guard let change else { return nil }
        let arrow = change > 0 ? "\u{25B2}" : "\u{25BC}"
        return "\(arrow)\(String(format: "%.1f", abs(change)))"
    }
}

extension HealthMetric {
    /// Resolved icon: uses iconOverride if set, otherwise falls back to category default.
    var resolvedIconName: String {
        iconOverride ?? category.iconName
    }
}

extension HealthMetric.Category {
    var themeColor: Color {
        switch self {
        case .hrv:      DS.Color.hrv
        case .rhr:      DS.Color.rhr
        case .sleep:    DS.Color.sleep
        case .exercise: DS.Color.activity
        case .steps:    DS.Color.steps
        case .weight:   DS.Color.body
        case .bmi:      DS.Color.body
        }
    }

    var iconName: String {
        switch self {
        case .hrv:      "waveform.path.ecg"
        case .rhr:      "heart.fill"
        case .sleep:    "moon.zzz.fill"
        case .exercise: "flame.fill"
        case .steps:    "figure.walk"
        case .weight:   "scalemass.fill"
        case .bmi:      "figure.stand"
        }
    }

    var displayName: String {
        switch self {
        case .hrv:      "Heart Rate Variability"
        case .rhr:      "Resting Heart Rate"
        case .sleep:    "Sleep"
        case .exercise: "Exercise"
        case .steps:    "Steps"
        case .weight:   "Weight"
        case .bmi:      "BMI"
        }
    }

    var unitLabel: String {
        switch self {
        case .hrv:      "ms"
        case .rhr:      "bpm"
        case .sleep:    ""
        case .exercise: "min"
        case .steps:    "steps"
        case .weight:   "kg"
        case .bmi:      ""
        }
    }
}
