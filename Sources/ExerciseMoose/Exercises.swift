import Foundation

/// Drives the popup's stage color.
enum ExerciseKind: String {
    case stretch, strength, move
}

/// Most breaks happen in your chair; a standing one comes every "stand-up interval".
enum Posture: String {
    case seated, standing
}

struct Exercise {
    let name: String
    let file: String  // <exercises folder>/<file>.mov
    let kind: ExerciseKind
    let posture: Posture
    let tips: [String]
}

let BUILT_IN_EXERCISES: [Exercise] = [
    // Seated, in your chair
    Exercise(name: "Neck Stretch", file: "neck-stretch", kind: .stretch, posture: .seated,
             tips: ["Sit tall, shoulders down", "Tilt ear toward shoulder", "Hold 15s each side"]),
    Exercise(name: "Shoulder Rolls", file: "shoulder-rolls", kind: .stretch, posture: .seated,
             tips: ["Roll back 10 times", "Then forward 10 times", "Keep your neck relaxed"]),
    Exercise(name: "Wrist Stretch", file: "wrist-stretch", kind: .stretch, posture: .seated,
             tips: ["Arm straight, palm up", "Gently pull fingers back", "Hold 15s each hand"]),
    Exercise(name: "Seated Twist", file: "torso-twist", kind: .stretch, posture: .seated,
             tips: ["Sit tall, feet flat", "Turn and hold the backrest", "Hold 15s each side"]),
    Exercise(name: "Leg Extensions", file: "seated-leg-raises", kind: .strength, posture: .seated,
             tips: ["Hold the edge of the seat", "Straighten one leg, hold 3s", "10 each leg"]),
    Exercise(name: "Seated March", file: "seated-march", kind: .move, posture: .seated,
             tips: ["Sit near the front of the chair", "Lift your knees one at a time", "Keep going for 30 seconds"]),
    Exercise(name: "Seated Cat-Cow", file: "seated-cat-cow", kind: .stretch, posture: .seated,
             tips: ["Hands on your knees", "Push chest forward, then round your back", "Slowly, 8 times"]),
    Exercise(name: "Ankle Circles", file: "ankle-circles", kind: .move, posture: .seated,
             tips: ["Lift one foot off the floor", "Circle 10 times each way", "Switch feet"]),
    Exercise(name: "Chin Tucks", file: "chin-tucks", kind: .stretch, posture: .seated,
             tips: ["Look straight ahead", "Pull your chin straight back", "Hold 3s, 10 times"]),
    Exercise(name: "Chest Opener", file: "chest-opener", kind: .stretch, posture: .seated,
             tips: ["Hands behind your head", "Open elbows wide", "Squeeze shoulder blades, hold 15s"]),
    Exercise(name: "Side Bend", file: "seated-side-bend", kind: .stretch, posture: .seated,
             tips: ["Reach one arm overhead", "Lean gently to the other side", "Hold 15s each side"]),
    Exercise(name: "Figure-4 Stretch", file: "figure-4", kind: .stretch, posture: .seated,
             tips: ["Ankle on the opposite knee", "Lean forward, back straight", "Hold 20s each side"]),
    // Standing, every stand-up interval
    Exercise(name: "10 Squats", file: "squats", kind: .strength, posture: .standing,
             tips: ["Feet shoulder-width apart", "Back straight, chest up", "Knees follow your toes"]),
    Exercise(name: "15 Calf Raises", file: "calf-raises", kind: .strength, posture: .standing,
             tips: ["Rise onto your toes", "Hold 1s at the top", "Lower slowly"]),
    Exercise(name: "10 Wall Push-ups", file: "wall-pushups", kind: .strength, posture: .standing,
             tips: ["Hands on wall, shoulder height", "Body in a straight line", "Chest to wall, push back"]),
    Exercise(name: "Hip Flexor Stretch", file: "hip-stretch", kind: .stretch, posture: .standing,
             tips: ["Step one foot back", "Squeeze glutes, push hips forward", "Hold 20s each side"]),
    Exercise(name: "Overhead Stretch", file: "overhead-stretch", kind: .stretch, posture: .standing,
             tips: ["Reach both arms straight up", "Stretch tall, hold 3 seconds", "Lower arms slowly out to the sides"]),
    Exercise(name: "Walk Break", file: "walk", kind: .move, posture: .standing,
             tips: ["Walk around for 2 minutes", "Drink some water", "Look far away to rest your eyes"]),
]

/// ~/Library/Application Support/Exercise Moose/exercises — convert.sh writes clips here.
func exercisesFolder() -> URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Exercise Moose/exercises")
}

/// The sample avatar build.sh bundles into the app (Contents/Resources/Sample), so a downloaded app works.
func sampleMediaFolder() -> URL? {
    Bundle.main.resourceURL?.appendingPathComponent("Sample")
}

/// Your own media as soon as you've added any; until then the bundled sample.
/// Never a mix, so nobody gets someone else's face for the exercises they haven't filmed.
func activeMediaFolder() -> URL {
    let user = exercisesFolder().deletingLastPathComponent()
    let hasOwnMedia = FileManager.default.fileExists(atPath: user.appendingPathComponent("character.png").path)
        || !videoFiles(in: exercisesFolder()).isEmpty
    guard !hasOwnMedia, let sample = sampleMediaFolder(),
          FileManager.default.fileExists(atPath: sample.path) else { return user }
    return sample
}

func activeExercisesFolder() -> URL {
    activeMediaFolder().appendingPathComponent("exercises")
}

/// Your character stills (green removed by convert.sh), shown when an exercise has no video yet.
func characterImageURL() -> URL {
    activeMediaFolder().appendingPathComponent("character.png")
}

func seatedCharacterImageURL() -> URL {
    activeMediaFolder().appendingPathComponent("character-seated.png")
}

func videoFiles(in dir: URL) -> [String] {
    let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    return files.filter { $0.hasSuffix(".mov") }.map { String($0.dropLast(4)) }.sorted()
}

/// Built-in exercises plus any extra .mov you drop into the exercises folder (treated as seated).
func loadExercises(dir: URL) -> [Exercise] {
    let known = Set(BUILT_IN_EXERCISES.map(\.file))
    let extras = videoFiles(in: dir)
        .filter { !known.contains($0) }
        .map { Exercise(name: $0.replacingOccurrences(of: "-", with: " ").capitalized,
                        file: $0, kind: .move, posture: .seated, tips: ["Follow along!"]) }
    return BUILT_IN_EXERCISES + extras
}

/// Standing once the stand-up interval has passed since the last standing break, otherwise seated.
func postureForNextBreak(now: Date, lastStanding: Date, standInterval: TimeInterval) -> Posture {
    now.timeIntervalSince(lastStanding) >= standInterval ? .standing : .seated
}

/// Random exercise with the given posture that isn't the one you just did. Exercises you've made a
/// video for win; the rest only appear when that posture has no videos yet.
func pickExercise(from all: [Exercise], posture: Posture, after lastFile: String?, videos: Set<String>) -> Exercise? {
    let pool = all.filter { $0.posture == posture }
    let filmed = pool.filter { videos.contains($0.file) }
    let choices = filmed.isEmpty ? pool : filmed
    let fresh = choices.filter { $0.file != lastFile }
    return (fresh.isEmpty ? choices : fresh).randomElement()
}
