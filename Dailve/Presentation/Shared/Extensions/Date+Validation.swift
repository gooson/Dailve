import Foundation

extension Date {
    /// Whether this date is in the future compared to now.
    /// Allows a 60-second tolerance to avoid false positives
    /// from DatePicker minute-level precision.
    var isFuture: Bool { self > Date().addingTimeInterval(60) }

    /// Short relative label for historical data display (e.g. "Yesterday", "3 days ago")
    var relativeLabel: String? {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return nil }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: self), to: calendar.startOfDay(for: Date())).day ?? 0
        if days > 1 { return "\(days) days ago" }
        return nil
    }
}
