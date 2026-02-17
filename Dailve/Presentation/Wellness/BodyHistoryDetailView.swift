import SwiftUI
import SwiftData

struct BodyHistoryDetailView: View {
    @Bindable var viewModel: BodyCompositionViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyCompositionRecord.date, order: .reverse) private var records: [BodyCompositionRecord]

    private var allItems: [BodyCompositionListItem] {
        viewModel.allItems(manualRecords: records)
    }

    var body: some View {
        Group {
            if allItems.isEmpty {
                EmptyStateView(
                    icon: "figure.stand",
                    title: "No Records",
                    message: "Your body composition records will appear here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Spacing.sm) {
                        ForEach(allItems) { item in
                            historyRow(item)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Body Records")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            if let record = viewModel.editingRecord {
                BodyCompositionFormSheet(
                    viewModel: viewModel,
                    isEdit: true,
                    onSave: {
                        if viewModel.applyUpdate(to: record) {
                            viewModel.isShowingEditSheet = false
                            viewModel.editingRecord = nil
                        }
                    }
                )
            }
        }
    }

    private func historyRow(_ item: BodyCompositionListItem) -> some View {
        HStack {
            if item.source == .healthKit {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(item.date, style: .date)
                    .font(.subheadline)
                HStack(spacing: DS.Spacing.md) {
                    if let w = item.weight {
                        Text("\(String(format: "%.1f", w)) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let f = item.bodyFatPercentage {
                        Text("\(String(format: "%.1f", f))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let m = item.muscleMass {
                        Text("\(String(format: "%.1f", m)) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if item.source == .manual {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DS.Spacing.md)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .contextMenu {
            if item.source == .manual, let record = findManualRecord(id: item.id) {
                Button {
                    viewModel.startEditing(record)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    modelContext.delete(record)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func findManualRecord(id: String) -> BodyCompositionRecord? {
        records.first { $0.id.uuidString == id }
    }
}
