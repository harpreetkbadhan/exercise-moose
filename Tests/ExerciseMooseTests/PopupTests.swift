import AppKit
import Foundation
import Testing
@testable import ExerciseMoose

private let neckStretch = BUILT_IN_EXERCISES[0]
private let squats = BUILT_IN_EXERCISES.first { $0.posture == .standing } ?? BUILT_IN_EXERCISES[0]

@Test("VoiceOver hears which break it is")
func announcementNamesTheBreak() {
    #expect(popupAnnouncement(for: neckStretch, chipText: nil) == "Seated break: Neck Stretch")
    #expect(popupAnnouncement(for: squats, chipText: nil) == "Stand-up break: \(squats.name)")
}

@Test("An agent or limit break says why it appeared")
func announcementUsesTheChip() {
    #expect(popupAnnouncement(for: neckStretch, chipText: "Claude is working") == "Claude is working: Neck Stretch")
}

// MARK: Step-by-step guidance

@Test("The timer walks through the tips in equal parts")
func stepFillsWalkTheTips() {
    #expect(stepFills(remaining: 30, total: 30, steps: 3) == [0, 0, 0])
    #expect(stepFills(remaining: 25, total: 30, steps: 3) == [0.5, 0, 0])
    #expect(stepFills(remaining: 15, total: 30, steps: 3) == [1, 0.5, 0])
    #expect(stepFills(remaining: 0, total: 30, steps: 3) == [1, 1, 1])
}

@Test("The current step is the one filling; none once time is up")
func currentStepFollowsTheTimer() {
    #expect(currentStep(remaining: 30, total: 30, steps: 3) == 0)
    #expect(currentStep(remaining: 20, total: 30, steps: 3) == 1)
    #expect(currentStep(remaining: 1, total: 30, steps: 3) == 2)
    #expect(currentStep(remaining: 0, total: 30, steps: 3) == nil)
}

@Test("Odd timings never break the steps")
func stepFillsHandleOddTimings() {
    #expect(stepFills(remaining: 5, total: 0, steps: 3) == [1, 1, 1])
    #expect(stepFills(remaining: -4, total: 30, steps: 2) == [1, 1])
    #expect(stepFills(remaining: 40, total: 30, steps: 2) == [0, 0])
    #expect(stepFills(remaining: 10, total: 30, steps: 0).isEmpty)
}

@Test("VoiceOver hears where each step stands")
func stepLabelsSayWhereTheyStand() {
    #expect(stepAccessibilityLabel(index: 1, count: 3, tip: "Tilt ear toward shoulder", fill: 0.4, isCurrent: true)
        == "Step 2 of 3, current: Tilt ear toward shoulder")
    #expect(stepAccessibilityLabel(index: 0, count: 3, tip: "Sit tall", fill: 1, isCurrent: false)
        == "Step 1 of 3, done: Sit tall")
    #expect(stepAccessibilityLabel(index: 2, count: 3, tip: "Hold 15s each side", fill: 0, isCurrent: false)
        == "Step 3 of 3: Hold 15s each side")
}

// MARK: Figures stand on the field's edge

@Test("Transparent margins are trimmed so the figure stands on the edge")
func transparentMarginsAreTrimmed() {
    let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { _ in
        NSColor.black.setFill()
        NSRect(x: 4, y: 3, width: 6, height: 8).fill()
        return true
    }
    let trimmed = trimmingTransparentEdges(image)
    #expect(trimmed.size.width == 6 && trimmed.size.height == 8)
}

@Test("A picture with nothing to trim keeps its size")
func opaquePictureKeepsItsSize() {
    let image = NSImage(size: NSSize(width: 12, height: 9), flipped: false) { rect in
        NSColor.red.setFill()
        rect.fill()
        return true
    }
    #expect(trimmingTransparentEdges(image).size == NSSize(width: 12, height: 9))
}

// MARK: What a card stamps before it leaves

@Test("Done stamps today's count")
func doneStampsTodaysCount() {
    let stamp = Stamp.counted(today: 3, goal: 6)
    #expect(stamp.headline == "Nice!" && stamp.figure == "3" && stamp.detail == "of 6 today")
}

@Test("Reaching the goal says so")
func doneStampsGoalReached() {
    #expect(Stamp.counted(today: 6, goal: 6).detail == "today. Goal reached")
}

@Test("Snooze stamps when it comes back")
func snoozeStampsReturnTime() {
    let calendar = berlinCalendar()
    let stamp = Stamp.snoozed(until: date(calendar, day: 19, hour: 21, minute: 45))
    #expect(stamp.headline == "Back at" && stamp.detail == "Snoozed")
    #expect(!stamp.figure.isEmpty)
}

@Test("An agent's finish names the agent")
func agentDoneStampsTheAgent() {
    #expect(Stamp.agentDone(name: "Claude").headline == "Claude is done")
}

@Test("An agent waiting on you says it needs you")
func agentWaitingStampsNeedsYou() {
    #expect(Stamp.agentDone(name: "Claude", isWaiting: true).headline == "Claude needs you")
}

// MARK: Field colors

@Test("Each exercise type owns its own field colour")
func kindsOwnDistinctFields() {
    let fields = [ExerciseKind.stretch, .strength, .move].map { $0.field.usingColorSpace(.sRGB)?.description ?? "" }
    #expect(Set(fields).count == 3)
}

@Test("Text on every field meets contrast for its size")
func fieldInkHasContrast() {
    for kind in [ExerciseKind.stretch, .strength, .move] {
        #expect(contrastRatio(kind.field, kind.fieldInk) >= 4.5, "\(kind) ink on field")
    }
    #expect(contrastRatio(DONE_RED, .white) >= 4.5)
}

@Test("The countdown ring reads as time left")
func ringReadsAsTimeLeft() {
    #expect(countdownAccessibilityLabel(remaining: 23) == "23 seconds left")
    #expect(countdownAccessibilityLabel(remaining: 1) == "1 second left")
    #expect(countdownAccessibilityLabel(remaining: 0) == "Time's up")
}
