import Foundation

// Pause (menu or `moose pause`) and snooze hold every popup until they end: the regular break,
// agent breaks and the "limit reached" walk.

enum Hold: Equatable {
    case paused(until: Date)
    case snoozed(until: Date)

    var until: Date {
        switch self {
        case .paused(let until), .snoozed(let until): until
        }
    }

    /// When a pause ends; nil for a snooze, which the menu shows as the next break instead.
    var pausedUntil: Date? {
        if case .paused(let until) = self { return until }
        return nil
    }
}

func isHolding(_ hold: Hold?, at now: Date) -> Bool {
    hold.map { $0.until > now } ?? false
}

func pausedUntilText(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
    untilText("Paused", date, now: now, calendar: calendar)
}
