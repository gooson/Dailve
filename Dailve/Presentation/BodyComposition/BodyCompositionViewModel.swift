import SwiftUI
import SwiftData

@Observable
@MainActor
final class BodyCompositionViewModel {
    var isShowingAddSheet = false
    var isShowingEditSheet = false
    var editingRecord: BodyCompositionRecord?

    // Form fields
    var newWeight: String = ""
    var newBodyFat: String = ""
    var newMuscleMass: String = ""
    var newMemo: String = ""

    func saveRecord(context: ModelContext) {
        let record = BodyCompositionRecord(
            date: Date(),
            weight: Double(newWeight),
            bodyFatPercentage: Double(newBodyFat),
            muscleMass: Double(newMuscleMass),
            memo: newMemo
        )
        context.insert(record)
        resetForm()
        isShowingAddSheet = false
    }

    func updateRecord(_ record: BodyCompositionRecord) {
        record.weight = Double(newWeight)
        record.bodyFatPercentage = Double(newBodyFat)
        record.muscleMass = Double(newMuscleMass)
        record.memo = newMemo
        isShowingEditSheet = false
        editingRecord = nil
    }

    func startEditing(_ record: BodyCompositionRecord) {
        editingRecord = record
        newWeight = record.weight.map { String(format: "%.1f", $0) } ?? ""
        newBodyFat = record.bodyFatPercentage.map { String(format: "%.1f", $0) } ?? ""
        newMuscleMass = record.muscleMass.map { String(format: "%.1f", $0) } ?? ""
        newMemo = record.memo
        isShowingEditSheet = true
    }

    func deleteRecord(_ record: BodyCompositionRecord, context: ModelContext) {
        context.delete(record)
    }

    func resetForm() {
        newWeight = ""
        newBodyFat = ""
        newMuscleMass = ""
        newMemo = ""
        editingRecord = nil
    }
}
