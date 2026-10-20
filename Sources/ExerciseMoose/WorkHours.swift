import Foundation

let HOURS_PER_WEEK = 7 * 24

/// When reminders are allowed. Start and end are whole hours; end is exclusive (18 means until 18:00).
struct WorkHours {
    let isEnabled: Bool
    let startHour: Int
    let endHour: Int
    let weekdaysOnly: Bool
}

func isWorkTime(_ date: Date, hours: WorkHours, calendar: Calendar = .current) -> Bool {
    guard hours.isEnabled else { return true }
    let hour = calendar.component(.hour, from: date)
    let isAllowedDay = !(hours.weekdaysOnly && calendar.isDateInWeekend(date))
    return isAllowedDay && hour >= hours.startHour && hour < hours.endHour
}

/// The next hour at which work time begins, looking up to a week ahead; nil if the hours never allow it.
func nextWorkStart(after date: Date, hours: WorkHours, calendar: Calendar = .current) -> Date? {
    let startOfHour = calendar.dateInterval(of: .hour, for: date)?.start ?? date
    return (1...HOURS_PER_WEEK).lazy
        .compactMap { calendar.date(byAdding: .hour, value: $0, to: startOfHour) }
        .first { isWorkTime($0, hours: hours, calendar: calendar) }
}

/// "<label> until 9:00" today, "<label> until Mon 9:00" on another day — for the menu and `moose status`.
func untilText(_ label: String, _ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
    let style: Date.FormatStyle = calendar.isDate(date, inSameDayAs: now)
        ? .dateTime.hour().minute()
        : .dateTime.weekday(.abbreviated).hour().minute()
    return "\(label) until \(date.formatted(style))"
}

func offUntilText(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
    untilText("Off", date, now: now, calendar: calendar)
}
