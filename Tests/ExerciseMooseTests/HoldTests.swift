import Foundation
import Testing
@testable import ExerciseMoose

private let now = Date()
private let soon = now.addingTimeInterval(60)

@Test("A pause holds popups until it ends")
func pauseHoldsUntilItEnds() {
    #expect(isHolding(.paused(until: soon), at: now))
    #expect(!isHolding(.paused(until: now), at: now))
}

@Test("A snooze holds popups too")
func snoozeHolds() {
    #expect(isHolding(.snoozed(until: soon), at: now))
}

@Test("No hold, nothing held")
func noHoldNothingHeld() {
    #expect(!isHolding(nil, at: now))
}

@Test("Only a pause is shown as paused")
func onlyPauseShowsAsPaused() {
    #expect(Hold.paused(until: soon).pausedUntil == soon)
    #expect(Hold.snoozed(until: soon).pausedUntil == nil)
}
