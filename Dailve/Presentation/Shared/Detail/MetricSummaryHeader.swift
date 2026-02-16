import SwiftUI

/// Summary header for metric detail view showing current value, period stats, and change badge.
struct MetricSummaryHeader: View {
    let category: HealthMetric.Category
    let currentValue: Double
    let summary: MetricSummary?
    let lastUpdated: Date?
    var unitOverride: String?

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Category icon + name
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: category.iconName)
                    .foregroundStyle(category.themeColor)
                Text(category.displayName)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            // Large current value
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                Text(formattedCurrentValue)
                    .font(sizeClass == .regular ? DS.Typography.heroScore : DS.Typography.cardScore)
                    .fontDesign(.rounded)

                Text(resolvedUnit)
                    .font(sizeClass == .regular ? .title2 : .title3)
                    .foregroundStyle(.secondary)
            }

            // Period summary stats
            if let summary {
                HStack(spacing: DS.Spacing.lg) {
                    statItem(label: "Avg", value: formatValue(summary.average))
                    if sizeClass == .regular { statDivider }
                    statItem(label: "Min", value: formatValue(summary.min))
                    if sizeClass == .regular { statDivider }
                    statItem(label: "Max", value: formatValue(summary.max))

                    if let change = summary.changePercentage {
                        changeBadge(change)
                    }
                }

                // Comparison sentence
                if let change = summary.changePercentage {
                    comparisonSentence(change)
                }
            }

            // Last updated
            if let lastUpdated {
                Text("Updated \(lastUpdated, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.displayName), \(formattedCurrentValue) \(resolvedUnit)")
    }

    // MARK: - Subviews

    private var statDivider: some View {
        Divider()
            .frame(height: 24)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: DS.Spacing.xxs) {
            Text(label)
                .font(sizeClass == .regular ? .caption : .caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(sizeClass == .regular ? .subheadline : .caption)
                .fontWeight(.medium)
        }
    }

    private func changeBadge(_ change: Double) -> some View {
        let isPositive = change > 0
        let icon = isPositive ? "arrow.up.right" : "arrow.down.right"
        let color = badgeColor(isPositive: isPositive)

        return HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(String(format: "%.1f", abs(change)))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12), in: Capsule())
    }

    // MARK: - Helpers

    private var resolvedUnit: String {
        unitOverride ?? category.unitLabel
    }

    private var formattedCurrentValue: String {
        formatValue(currentValue)
    }

    private func formatValue(_ value: Double) -> String {
        // Use distance formatting when unit is km
        if let override = unitOverride, override == "km" {
            return String(format: "%.1f", value)
        }
        return switch category {
        case .hrv:      String(format: "%.0f", value)
        case .rhr:      String(format: "%.0f", value)
        case .sleep:    value.hoursMinutesFormatted
        case .exercise: String(format: "%.0f", value)
        case .steps:    String(format: "%.0f", value)
        case .weight:   String(format: "%.1f", value)
        }
    }

    private func comparisonSentence(_ change: Double) -> some View {
        let direction = change > 0 ? "higher" : "lower"
        let absChange = String(format: "%.1f", abs(change))
        return Text("Your average is \(absChange)% \(direction) than last period")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func badgeColor(isPositive: Bool) -> Color {
        switch category {
        case .rhr:
            isPositive ? DS.Color.negative : DS.Color.positive
        default:
            isPositive ? DS.Color.positive : DS.Color.negative
        }
    }
}
