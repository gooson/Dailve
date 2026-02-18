import SwiftUI
import WatchKit

/// Dedicated sheet for weight/reps input with Digital Crown support.
/// Crown controls weight, +/- buttons adjust reps.
/// Layout is compact to fit all elements on screen without scrolling.
struct SetInputSheet: View {
    @Binding var weight: Double
    @Binding var reps: Int
    @Environment(\.dismiss) private var dismiss

    /// Tracks last haptic play time for debouncing rapid taps.
    @State private var lastHapticDate: Date = .distantPast

    var body: some View {
        VStack(spacing: 6) {
            // Weight section
            weightSection

            Divider()

            // Reps section
            repsSection

            // Done button
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
        }
        .padding(.horizontal, 8)
        .focusable()
        .digitalCrownRotation($weight, from: 0, through: 500, by: 2.5, sensitivity: .medium)
        .onChange(of: weight) { _, newValue in
            let clamped = min(max(newValue, 0), 500)
            if clamped != newValue {
                weight = clamped
            }
        }
    }

    // MARK: - Weight Section

    private var weightSection: some View {
        VStack(spacing: 4) {
            Text("Weight (kg)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("\(weight, specifier: "%.1f")")
                .font(.system(.title2, design: .rounded).monospacedDigit().bold())
                .foregroundStyle(.green)
                .contentTransition(.numericText())

            HStack(spacing: 4) {
                weightButton("-5", delta: -5)
                weightButton("-2.5", delta: -2.5)
                weightButton("+2.5", delta: 2.5)
                weightButton("+5", delta: 5)
            }
        }
    }

    private func weightButton(_ label: String, delta: Double) -> some View {
        Button {
            let newValue = weight + delta
            if (0...500).contains(newValue) {
                weight = newValue
                playDebouncedHaptic()
            }
        } label: {
            Text(label)
                .font(.caption2.weight(.medium))
                .frame(minWidth: 34, minHeight: 24)
        }
        .buttonStyle(.bordered)
        .tint(.gray)
    }

    // MARK: - Reps Section

    private var repsSection: some View {
        HStack(spacing: 12) {
            Button {
                if reps > 0 {
                    reps -= 1
                    playDebouncedHaptic()
                }
            } label: {
                Text("-")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 40, minHeight: 40)
            }
            .buttonStyle(.bordered)
            .tint(.gray)

            VStack(spacing: 1) {
                Text("\(reps)")
                    .font(.system(.title2, design: .rounded).monospacedDigit().bold())
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())
                Text("reps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 50)

            Button {
                if reps < 100 {
                    reps += 1
                    playDebouncedHaptic()
                }
            } label: {
                Text("+")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 40, minHeight: 40)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
        }
    }

    // MARK: - Haptic

    /// Debounced haptic — skips if last play was < 100ms ago.
    private func playDebouncedHaptic() {
        let now = Date()
        guard now.timeIntervalSince(lastHapticDate) >= 0.1 else { return }
        lastHapticDate = now
        WKInterfaceDevice.current().play(.click)
    }
}
