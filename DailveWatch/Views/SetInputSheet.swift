import SwiftUI
import WatchKit

/// Dedicated sheet for weight/reps input with Digital Crown support.
/// Crown controls weight, +/- buttons control reps.
struct SetInputSheet: View {
    @Binding var weight: Double
    @Binding var reps: Int
    @Environment(\.dismiss) private var dismiss

    /// Tracks last haptic play time for debouncing rapid taps.
    @State private var lastHapticDate: Date = .distantPast

    var body: some View {
        VStack(spacing: 10) {
            // Weight section
            weightSection

            Divider()
                .padding(.vertical, 2)

            // Reps section
            repsSection

            // Done button
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(minHeight: 36)
        }
        .padding(.horizontal, 8)
        .focusable()
        .digitalCrownRotation($weight, from: 0, through: 500, by: 2.5, sensitivity: .medium)
        // P1: Clamp weight to valid range — `through` is a soft limit (correction #22)
        .onChange(of: weight) { _, newValue in
            let clamped = min(max(newValue, 0), 500)
            if clamped != newValue {
                weight = clamped
            }
        }
    }

    // MARK: - Weight Section

    private var weightSection: some View {
        VStack(spacing: 6) {
            Text("Weight (kg)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("\(weight, specifier: "%.1f")")
                .font(.system(.title, design: .rounded).monospacedDigit().bold())
                .foregroundStyle(.green)
                .contentTransition(.numericText())

            HStack(spacing: 6) {
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
                .frame(minWidth: 36, minHeight: 28)
        }
        .buttonStyle(.bordered)
        .tint(.gray)
    }

    // MARK: - Reps Section

    private var repsSection: some View {
        VStack(spacing: 6) {
            Text("Reps")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    if reps > 0 {
                        reps -= 1
                        playDebouncedHaptic()
                    }
                } label: {
                    Text("-")
                        .font(.title3.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Text("\(reps)")
                    .font(.system(.title, design: .rounded).monospacedDigit().bold())
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())
                    .frame(minWidth: 40)

                Button {
                    if reps < 100 {
                        reps += 1
                        playDebouncedHaptic()
                    }
                } label: {
                    Text("+")
                        .font(.title3.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
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
