import SwiftUI

/// Compact gradient legend for the 10-level fatigue system.
struct FatigueLegendView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DS.Spacing.xxs) {
            gradientBar
            labelRow
        }
    }

    private var gradientBar: some View {
        HStack(spacing: 1) {
            ForEach(FatigueLevel.allCases, id: \.self) { level in
                if level != .noData {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(level.color(for: colorScheme))
                        .frame(height: 6)
                }
            }
        }
        .clipShape(Capsule())
    }

    private var labelRow: some View {
        HStack {
            Text("Recovered")
                .foregroundStyle(.secondary)
            Spacer()
            Text("Fatigued")
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
    }
}
