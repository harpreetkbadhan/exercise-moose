import Foundation

// Adds or removes our entries in ~/.claude/settings.json, leaving everything else as it was.

let CLAUDE_HOOK_EVENTS = ["UserPromptSubmit", "Stop", "Notification", "SessionEnd"]
let CLAUDE_SETTINGS_BACKUP_SUFFIX = ".exercisemoose-backup"

struct HookError: Error, CustomStringConvertible {
    let description: String
}

func claudeSettingsURL() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")
        .resolvingSymlinksInPath()  // keep dotfile symlinks intact
}

/// Single-quotes a path for /bin/sh, so spaces, $, backticks and quotes in it stay literal.
func shellQuoted(_ path: String) -> String {
    "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

func claudeHookCommand(executable: String) -> String {
    "\(shellQuoted(executable)) --agent"
}

/// Only commands that run this app's own program (…/Contents/MacOS/ExerciseMoose) with our flag count as ours.
func isOurCommand(_ command: String?, flag: String) -> Bool {
    guard let command else { return false }
    return command.hasSuffix(" \(flag)") && command.contains("/Contents/MacOS/ExerciseMoose")
}

func isOurHook(_ command: String?) -> Bool {
    isOurCommand(command, flag: "--agent")
}

func hasClaudeHook(_ settings: [String: Any]) -> Bool {
    let hooks = settings["hooks"] as? [String: Any] ?? [:]
    return hooks.values
        .compactMap { $0 as? [[String: Any]] }
        .joined()
        .compactMap { $0["hooks"] as? [[String: Any]] }
        .joined()
        .contains { isOurHook($0["command"] as? String) }
}

/// Settings without any of our hook entries; groups and events we emptied are dropped.
func removingClaudeHook(from settings: [String: Any]) -> [String: Any] {
    guard let hooks = settings["hooks"] as? [String: Any] else { return settings }
    let cleaned = hooks.compactMapValues { value -> Any? in
        guard let groups = value as? [[String: Any]] else { return value }
        let kept = groups.compactMap { group -> [String: Any]? in
            guard let entries = group["hooks"] as? [[String: Any]] else { return group }
            let others = entries.filter { !isOurHook($0["command"] as? String) }
            if others.count == entries.count { return group }
            return others.isEmpty ? nil : group.merging(["hooks": others]) { _, new in new }
        }
        return kept.isEmpty && !groups.isEmpty ? nil : kept
    }
    return settings.merging(["hooks": cleaned]) { _, new in new }
}

/// Settings with our command added once to each event we listen to.
func addingClaudeHook(to settings: [String: Any], command: String) -> [String: Any] {
    let base = removingClaudeHook(from: settings)
    let entry: [String: Any] = ["hooks": [["type": "command", "command": command]]]
    let hooks = CLAUDE_HOOK_EVENTS.reduce(base["hooks"] as? [String: Any] ?? [:]) { current, event in
        let groups = current[event] as? [[String: Any]] ?? []
        return current.merging([event: groups + [entry]]) { _, new in new }
    }
    return base.merging(["hooks": hooks]) { _, new in new }
}

// MARK: Status line (one command only, so ours wraps yours)

func statuslineCommand(executable: String) -> String {
    "\(shellQuoted(executable)) --statusline"
}

func isOurStatusline(_ settings: [String: Any]) -> Bool {
    isOurCommand((settings["statusLine"] as? [String: Any])?["command"] as? String, flag: "--statusline")
}

/// Settings with our status line in place; any other keys of your status line (like padding) are kept.
func installingStatusline(in settings: [String: Any], command: String) -> [String: Any] {
    let current = settings["statusLine"] as? [String: Any] ?? [:]
    let ours = current.merging(["type": "command", "command": command]) { _, new in new }
    return settings.merging(["statusLine": ours]) { _, new in new }
}

/// Puts your original status line back (or removes the key if you had none). Leaves foreign status lines alone.
func removingStatusline(from settings: [String: Any], original: [String: Any]?) -> [String: Any] {
    guard isOurStatusline(settings) else { return settings }
    guard let original else { return settings.filter { $0.key != "statusLine" } }
    return settings.merging(["statusLine": original]) { _, new in new }
}

func installStatusline(executable: String, settingsURL: URL = claudeSettingsURL(),
                       originalURL: URL = originalStatuslineURL()) throws {
    let current = try readClaudeSettings(at: settingsURL)
    if !isOurStatusline(current) {
        try saveOriginalStatusline(current["statusLine"] as? [String: Any], at: originalURL)
    }
    try updateClaudeSettings(at: settingsURL) {
        installingStatusline(in: $0, command: statuslineCommand(executable: executable))
    }
}

func removeStatusline(settingsURL: URL = claudeSettingsURL(), originalURL: URL = originalStatuslineURL()) throws {
    let original = (try loadOriginalStatusline(at: originalURL)) ?? nil
    try updateClaudeSettings(at: settingsURL) { removingStatusline(from: $0, original: original) }
    try? FileManager.default.removeItem(at: originalURL)
}

func readClaudeSettings(at url: URL = claudeSettingsURL()) throws -> [String: Any] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
    return try parseClaudeSettings(Data(contentsOf: url))
}

private func parseClaudeSettings(_ data: Data) throws -> [String: Any] {
    guard let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw HookError(description: "~/.claude/settings.json isn't a JSON object, so it was left untouched")
    }
    return settings
}

/// Writes the transformed settings atomically. Keeps the very first backup (your untouched original),
/// keeps the file's permissions, and refuses to write if another tool changed the file in the meantime.
func updateClaudeSettings(at url: URL = claudeSettingsURL(), _ transform: ([String: Any]) -> [String: Any]) throws {
    let fileManager = FileManager.default
    let exists = fileManager.fileExists(atPath: url.path)
    let before = exists ? try Data(contentsOf: url) : nil
    let current = try before.map(parseClaudeSettings) ?? [:]
    let permissions = exists ? (try? fileManager.attributesOfItem(atPath: url.path))?[.posixPermissions] : nil
    if exists {
        let backup = URL(fileURLWithPath: url.path + CLAUDE_SETTINGS_BACKUP_SUFFIX)
        if !fileManager.fileExists(atPath: backup.path) { try fileManager.copyItem(at: url, to: backup) }
    } else {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
    let data = try JSONSerialization.data(withJSONObject: transform(current),
                                          options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    let latest = exists ? try? Data(contentsOf: url) : nil
    guard latest == before else {
        throw HookError(description: "~/.claude/settings.json changed while updating it, so nothing was written. Try again.")
    }
    try data.write(to: url, options: .atomic)
    if let permissions { try? fileManager.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path) }
}
