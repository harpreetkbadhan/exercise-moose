import Foundation
import Testing
@testable import ExerciseMoose

private let calendar = berlinCalendar()
private let now = date(calendar, day: 19, hour: 11)

@Test("Basic commands")
func basicCommands() {
    #expect(parseMooseCommand([]) == .status && parseMooseCommand(["break"]) == .breakNow)
}

@Test("Pause defaults to an hour")
func pauseDefaultsToAnHour() {
    #expect(parseMooseCommand(["pause"]) == .pause(minutes: DEFAULT_PAUSE_MINUTES))
}

@Test("Pause takes minutes")
func pauseTakesMinutes() {
    #expect(parseMooseCommand(["pause", "30"]) == .pause(minutes: 30))
}

@Test("Bad input is rejected")
func badInputIsRejected() {
    #expect(parseMooseCommand(["pause", "-5"]) == nil && parseMooseCommand(["dance"]) == nil)
}

@Test("Pause goes up to a day")
func pauseGoesUpToADay() {
    #expect(parseMooseCommand(["pause", "\(MAX_PAUSE_MINUTES)"]) == .pause(minutes: MAX_PAUSE_MINUTES))
    #expect(parseMooseCommand(["pause", "\(MAX_PAUSE_MINUTES + 1)"]) == nil)
}

@Test("A huge pause is rejected instead of overflowing")
func hugePauseIsRejected() {
    #expect(parseMooseCommand(["pause", "200000000000000000"]) == nil)
}

@Test("Minutes in a pause signal are clamped, whoever sent it")
func pauseSignalMinutesAreClamped() {
    #expect(pauseMinutes(fromSignal: "30") == 30)
    #expect(pauseMinutes(fromSignal: "200000000000000000") == MAX_PAUSE_MINUTES)
    #expect(pauseMinutes(fromSignal: "0") == 1)
    #expect(pauseMinutes(fromSignal: "-5") == 1)
}

@Test("A pause signal without readable minutes pauses for the default")
func pauseSignalWithoutMinutesUsesDefault() {
    #expect(pauseMinutes(fromSignal: nil) == DEFAULT_PAUSE_MINUTES)
    #expect(pauseMinutes(fromSignal: "soon") == DEFAULT_PAUSE_MINUTES)
    #expect(pauseMinutes(fromSignal: "99999999999999999999999") == DEFAULT_PAUSE_MINUTES)
}

@Test("The moose symlink switches to terminal mode")
func symlinkSwitchesToTerminalMode() {
    #expect(isInvokedAsCLI(["/usr/local/bin/moose"]) && !isInvokedAsCLI(["/A.app/Contents/MacOS/ExerciseMoose"]))
}

@Test("Status lines")
func statusLines() {
    let report = statusReport(nextBreak: now.addingTimeInterval(23 * 60), offUntil: nil, pausedUntil: nil,
                              counts: [dayKey(now, calendar: calendar): 2], goal: 6,
                              claudeLines: ["Claude Code: Opus"], now: now, calendar: calendar)
    #expect(report == ["Next break in 23 min", "1-day streak, 2 of 6 today", "Claude Code: Opus"])
}

@Test("Off hours and no streak")
func offHoursAndNoStreak() {
    let off = statusReport(nextBreak: nil, offUntil: now.addingTimeInterval(3600), pausedUntil: nil, counts: [:],
                           goal: 6, claudeLines: [], now: now, calendar: calendar)
    #expect(off.first?.hasPrefix("Off until") == true && off.last == "0 of 6 today")
}

@Test("A pause shows in the status until it ends")
func pauseShowsInStatus() {
    let hourLater = now.addingTimeInterval(3600)
    let paused = statusReport(nextBreak: hourLater, offUntil: nil, pausedUntil: hourLater, counts: [:], goal: 6,
                              claudeLines: [], now: now, calendar: calendar)
    #expect(paused.first?.hasPrefix("Paused until") == true)
}

@Test("A pause that has ended is ignored")
func endedPauseIsIgnored() {
    let report = statusReport(nextBreak: now.addingTimeInterval(23 * 60), offUntil: nil,
                              pausedUntil: now.addingTimeInterval(-60), counts: [:], goal: 6, claudeLines: [],
                              now: now, calendar: calendar)
    #expect(report.first == "Next break in 23 min")
}
