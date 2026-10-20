import Foundation
import Testing
@testable import ExerciseMoose

private let calendar = berlinCalendar()

private func day(_ offset: Int) -> Date {
    calendar.date(byAdding: .day, value: offset, to: date(calendar, day: 19)) ?? Date()
}

private func key(_ offset: Int) -> String {
    dayKey(day(offset), calendar: calendar)
}

@Test("Day keys are zero-padded local dates")
func dayKeysAreZeroPadded() {
    #expect(key(0) == "2026-10-19")
}

@Test("No history means no streak")
func noHistoryNoStreak() {
    #expect(streak(counts: [:], today: day(0), calendar: calendar) == 0)
}

@Test("Today alone is a 1-day streak")
func todayAloneIsOneDay() {
    #expect(streak(counts: [key(0): 2], today: day(0), calendar: calendar) == 1)
}

@Test("A missed day ends the streak")
func missedDayEndsStreak() {
    #expect(streak(counts: [key(0): 1, key(-1): 3, key(-3): 1], today: day(0), calendar: calendar) == 2)
}

@Test("The streak survives until you skip a whole day")
func streakSurvivesUntilMidnight() {
    #expect(streak(counts: [key(-1): 1, key(-2): 1], today: day(0), calendar: calendar) == 2)
}

@Test("Recording adds one to today")
func recordingAddsOne() {
    #expect(recordingBreak(in: [key(0): 2], on: day(0), calendar: calendar)[key(0)] == 3)
}

@Test("Days older than the keep window are dropped")
func oldDaysAreDropped() {
    let tooOld = key(-(STATS_KEEP_DAYS + 1))
    #expect(recordingBreak(in: [key(0): 2, tooOld: 5], on: day(0), calendar: calendar)[tooOld] == nil)
}

@Test("A long streak keeps counting past two months")
func longStreakKeepsCounting() {
    let history = (-99...0).reduce([String: Int]()) { counts, offset in
        recordingBreak(in: counts, on: day(offset), calendar: calendar)
    }
    #expect(streak(counts: history, today: day(0), calendar: calendar) == 100)
}

@Test("The chart runs oldest to newest")
func chartRunsOldestToNewest() {
    let week = lastDays(counts: [key(0): 4, key(-6): 1], today: day(0), calendar: calendar)
    #expect(week.count == CHART_DAYS && week.first?.count == 1 && week.last?.count == 4)
}
