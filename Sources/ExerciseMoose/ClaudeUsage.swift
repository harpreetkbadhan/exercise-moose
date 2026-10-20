import Foundation

// Claude Code usage (context window, 5-hour and weekly limits) from its official status line data.
// `ExerciseMoose --statusline` copies those numbers to the app, then runs your original status line
// with the same input, so whatever you had there keeps working.

let USAGE_NOTIFICATION = Notification.Name("com.appdevelopment.exercisemoose.usage")
let USAGE_WARNING_PERCENT = 80.0
let USAGE_WARNING_SUFFIX = ", high"  // marks a line running high in `moose status`
let CONTEXT_COMPACT_PERCENT = 90.0
let LIMIT_REACHED_PERCENT = 100.0
let USAGE_STALE_AFTER: TimeInterval = 2 * 60 * 60
let USAGE_FRESH_SECONDS: TimeInterval = 60
let MAX_USAGE_SESSIONS = MAX_AGENT_SESSIONS
let ORIGINAL_STATUSLINE_FILE = "claude-statusline-original.json"
let MAX_USAGE_NUMBER = 1e13  // well above any real token count or timestamp in milliseconds
let PRIVATE_FILE_PERMISSIONS = 0o600
let DIAGNOSTICS_FLAG_FILE = "debug-statusline"  // create this empty file to turn diagnostics on
let DIAGNOSTICS_FILE = "statusline-fields.json"

struct ClaudeUsage {
    let sessionId: String
    let model: String?
    let contextPercent: Double?
    let contextSize: Int?
    let fiveHourPercent: Double?
    let fiveHourResetsAt: Date?
    let weeklyPercent: Double?
    let weeklyResetsAt: Date?
    let updatedAt: Date
}

/// Numbers from the status line, or nil for anything that isn't a sane finite value
/// (signals are local but any process can send them, and Int(NaN) would crash).
func usageNumber(_ value: Any?) -> Double? {
    let number = (value as? NSNumber)?.doubleValue ?? (value as? String).flatMap(Double.init)
    guard let number, number.isFinite, abs(number) < MAX_USAGE_NUMBER else { return nil }
    return number
}

/// Reset times arrive as Unix seconds (or milliseconds) or ISO 8601 text.
func usageDate(_ value: Any?) -> Date? {
    if let seconds = usageNumber(value) {
        return Date(timeIntervalSince1970: seconds > 1e12 ? seconds / 1000 : seconds)
    }
    return (value as? String).flatMap { try? Date($0, strategy: .iso8601) }
}

func parseClaudeUsage(_ json: [String: Any], now: Date) -> ClaudeUsage {
    let context = json["context_window"] as? [String: Any]
    let limits = json["rate_limits"] as? [String: Any]
    let fiveHour = limits?["five_hour"] as? [String: Any]
    let weekly = limits?["seven_day"] as? [String: Any]
    return ClaudeUsage(
        sessionId: (json["session_id"] as? String).map(sanitizedLabel) ?? "default",
        model: ((json["model"] as? [String: Any])?["display_name"] as? String).map(sanitizedLabel),
        contextPercent: usageNumber(context?["used_percentage"]),
        contextSize: usageNumber(context?["context_window_size"]).map { Int($0) },
        fiveHourPercent: usageNumber(fiveHour?["used_percentage"]),
        fiveHourResetsAt: usageDate(fiveHour?["resets_at"]),
        weeklyPercent: usageNumber(weekly?["used_percentage"]),
        weeklyResetsAt: usageDate(weekly?["resets_at"]),
        updatedAt: now)
}

/// Remembers `usage` under its session. Stale sessions are forgotten and, past MAX_USAGE_SESSIONS, the least
/// recently updated ones, so a flood of signals can't grow this without bound. The update just received always stays.
func recordingUsage(_ usage: ClaudeUsage, in sessions: [String: ClaudeUsage], now: Date) -> [String: ClaudeUsage] {
    let others = sessions
        .filter { $0.key != usage.sessionId && now.timeIntervalSince($0.value.updatedAt) < USAGE_STALE_AFTER }
        .sorted { $0.value.updatedAt > $1.value.updatedAt }
        .prefix(MAX_USAGE_SESSIONS - 1)
        .map { ($0.key, $0.value) }
    return Dictionary(uniqueKeysWithValues: others + [(usage.sessionId, usage)])
}

/// The most recently updated session that isn't stale.
func latestUsage(_ sessions: [String: ClaudeUsage], now: Date) -> ClaudeUsage? {
    sessions.values
        .filter { now.timeIntervalSince($0.updatedAt) < USAGE_STALE_AFTER }
        .max { $0.updatedAt < $1.updatedAt }
}

/// Plan limits are per account, not per session, and a session sends them only after its first reply.
/// So the menu takes context from the newest session and limits from the newest data that has them,
/// dropping a limit once its reset time has passed.
func combinedUsage(context latest: ClaudeUsage?, limits: ClaudeUsage?, now: Date) -> ClaudeUsage? {
    guard let latest else { return nil }
    let live = { (percent: Double?, reset: Date?) -> (Double?, Date?) in
        guard let percent, (reset ?? .distantFuture) > now else { return (nil, nil) }
        return (percent, reset)
    }
    let fiveHour = live(limits?.fiveHourPercent, limits?.fiveHourResetsAt)
    let weekly = live(limits?.weeklyPercent, limits?.weeklyResetsAt)
    return ClaudeUsage(sessionId: latest.sessionId, model: latest.model, contextPercent: latest.contextPercent,
                       contextSize: latest.contextSize, fiveHourPercent: fiveHour.0, fiveHourResetsAt: fiveHour.1,
                       weeklyPercent: weekly.0, weeklyResetsAt: weekly.1, updatedAt: latest.updatedAt)
}

extension ClaudeUsage {
    var hasLimits: Bool { fiveHourPercent != nil || weeklyPercent != nil }
}

/// Suggest a walk once per limit window, the moment the 5-hour limit is used up. Not during a pause or snooze:
/// the next status line update asks again.
func shouldSuggestLimitBreak(_ usage: ClaudeUsage, alreadyShownFor shownReset: Date?, isHeld: Bool) -> Bool {
    guard !isHeld, let percent = usage.fiveHourPercent, percent >= LIMIT_REACHED_PERCENT else { return false }
    return shownReset == nil || shownReset != usage.fiveHourResetsAt
}

// MARK: Menu text

func formatContextSize(_ tokens: Int) -> String {
    tokens >= 1_000_000 ? "\(tokens / 1_000_000)M" : "\(tokens / 1000)k"
}

func formatReset(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
    calendar.isDate(date, inSameDayAs: now)
        ? date.formatted(.dateTime.hour().minute())
        : date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
}

func warningMark(_ percent: Double) -> String {
    percent >= USAGE_WARNING_PERCENT ? USAGE_WARNING_SUFFIX : ""
}

/// Lines for the menu bar menu; empty when the status line isn't connected.
func usageLines(_ usage: ClaudeUsage?, isConnected: Bool, now: Date, calendar: Calendar = .current) -> [String] {
    guard isConnected else { return [] }
    guard let usage else { return ["Claude Code: waiting for a session"] }
    let age = now.timeIntervalSince(usage.updatedAt)
    let updated = age > USAGE_FRESH_SECONDS ? ", updated \(Int(age / 60)) min ago" : ""
    let header = "Claude Code" + (usage.model.map { ": \($0)" } ?? "") + updated
    let context = usage.contextPercent.map { percent -> String in
        let size = usage.contextSize.map { " of \(formatContextSize($0))" } ?? ""
        let hint = percent >= CONTEXT_COMPACT_PERCENT ? ", time to /compact" : ""
        return "Context \(Int(percent.rounded()))%\(size)\(warningMark(percent))\(hint)"
    }
    let limit = { (label: String, percent: Double?, reset: Date?) -> String? in
        percent.map { value in
            let resets = reset.map { ", resets \(formatReset($0, now: now, calendar: calendar))" } ?? ""
            return "\(label) \(Int(value.rounded()))%\(resets)\(warningMark(value))"
        }
    }
    return [header, context, limit("5-hour limit", usage.fiveHourPercent, usage.fiveHourResetsAt),
            limit("Weekly limit", usage.weeklyPercent, usage.weeklyResetsAt)].compactMap { $0 }
}

// MARK: The --statusline command

/// Forwards the numbers to the app, then runs your original status line with the same input.
func runStatuslineCommand() -> Int32 {
    signal(SIGPIPE, SIG_IGN)  // an original command that ignores its input must not kill us mid-write
    let input = FileHandle.standardInput.readDataToEndOfFile()
    if let json = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any] {
        postUsage(json)
        writeDiagnosticsIfRequested(json)
    }
    return runOriginalStatusline(input: input)
}

/// Support aid: if the flag file exists, record which fields Claude Code sends (names only, no values).
private func writeDiagnosticsIfRequested(_ json: [String: Any]) {
    let folder = exercisesFolder().deletingLastPathComponent()
    guard FileManager.default.fileExists(atPath: folder.appendingPathComponent(DIAGNOSTICS_FLAG_FILE).path) else { return }
    let limits = json["rate_limits"] as? [String: Any]
    let report: [String: Any] = [
        "fields": json.keys.sorted(),
        "context_window_fields": (json["context_window"] as? [String: Any])?.keys.sorted() ?? [],
        "rate_limits_fields": limits.map { $0.keys.sorted() } ?? ["(not sent)"],
        "five_hour_fields": fieldTypes(limits?["five_hour"]),
        "seven_day_fields": fieldTypes(limits?["seven_day"]),
        "version": json["version"] as? String ?? "unknown",
    ]
    let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    try? data?.write(to: folder.appendingPathComponent(DIAGNOSTICS_FILE), options: .atomic)
}

/// "used_percentage: number" style descriptions, so diagnostics never contain values.
private func fieldTypes(_ value: Any?) -> [String] {
    guard let object = value as? [String: Any] else { return [value == nil ? "(not sent)" : "\(type(of: value!))"] }
    return object.keys.sorted().map { key in
        let kind = switch object[key] {
        case is NSNumber: "number"
        case is String: "string"
        case is NSNull: "null"
        default: "other"
        }
        return "\(key): \(kind)"
    }
}

private func postUsage(_ json: [String: Any]) {
    let wanted = ["session_id", "model", "context_window", "rate_limits"]
    let subset = json.filter { wanted.contains($0.key) }
    guard let data = try? JSONSerialization.data(withJSONObject: subset),
          let text = String(data: data, encoding: .utf8) else { return }
    DistributedNotificationCenter.default().postNotificationName(
        USAGE_NOTIFICATION, object: nil, userInfo: ["json": text], deliverImmediately: true)
}

private func runOriginalStatusline(input: Data) -> Int32 {
    guard let command = (try? loadOriginalStatusline())??["command"] as? String else {
        print("\(Stats.today) breaks today")
        return 0
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = ["-c", command]
    let stdin = Pipe()
    process.standardInput = stdin
    do {
        try process.run()
    } catch {
        FileHandle.standardError.write(Data("statusline: couldn't run your original status line: \(error)\n".utf8))
        return 0
    }
    // The throwing write: a command that exits without reading gives an error here, not a crash.
    try? stdin.fileHandleForWriting.write(contentsOf: input)
    try? stdin.fileHandleForWriting.close()
    process.waitUntilExit()
    return process.terminationStatus
}

// MARK: Saved original status line

func originalStatuslineURL() -> URL {
    exercisesFolder().deletingLastPathComponent().appendingPathComponent(ORIGINAL_STATUSLINE_FILE)
}

/// nil: nothing saved. .some(nil): you had no status line before. .some(object): your original one.
func loadOriginalStatusline(at url: URL = originalStatuslineURL()) throws -> [String: Any]?? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let saved = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    return .some(saved?["statusLine"] as? [String: Any])
}

func saveOriginalStatusline(_ statusLine: [String: Any]?, at url: URL = originalStatuslineURL()) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let wrapper: [String: Any] = statusLine.map { ["statusLine": $0] } ?? [:]
    try JSONSerialization.data(withJSONObject: wrapper, options: [.prettyPrinted]).write(to: url, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: PRIVATE_FILE_PERMISSIONS], ofItemAtPath: url.path)
}
