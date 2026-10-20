import Foundation

// "Move while your AI codes": AI coding tools call `ExerciseMoose --agent [start|stop]` from their hooks;
// that command only forwards a start/stop signal to the running app and prints nothing.

let AGENT_NOTIFICATION = Notification.Name("com.appdevelopment.exercisemoose.agent")
let AGENT_MIN_RUN: TimeInterval = 60
let TEST_AGENT_MIN_RUN: TimeInterval = 5
let AGENT_COOLDOWN: TimeInterval = 15 * 60
let TEST_AGENT_COOLDOWN: TimeInterval = 20
let AGENT_STALE_AFTER: TimeInterval = 3 * 60 * 60  // a session that never sent "stop" is forgotten
let DEFAULT_AGENT_NAME = "Claude"
let MAX_AGENT_SESSIONS = 50
let MAX_LABEL_LENGTH = 40

/// Text from local signals shown in the UI: printable characters only, capped in length.
func sanitizedLabel(_ text: String) -> String {
    String(String.UnicodeScalarView(text.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) })
        .prefix(MAX_LABEL_LENGTH))
}

enum AgentEvent: String {
    case start, stop
}

/// Maps Claude Code hook events to start/stop. "Notification" means Claude is waiting for you.
func agentEvent(fromHookName name: String?) -> AgentEvent? {
    switch name {
    case "UserPromptSubmit": .start
    case "Stop", "SessionEnd", "Notification": .stop
    default: nil
    }
}

/// Running agent sessions by id, with when each started. Every change returns a new value.
struct AgentSessions {
    let started: [String: Date]

    static let none = AgentSessions(started: [:])

    var isEmpty: Bool { started.isEmpty }

    /// Ignores new sessions beyond MAX_AGENT_SESSIONS, so a flood of signals can't grow this without bound.
    func starting(_ id: String, at date: Date) -> AgentSessions {
        guard started[id] != nil || started.count < MAX_AGENT_SESSIONS else { return self }
        return AgentSessions(started: started.merging([id: date]) { earlier, _ in earlier })
    }

    func stopping(_ id: String) -> AgentSessions {
        AgentSessions(started: started.filter { $0.key != id })
    }

    func pruned(at now: Date) -> AgentSessions {
        AgentSessions(started: started.filter { now.timeIntervalSince($0.value) < AGENT_STALE_AFTER })
    }

    func longestRun(at now: Date) -> TimeInterval {
        started.values.map { now.timeIntervalSince($0) }.max() ?? 0
    }
}

func shouldShowAgentBreak(longestRun: TimeInterval, minRun: TimeInterval, sinceLastAgentBreak: TimeInterval,
                          cooldown: TimeInterval, isPopupVisible: Bool, isEnabled: Bool, isHeld: Bool) -> Bool {
    isEnabled && !isHeld && !isPopupVisible && longestRun >= minRun && sinceLastAgentBreak >= cooldown
}

/// `ExerciseMoose --agent [start|stop] [--name Codex]`. With no event given, reads the Claude Code hook
/// JSON from stdin. Never exits with 2: for Claude Code that would block your prompt.
func runAgentCommand(arguments: [String]) -> Int32 {
    let payload = readHookPayload()
    let explicitEvent = arguments.first.flatMap(AgentEvent.init(rawValue:))
    guard let event = explicitEvent ?? agentEvent(fromHookName: payload["hook_event_name"] as? String) else {
        return explicitEvent == nil && arguments.isEmpty ? 0 : usageError()  // unknown hook events: ignore quietly
    }
    let nameFlag = arguments.firstIndex(of: "--name").map { arguments.index(after: $0) }
    let name = nameFlag.flatMap { arguments.indices.contains($0) ? arguments[$0] : nil } ?? DEFAULT_AGENT_NAME
    let session = payload["session_id"] as? String ?? name
    DistributedNotificationCenter.default().postNotificationName(
        AGENT_NOTIFICATION, object: nil,
        userInfo: ["event": event.rawValue, "session": session, "name": name], deliverImmediately: true)
    return 0
}

private func readHookPayload() -> [String: Any] {
    guard isatty(STDIN_FILENO) == 0 else { return [:] }  // run by hand: nothing piped in
    let data = FileHandle.standardInput.readDataToEndOfFile()
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
}

private func usageError() -> Int32 {
    FileHandle.standardError.write(Data("usage: ExerciseMoose --agent [start|stop] [--name <tool>]\n".utf8))
    return 1
}
