import SwiftUI
import SwiftData

/// Full injury history — active injuries at top, ended injuries below.
struct InjuryHistoryView: View {
    @Bindable var viewModel: InjuryViewModel
    @Query(sort: \InjuryRecord.startDate, order: .reverse) private var allRecords: [InjuryRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var recordToDelete: InjuryRecord?
    @State private var cachedActiveRecords: [InjuryRecord] = []
    @State private var cachedEndedRecords: [InjuryRecord] = []

    @State private var showingStatistics = false

    var body: some View {
        List {
            if !cachedActiveRecords.isEmpty {
                Section("Active") {
                    ForEach(cachedActiveRecords) { record in
                        injuryRow(record)
                    }
                }
            }

            if !cachedEndedRecords.isEmpty {
                Section("Recovered") {
                    ForEach(cachedEndedRecords) { record in
                        injuryRow(record)
                    }
                }
            }

            if allRecords.isEmpty {
                ContentUnavailableView(
                    "No Injury Records",
                    systemImage: "bandage.fill",
                    description: Text("Injuries you track will appear here.")
                )
            }
        }
        .onChange(of: allRecords.count) { _, _ in rebuildRecordCache() }
        .onAppear { rebuildRecordCache() }
        .navigationTitle("Injury History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.loadStatistics(from: allRecords)
                    showingStatistics = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
                .disabled(allRecords.isEmpty)
            }
        }
        .navigationDestination(isPresented: $showingStatistics) {
            // Correction #48: avoid conditional content inside navigationDestination
            InjuryStatisticsView(
                statistics: viewModel.statistics ?? InjuryStatistics(
                    totalCount: 0,
                    activeCount: 0,
                    frequencyByBodyPart: [],
                    averageRecoveryDays: nil,
                    longestRecoveryDays: nil
                ),
                volumeComparisons: viewModel.volumeComparisons
            )
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            if viewModel.editingRecord != nil {
                InjuryFormSheet(
                    viewModel: viewModel,
                    isEdit: true,
                    onSave: {
                        if let record = viewModel.editingRecord, viewModel.applyUpdate(to: record) {
                            viewModel.isShowingEditSheet = false
                            viewModel.resetForm()
                        }
                    }
                )
            }
        }
        .confirmationDialog(
            "Delete Injury",
            isPresented: Binding(
                get: { recordToDelete != nil },
                set: { if !$0 { recordToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let record = recordToDelete {
                    withAnimation { modelContext.delete(record) }
                    recordToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }
        } message: {
            Text("This injury record will be permanently deleted across all your devices.")
        }
    }

    private func rebuildRecordCache() {
        cachedActiveRecords = allRecords.filter(\.isActive)
        cachedEndedRecords = allRecords.filter { !$0.isActive }
    }

    private func injuryRow(_ record: InjuryRecord) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: record.severity.iconName)
                .foregroundStyle(record.severity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                HStack(spacing: DS.Spacing.xs) {
                    Text(record.bodyPart.displayName)
                        .font(.subheadline.weight(.medium))
                    if let side = record.bodySide {
                        Text("(\(side.abbreviation))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: DS.Spacing.xs) {
                    Text(record.severity.displayName)
                        .font(.caption2)
                        .foregroundStyle(record.severity.color)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text("\(record.durationDays)d")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if record.isActive {
                Text("Active")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xxs)
                    .background(record.severity.color.opacity(0.12), in: Capsule())
                    .foregroundStyle(record.severity.color)
            }
        }
        .swipeActions(edge: .trailing) {
            Button { recordToDelete = record } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)

            if record.isActive {
                Button {
                    withAnimation { viewModel.markAsRecovered(record) }
                } label: {
                    Label("Recovered", systemImage: "checkmark.circle")
                }
                .tint(.green)
            }
        }
        .swipeActions(edge: .leading) {
            Button { viewModel.startEditing(record) } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button { viewModel.startEditing(record) } label: {
                Label("Edit", systemImage: "pencil")
            }
            if record.isActive {
                Button {
                    withAnimation { viewModel.markAsRecovered(record) }
                } label: {
                    Label("Mark Recovered", systemImage: "checkmark.circle")
                }
            }
            Divider()
            Button(role: .destructive) { recordToDelete = record } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
