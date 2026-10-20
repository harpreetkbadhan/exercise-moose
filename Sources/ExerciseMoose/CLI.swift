import AppKit

// The `moose` terminal command: a symlink to this app's program. Invoked under that name it talks to the
// running app instead of starting a second one.

let BUNDLE_ID = "com.appdevelopment.exercisemoose"
let CLI_NAME = "moose"
let COMMAND_NOTIFICATION = Notification.Name("com.appdevelopment.exercisemoose.command")
let NEXT_BREAK_KEY = "nextBreakAt"
let OFF_UNTIL_KEY = "offUntil"
let PAUSED_UNTIL_KEY = "pausedUntil"
let CLAUDE_LINES_KEY = "claudeUsageLines"
let DEFAULT_PAUSE_MINUTES = 60
let MAX_PAUSE_MINUTES = 24 * 60
let FALLBACK_DAILY_GOAL = 6

let MOOSE_HELP = """
moose: Exercise Moose from your terminal

  moose              status, or start the app if it isn't running
  moose start        start the app
  moose status       next break, streak and Claude Code usage
  moose break        show a break now
  moose pause [min]  pause reminders (default \(DEFAULT_PAUSE_MINUTES) min, up to \(MAX_PAUSE_MINUTES))
  moose resume       turn reminders back on
  moose quit         quit the app
  moose help         this help
"""

enum MooseCommand: Equatable {
    case start, status, breakNow, pause(minutes: Int), resume, quit, help
}

func parseMooseCommand(_ args: [String]) -> MooseCommand? {
    switch args.first {
    case nil, "status": return .status
    case "start", "open": return .start
    case "break", "now": return .breakNow
    case "resume": return .resume
    case "quit", "stop": return .quit
    case "help", "-h", "--help": return .help
    case "pause":
        guard args.count > 1 else { return .pause(minutes: DEFAULT_PAUSE_MINUTES) }
        return Int(args[1]).flatMap { (1...MAX_PAUSE_MINUTES).contains($0) ? .pause(minutes: $0) : nil }
    default: return nil
    }
}

/// Minutes in a `moose pause` signal. Any process can send one, so they're clamped to 1...MAX_PAUSE_MINUTES
/// (a huge value would otherwise overflow, and crash the app, when turned into seconds). Text that isn't a
/// whole number, including one too big for Int, means the default.
func pauseMinutes(fromSignal value: Any?) -> Int {
    min(max(1, Int(value as? String ?? "") ?? DEFAULT_PAUSE_MINUTES), MAX_PAUSE_MINUTES)
}

func isInvokedAsCLI(_ args: [String]) -> Bool {
    URL(fileURLWithPath: args.first ?? "").lastPathComponent == CLI_NAME
}

/// The app's own settings, also when read through the `moose` symlink (where Bundle.main may differ).
func appDefaults() -> UserDefaults {
    Bundle.main.bundleIdentifier == BUNDLE_ID ? .standard : (UserDefaults(suiteName: BUNDLE_ID) ?? .standard)
}

/// Lines for `moose status`.
func statusReport(nextBreak: Date?, offUntil: Date?, pausedUntil: Date?, counts: [String: Int], goal: Int,
                  claudeLines: [String], now: Date, calendar: Calendar = .current) -> [String] {
    let next: String
    if let pausedUntil, pausedUntil > now {
        next = pausedUntilText(pausedUntil, now: now, calendar: calendar)
    } else if let offUntil, offUntil > now {
        next = offUntilText(offUntil, now: now, calendar: calendar)
    } else if let nextBreak, nextBreak > now {
        next = "Next break in \(max(1, Int((nextBreak.timeIntervalSince(now) / 60).rounded(.up)))) min"
    } else {
        next = "Break time now"
    }
    let today = counts[dayKey(now, calendar: calendar)] ?? 0
    let days = streak(counts: counts, today: now, calendar: calendar)
    let progress = days > 0 ? "\(days)-day streak, \(today) of \(goal) today" : "\(today) of \(goal) today"
    let indented = claudeLines.enumerated().map { index, line in index == 0 ? line : "   " + line }
    return [next, progress] + indented
}

func runMooseCommand(_ args: [String]) -> Int32 {
    guard let command = parseMooseCommand(args) else {
        print(MOOSE_HELP)
        return 1
    }
    let isRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: BUNDLE_ID).isEmpty
    switch command {
    case .help:
        print(MOOSE_HELP)
        return 0
    case .start:
        return openApp()
    case .status where !isRunning && args.isEmpty:
        return openApp()  // plain `moose` starts it
    default:
        guard isRunning else {
            print("Exercise Moose isn't running. Start it with: moose start")
            return 1
        }
    }
    switch command {
    case .status: print(currentStatus().joined(separator: "\n"))
    case .breakNow: send("break", "Showing a break now.")
    case .pause(let minutes): send("pause", "Paused for \(minutes) min.", minutes: minutes)
    case .resume: send("resume", "Reminders are back on.")
    case .quit: send("quit", "Exercise Moose quit.")
    case .start, .help: break
    }
    return 0
}

private func currentStatus() -> [String] {
    let defaults = appDefaults()
    let goal = defaults.integer(forKey: PrefKey.dailyGoal)
    return statusReport(nextBreak: defaults.object(forKey: NEXT_BREAK_KEY) as? Date,
                        offUntil: defaults.object(forKey: OFF_UNTIL_KEY) as? Date,
                        pausedUntil: defaults.object(forKey: PAUSED_UNTIL_KEY) as? Date,
                        counts: defaults.dictionary(forKey: STATS_KEY) as? [String: Int] ?? [:],
                        goal: goal > 0 ? goal : FALLBACK_DAILY_GOAL,
                        claudeLines: defaults.stringArray(forKey: CLAUDE_LINES_KEY) ?? [], now: Date())
}

private func send(_ command: String, _ message: String, minutes: Int = 0) {
    DistributedNotificationCenter.default().postNotificationName(
        COMMAND_NOTIFICATION, object: nil, userInfo: ["command": command, "minutes": "\(minutes)"],
        deliverImmediately: true)
    print(message)
}

private func openApp() -> Int32 {
    let open = Process()
    open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    open.arguments = ["-b", BUNDLE_ID]
    do {
        try open.run()
        open.waitUntilExit()
    } catch {
        print("Couldn't start Exercise Moose: \(error.localizedDescription)")
        return 1
    }
    if open.terminationStatus == 0 { print("Exercise Moose is running. Look for it in your menu bar.") }
    return open.terminationStatus
}

/// The app side: act on commands sent by `moose`.
extension MooseApp {
    func observeCommands() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(commandReceived(_:)),
                                                            name: COMMAND_NOTIFICATION, object: nil)
    }

    @objc func commandReceived(_ notification: Notification) {
        switch notification.userInfo?["command"] as? String {
        case "break": showBreak()
        case "pause": pause(minutes: pauseMinutes(fromSignal: notification.userInfo?["minutes"]))
        case "resume": restartTimer()
        case "quit": NSApp.terminate(nil)
        default: return
        }
    }
}
