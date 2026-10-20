import Foundation
import Testing
@testable import ExerciseMoose

private let calendar = berlinCalendar()
private let office = WorkHours(isEnabled: true, startHour: 9, endHour: 18, weekdaysOnly: true)

private func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
    date(calendar, day: day, hour: hour, minute: minute)
}

@Test("A weekday morning is work time")
func weekdayMorningIsWorkTime() {
    #expect(isWorkTime(at(19, 10, 0), hours: office, calendar: calendar))
}

@Test("Before the start hour is off")
func beforeStartIsOff() {
    #expect(!isWorkTime(at(19, 8, 59), hours: office, calendar: calendar))
}

@Test("The end hour is exclusive")
func endHourIsExclusive() {
    #expect(!isWorkTime(at(19, 18, 0), hours: office, calendar: calendar))
}

@Test("Weekends are off")
func weekendsAreOff() {
    #expect(!isWorkTime(at(24, 10, 0), hours: office, calendar: calendar))
}

@Test("Weekends count when allowed")
func weekendsCountWhenAllowed() {
    let everyDay = WorkHours(isEnabled: true, startHour: 9, endHour: 18, weekdaysOnly: false)
    #expect(isWorkTime(at(24, 10, 0), hours: everyDay, calendar: calendar))
}

@Test("Turned off means always on")
func turnedOffMeansAlwaysOn() {
    let off = WorkHours(isEnabled: false, startHour: 9, endHour: 18, weekdaysOnly: true)
    #expect(isWorkTime(at(24, 3, 0), hours: off, calendar: calendar))
}

@Test("Early morning waits until 9:00 the same day")
func earlyMorningWaitsForStart() {
    #expect(nextWorkStart(after: at(20, 7, 30), hours: office, calendar: calendar) == at(20, 9, 0))
}

@Test("Friday evening waits until Monday 9:00")
func fridayEveningWaitsForMonday() {
    #expect(nextWorkStart(after: at(23, 19, 0), hours: office, calendar: calendar) == at(26, 9, 0))
}
