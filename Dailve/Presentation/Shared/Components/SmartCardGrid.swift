import SwiftUI

struct SmartCardGrid: View {
    let metrics: [HealthMetric]

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: DS.Spacing.md),
            count: count
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.md) {
            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                NavigationLink(value: metric) {
                    MetricCardView(metric: metric)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    NavigationLink(value: metric) {
                        Label("View Trend", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink(value: AllDataDestination(category: metric.category)) {
                        Label("Show All Data", systemImage: "list.bullet")
                    }
                } preview: {
                    MetricCardView(metric: metric)
                        .padding()
                        .frame(width: 240)
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity
                            .combined(with: .offset(y: 8))
                            .animation(DS.Animation.standard.delay(Double(index) * 0.05)),
                        removal: .opacity
                    )
                )
            }
        }
        .animation(DS.Animation.standard, value: metrics.map(\.id))
    }
}
