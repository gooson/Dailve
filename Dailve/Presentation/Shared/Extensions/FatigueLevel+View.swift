import SwiftUI

extension FatigueLevel {

    var displayName: String {
        switch self {
        case .noData:           "데이터 없음"
        case .fullyRecovered:   "완전 회복"
        case .wellRested:       "충분한 휴식"
        case .lightFatigue:     "가벼운 피로"
        case .mildFatigue:      "경미한 피로"
        case .moderateFatigue:  "중간 피로"
        case .notableFatigue:   "상당한 피로"
        case .highFatigue:      "높은 피로"
        case .veryHighFatigue:  "매우 높은 피로"
        case .extremeFatigue:   "극심한 피로"
        case .overtrained:      "과훈련"
        }
    }

    var shortLabel: String {
        switch self {
        case .noData:   "—"
        default:        "L\(rawValue)"
        }
    }

    /// HSB-interpolated color from deep green (L1) to deep red (L10).
    func color(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .noData:
            return .secondary.opacity(0.2)
        case .fullyRecovered:
            return Color(hue: 0.39, saturation: 0.70, brightness: colorScheme == .dark ? 0.90 : 0.50)
        case .wellRested:
            return Color(hue: 0.36, saturation: 0.60, brightness: colorScheme == .dark ? 0.90 : 0.60)
        case .lightFatigue:
            return Color(hue: 0.31, saturation: 0.55, brightness: colorScheme == .dark ? 0.90 : 0.70)
        case .mildFatigue:
            return Color(hue: 0.22, saturation: 0.55, brightness: colorScheme == .dark ? 0.90 : 0.75)
        case .moderateFatigue:
            return Color(hue: 0.15, saturation: 0.65, brightness: colorScheme == .dark ? 0.90 : 0.80)
        case .notableFatigue:
            return Color(hue: 0.11, saturation: 0.70, brightness: colorScheme == .dark ? 0.88 : 0.80)
        case .highFatigue:
            return Color(hue: 0.07, saturation: 0.75, brightness: colorScheme == .dark ? 0.85 : 0.78)
        case .veryHighFatigue:
            return Color(hue: 0.04, saturation: 0.80, brightness: colorScheme == .dark ? 0.82 : 0.72)
        case .extremeFatigue:
            return Color(hue: 0.01, saturation: 0.82, brightness: colorScheme == .dark ? 0.78 : 0.65)
        case .overtrained:
            return Color(hue: 0.00, saturation: 0.90, brightness: colorScheme == .dark ? 0.70 : 0.50)
        }
    }

    /// Stroke color for muscle map outline.
    func strokeColor(for colorScheme: ColorScheme) -> Color {
        if self == .noData {
            return .secondary.opacity(0.15)
        }
        return color(for: colorScheme).opacity(0.6)
    }
}
