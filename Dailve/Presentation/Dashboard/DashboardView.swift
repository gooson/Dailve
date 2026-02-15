import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Section
                    if let score = viewModel.conditionScore {
                        ConditionHeroView(
                            score: score,
                            recentScores: viewModel.recentScores
                        )
                    } else if let status = viewModel.baselineStatus, !status.isReady {
                        BaselineProgressView(status: status)
                    }

                    // Metric Cards (smart sorted)
                    SmartCardGrid(metrics: viewModel.sortedMetrics)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Dailve")
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Baseline Progress

private struct BaselineProgressView: View {
    let status: BaselineStatus

    var body: some View {
        VStack(spacing: 12) {
            Text("Establishing Baseline")
                .font(.headline)

            ProgressView(value: status.progress)
                .tint(.blue)

            Text("\(status.daysCollected)/\(status.daysRequired) days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
}
