import Foundation
import Testing
@testable import ExerciseMoose

private let calendar = berlinCalendar()
private let now = date(calendar, day: 19, hour: 11)

private func status(nextBreak: Date? = nil, pausedUntil: Date? = nil, offUntil: Date? = nil, waiting: Bool = false,
                    showing: Bool = false) -> BreakStatus {
    breakStatus(nextBreak: nextBreak, pausedUntil: pausedUntil, offUntil: offUntil, isWaitingForCall: waiting,
                isShowing: showing, now: now, calendar: calendar)
}

// MARK: Next break

@Test("The next break shows its minutes")
func nextBreakShowsMinutes() {
    #expect(status(nextBreak: now.addingTimeInterval(30 * 60)) == BreakStatus(label: "Next break", figure: "30", unit: "min"))
}

@Test("A pause says until when")
func pauseSaysUntilWhen() {
    let paused = status(nextBreak: now.addingTimeInterval(3600), pausedUntil: now.addingTimeInterval(3600))
    #expect(paused.label == "Paused until" && !paused.figure.isEmpty)
}

@Test("Off hours say when reminders come back")
func offHoursSayWhen() {
    #expect(status(offUntil: now.addingTimeInterval(20 * 3600)).label == "Off until")
}

@Test("A call holds the break")
func callHoldsTheBreak() {
    #expect(status(nextBreak: now.addingTimeInterval(60), waiting: true).figure == "Waiting")
}

@Test("A break on screen is now")
func breakOnScreenIsNow() {
    #expect(status(nextBreak: now.addingTimeInterval(600), showing: true).figure == "Now")
}

// MARK: Streak

@Test("The streak reads in days, with today's count")
func streakReadsInDays() {
    let today = dayKey(now, calendar: calendar)
    let yesterday = dayKey(now.addingTimeInterval(-86_400), calendar: calendar)
    #expect(streakStatus(counts: [today: 6], goal: 6, now: now, calendar: calendar)
        == BreakStatus(label: "Streak", figure: "1 day", unit: "6 of 6 today"))
    #expect(streakStatus(counts: [today: 2, yesterday: 4], goal: 6, now: now, calendar: calendar).figure == "2 days")
}

@Test("No streak yet shows today's count")
func noStreakShowsToday() {
    #expect(streakStatus(counts: [:], goal: 6, now: now, calendar: calendar)
        == BreakStatus(label: "Today", figure: "0 of 6", unit: "breaks"))
}

// MARK: Claude usage

private let reset = now.addingTimeInterval(2 * 3600)
private let usage = parseClaudeUsage([
    "session_id": "s1",
    "model": ["display_name": "Opus 5.5"],
    "context_window": ["used_percentage": 43.0, "context_window_size": 1_000_000],
    "rate_limits": ["five_hour": ["used_percentage": 71, "resets_at": reset.timeIntervalSince1970],
                    "seven_day": ["used_percentage": 85.0, "resets_at": reset.timeIntervalSince1970 + 86_400 * 3]],
], now: now)

@Test("Usage becomes one bar per limit, with resets")
func usageBecomesBars() {
    let rows = usageRows(usage, now: now, calendar: calendar)
    #expect(rows.map(\.label) == ["Context", "5-hour", "Weekly"])
    #expect(rows[0].percent == 43 && rows[0].detail == "of 1M")
    #expect(rows[1].detail.hasPrefix("resets ") && !rows[1].isHigh)
    #expect(rows[2].isHigh)
}

@Test("A nearly full context suggests /compact")
func fullContextSuggestsCompact() {
    let full = parseClaudeUsage(["context_window": ["used_percentage": 93, "context_window_size": 200_000]], now: now)
    #expect(usageRows(full, now: now, calendar: calendar).first?.detail == "of 200k, time to /compact")
}

@Test("Missing limits are simply left out")
func missingLimitsAreLeftOut() {
    let bare = parseClaudeUsage(["context_window": ["used_percentage": 10]], now: now)
    #expect(usageRows(bare, now: now, calendar: calendar).map(\.label) == ["Context"])
}
