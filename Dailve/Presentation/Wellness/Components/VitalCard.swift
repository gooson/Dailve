import SwiftUI

/// Individual metric card for the 2-column wellness grid.
struct VitalCard: View {
    let data: VitalCardData

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool { sizeClass == .regular }
    private var themeColor: Color { data.category.themeColor }

    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                // Header: icon + title
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: data.category.iconName)
                        .font(.caption)
                        .foregroundStyle(themeColor)

                    Text(data.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    // Stale indicator
                    if data.isStale {
                        staleLabel
                    }
                }

                // Value row
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
                    Text(data.value)
                        .font(DS.Typography.cardScore)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    if !data.unit.isEmpty {
                        Text(data.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    // Change indicator
                    if let change = data.change {
                        changeLabel(change)
                    }
                }

                // Sparkline
                if data.sparklineData.count >= 2 {
                    MiniSparklineView(dataPoints: data.sparklineData, color: themeColor)
                        .frame(height: isRegular ? 28 : 24)
                } else {
                    // Dashed placeholder
                    dashPlaceholder
                        .frame(height: isRegular ? 28 : 24)
                }
            }
        }
        .opacity(data.isStale ? 0.6 : 1.0)
    }

    // MARK: - Components

    private var staleLabel: some View {
        let days = Calendar.current.dateComponents([.day], from: data.lastUpdated, to: Date()).day ?? 0
        return Text("\(days)d ago")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private func changeLabel(_ change: String) -> some View {
        let isPositive = data.changeIsPositive ?? false
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .semibold))
            Text(change)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(isPositive ? DS.Color.positive : DS.Color.negative)
    }

    private var dashPlaceholder: some View {
        GeometryReader { geo in
            Path { path in
                let y = geo.size.height / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geo.size.width, y: y))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .foregroundStyle(.quaternary)
        }
        .accessibilityHidden(true)
    }
}
