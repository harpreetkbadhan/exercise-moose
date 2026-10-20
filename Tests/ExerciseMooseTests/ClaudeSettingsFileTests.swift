import Foundation
import Testing
@testable import ExerciseMoose

// Reading and writing ~/.claude/settings.json, against files in a fresh temporary folder (never your real one).

private let executable = "/Applications/Exercise Moose.app/Contents/MacOS/ExerciseMoose"

/// <temporary folder>/.claude/settings.json with `json` in it, or not created yet when `json` is nil.
private func temporarySettings(_ json: String?) throws -> URL {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("moose-tests-\(UUID().uuidString)")
    let url = folder.appendingPathComponent(".claude/settings.json")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    if let json {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: url)
    }
    return url
}

private func savedOriginalURL(next settings: URL) -> URL {
    settings.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("original-statusline.json")
}

// MARK: settings.json

@Test("Updating keeps your other settings")
func updateKeepsOtherSettings() throws {
    let url = try temporarySettings(#"{"model": "opus"}"#)
    try updateClaudeSettings(at: url) { $0.merging(["statusLine": ["type": "command"]]) { _, new in new } }
    let saved = try readClaudeSettings(at: url)
    #expect(saved["model"] as? String == "opus" && saved["statusLine"] != nil)
}

@Test("The first update backs up your untouched original and later ones keep it")
func firstUpdateBacksUpOriginal() throws {
    let url = try temporarySettings(#"{"model": "opus"}"#)
    try updateClaudeSettings(at: url) { $0.merging(["a": 1]) { _, new in new } }
    try updateClaudeSettings(at: url) { $0.merging(["b": 2]) { _, new in new } }
    let backup = URL(fileURLWithPath: url.path + CLAUDE_SETTINGS_BACKUP_SUFFIX)
    #expect(try String(contentsOf: backup, encoding: .utf8) == #"{"model": "opus"}"#)
}

@Test("The file's permissions are kept")
func updateKeepsPermissions() throws {
    let url = try temporarySettings("{}")
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    try updateClaudeSettings(at: url) { $0 }
    #expect(try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int == 0o600)
}

@Test("Nothing is written if another tool changes the file meanwhile")
func concurrentChangeWritesNothing() throws {
    let url = try temporarySettings(#"{"model": "opus"}"#)
    let theirs = Data(#"{"model": "sonnet"}"#.utf8)
    #expect(throws: HookError.self) {
        try updateClaudeSettings(at: url) { settings in
            try? theirs.write(to: url)  // another tool saves while we are working
            return settings.merging(["ours": true]) { _, new in new }
        }
    }
    #expect(try Data(contentsOf: url) == theirs)
}

@Test("A settings file that isn't a JSON object is left untouched")
func nonObjectSettingsAreLeftAlone() throws {
    let url = try temporarySettings("[1, 2]")
    #expect(throws: HookError.self) { try updateClaudeSettings(at: url) { $0 } }
    #expect(try String(contentsOf: url, encoding: .utf8) == "[1, 2]")
}

@Test("A missing settings file reads as empty and is created on update")
func missingSettingsFileIsCreated() throws {
    let url = try temporarySettings(nil)
    #expect(try readClaudeSettings(at: url).isEmpty)
    try updateClaudeSettings(at: url) { $0.merging(["model": "opus"]) { _, new in new } }
    #expect(try readClaudeSettings(at: url)["model"] as? String == "opus")
}

// MARK: Status line install and remove

@Test("Installing and removing the status line puts your original back")
func statuslineRoundTrip() throws {
    let url = try temporarySettings(#"{"statusLine": {"type": "command", "command": "~/status.sh", "padding": 2}}"#)
    let original = savedOriginalURL(next: url)
    try installStatusline(executable: executable, settingsURL: url, originalURL: original)
    #expect(isOurStatusline(try readClaudeSettings(at: url)))
    try removeStatusline(settingsURL: url, originalURL: original)
    let restored = try readClaudeSettings(at: url)["statusLine"] as? [String: Any]
    #expect(restored?["command"] as? String == "~/status.sh" && restored?["padding"] as? Int == 2)
    #expect(!FileManager.default.fileExists(atPath: original.path))
}

@Test("No status line before means none after removing ours")
func noOriginalStatuslineMeansNoneAfter() throws {
    let url = try temporarySettings("{}")
    let original = savedOriginalURL(next: url)
    try installStatusline(executable: executable, settingsURL: url, originalURL: original)
    try removeStatusline(settingsURL: url, originalURL: original)
    #expect(try readClaudeSettings(at: url)["statusLine"] == nil)
}

@Test("Installing twice keeps your real original, not ours")
func reinstallKeepsRealOriginal() throws {
    let url = try temporarySettings(#"{"statusLine": {"type": "command", "command": "~/status.sh"}}"#)
    let original = savedOriginalURL(next: url)
    try installStatusline(executable: executable, settingsURL: url, originalURL: original)
    try installStatusline(executable: executable, settingsURL: url, originalURL: original)
    #expect((try loadOriginalStatusline(at: original))??["command"] as? String == "~/status.sh")
}

@Test("The saved original status line is private to you")
func savedOriginalIsPrivate() throws {
    let original = savedOriginalURL(next: try temporarySettings(nil))
    try saveOriginalStatusline(["command": "~/status.sh"], at: original)
    #expect(try FileManager.default.attributesOfItem(atPath: original.path)[.posixPermissions] as? Int
        == PRIVATE_FILE_PERMISSIONS)
}
