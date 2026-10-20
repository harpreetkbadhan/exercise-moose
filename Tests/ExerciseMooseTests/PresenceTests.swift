import Foundation
import Testing
@testable import ExerciseMoose

@Test("Free and present: show")
func freeAndPresentShows() {
    #expect(breakDecision(isAway: false, isOnCall: false, waitForCalls: true, waitedSoFar: 0) == .show)
}

@Test("Away: wait")
func awayWaits() {
    #expect(breakDecision(isAway: true, isOnCall: false, waitForCalls: true, waitedSoFar: 0) == .wait)
}

@Test("On a call: wait")
func onCallWaits() {
    #expect(breakDecision(isAway: false, isOnCall: true, waitForCalls: true, waitedSoFar: 60) == .wait)
}

@Test("Call waiting turned off: show")
func callWaitingOffShows() {
    #expect(breakDecision(isAway: false, isOnCall: true, waitForCalls: false, waitedSoFar: 0) == .show)
}

@Test("Never wait on a call forever")
func callWaitIsCapped() {
    #expect(breakDecision(isAway: false, isOnCall: true, waitForCalls: true, waitedSoFar: MAX_CALL_WAIT) == .show)
}

@Test("A long absence resets the timer")
func longAbsenceResets() {
    #expect(shouldResetAfterAway(awayFor: AWAY_THRESHOLD, resetWhenAway: true, threshold: AWAY_THRESHOLD, isHeld: false))
}

@Test("A quick lock does not reset")
func quickLockDoesNotReset() {
    #expect(!shouldResetAfterAway(awayFor: 60, resetWhenAway: true, threshold: AWAY_THRESHOLD, isHeld: false))
}

@Test("Coming back during a pause keeps the pause")
func comingBackKeepsPause() {
    #expect(!shouldResetAfterAway(awayFor: 3600, resetWhenAway: true, threshold: AWAY_THRESHOLD, isHeld: true))
}

@Test("Resetting can be turned off")
func resetCanBeTurnedOff() {
    #expect(!shouldResetAfterAway(awayFor: 3600, resetWhenAway: false, threshold: AWAY_THRESHOLD, isHeld: false))
}
