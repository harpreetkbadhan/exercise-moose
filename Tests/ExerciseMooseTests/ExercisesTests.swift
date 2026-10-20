import Foundation
import Testing
@testable import ExerciseMoose

private let hour: TimeInterval = 3600

@Test("Before the stand-up interval the next break is seated")
func seatedBeforeStandInterval() {
    let now = Date()
    #expect(postureForNextBreak(now: now, lastStanding: now.addingTimeInterval(-hour), standInterval: 2 * hour) == .seated)
}

@Test("Once the stand-up interval has passed the next break is standing")
func standingAfterStandInterval() {
    let now = Date()
    #expect(postureForNextBreak(now: now, lastStanding: now.addingTimeInterval(-2 * hour), standInterval: 2 * hour)
        == .standing)
}

@Test("Most exercises are seated")
func mostExercisesAreSeated() {
    let seatedCount = BUILT_IN_EXERCISES.filter { $0.posture == .seated }.count
    #expect(seatedCount > BUILT_IN_EXERCISES.count / 2)
}

@Test("A seated pick is never a repeat")
func seatedPickNeverRepeats() {
    for _ in 0..<500 {
        let pick = pickExercise(from: BUILT_IN_EXERCISES, posture: .seated, after: "neck-stretch", videos: [])
        #expect(pick?.posture == .seated && pick?.file != "neck-stretch")
    }
}

@Test("Exercises with a video win, still no repeat")
func filmedExercisesWin() {
    for _ in 0..<500 {
        let pick = pickExercise(from: BUILT_IN_EXERCISES, posture: .seated, after: "neck-stretch",
                                videos: ["neck-stretch", "shoulder-rolls", "squats"])
        #expect(pick?.file == "shoulder-rolls")
    }
}

@Test("A posture without videos falls back to all its exercises")
func postureWithoutVideosUsesAll() {
    let pick = pickExercise(from: BUILT_IN_EXERCISES, posture: .standing, after: nil, videos: ["neck-stretch"])
    #expect(pick?.posture == .standing)
}

@Test("A single exercise is still picked")
func singleExerciseIsPicked() {
    let single = [BUILT_IN_EXERCISES[0]]
    #expect(pickExercise(from: single, posture: .seated, after: single[0].file, videos: [])?.file == single[0].file)
}

@Test("No exercise with that posture gives nil")
func noMatchingPostureGivesNil() {
    #expect(pickExercise(from: [BUILT_IN_EXERCISES[0]], posture: .standing, after: nil, videos: []) == nil)
}

@Test("A missing folder falls back to the built-in exercises")
func missingFolderUsesBuiltIns() {
    #expect(loadExercises(dir: URL(fileURLWithPath: "/nonexistent")).count == BUILT_IN_EXERCISES.count)
}

@Test("An unknown popup size doesn't parse")
func unknownPopupSizeIsRejected() {
    #expect(PopupSize(rawValue: "bogus") == nil)
}
