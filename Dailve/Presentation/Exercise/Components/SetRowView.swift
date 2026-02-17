import SwiftUI

struct SetRowView: View {
    @Binding var editableSet: EditableSet
    let inputType: ExerciseInputType
    let previousSet: PreviousSetInfo?
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Set number
            Text("\(editableSet.setNumber)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Previous set info
            previousLabel
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 56, alignment: .leading)
                .lineLimit(1)

            // Input fields based on exercise type
            inputFields

            // Completion checkbox
            Button {
                onComplete()
            } label: {
                Image(systemName: editableSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(editableSet.isCompleted ? DS.Color.activity : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DS.Spacing.xs)
        .padding(.horizontal, DS.Spacing.sm)
        .background(
            editableSet.isCompleted
                ? DS.Color.activity.opacity(0.08)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: DS.Radius.sm)
        )
    }

    @ViewBuilder
    private var previousLabel: some View {
        if let prev = previousSet {
            switch inputType {
            case .setsRepsWeight:
                let w = prev.weight.map {
                    $0.formatted(.number.precision(.fractionLength(0...1)))
                } ?? "—"
                let r = prev.reps.map { "\($0)" } ?? "—"
                Text("\(w)×\(r)")
            case .setsReps:
                let r = prev.reps.map { "\($0)" } ?? "—"
                Text("×\(r)")
            default:
                Text("—")
            }
        } else {
            Text("—")
        }
    }

    @ViewBuilder
    private var inputFields: some View {
        switch inputType {
        case .setsRepsWeight:
            HStack(spacing: DS.Spacing.xs) {
                TextField("kg", text: $editableSet.weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 70)

                TextField("reps", text: $editableSet.reps)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
            }

        case .setsReps:
            TextField("reps", text: $editableSet.reps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 80)

        case .durationDistance:
            HStack(spacing: DS.Spacing.xs) {
                TextField("min", text: $editableSet.duration)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)

                TextField("km", text: $editableSet.distance)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 70)
            }

        case .durationIntensity:
            HStack(spacing: DS.Spacing.xs) {
                TextField("min", text: $editableSet.duration)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)

                TextField("1-10", text: $editableSet.intensity)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
            }

        case .roundsBased:
            HStack(spacing: DS.Spacing.xs) {
                TextField("reps", text: $editableSet.reps)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)

                TextField("sec", text: $editableSet.duration)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 60)
            }
        }
    }
}
