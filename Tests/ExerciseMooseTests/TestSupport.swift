import Foundation

/// A fixed timezone so date tests give the same answer on every machine.
/// October 2026: 19 = Monday, 23 = Friday, 24 = Saturday.
func berlinCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
    return calendar
}

func date(_ calendar: Calendar, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
    DateComponents(calendar: calendar, year: 2026, month: 10, day: day, hour: hour, minute: minute).date ?? Date()
}
