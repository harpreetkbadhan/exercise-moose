import Foundation
import Testing
@testable import ExerciseMoose

private let other: [String: Any] = ["type": "command", "command": "~/bin/lint.sh"]
private let original: [String: Any] = [
    "model": "opus",
    "hooks": ["Stop": [["hooks": [other]]], "PreToolUse": [["matcher": "Bash", "hooks": [other]]]],
]
private let command = claudeHookCommand(executable: "/Applications/Exercise Moose.app/Contents/MacOS/ExerciseMoose")
private let installed = addingClaudeHook(to: original, command: command)

private func hooks(_ settings: [String: Any]) -> [String: Any] {
    settings["hooks"] as? [String: Any] ?? [:]
}

@Test("Install adds our hook")
func installAddsHook() {
    #expect(hasClaudeHook(installed) && !hasClaudeHook(original))
}

@Test("Existing hooks on the same event are kept")
func installKeepsExistingHooks() {
    #expect((hooks(installed)["Stop"] as? [[String: Any]])?.count == 2)
}

@Test("Every event we need is registered")
func installRegistersEveryEvent() {
    #expect(CLAUDE_HOOK_EVENTS.allSatisfy { hooks(installed)[$0] != nil })
}

@Test("Installing twice adds no duplicate")
func installingTwiceAddsNoDuplicate() {
    let twice = addingClaudeHook(to: installed, command: command)
    #expect((hooks(twice)["Stop"] as? [[String: Any]])?.count == 2)
}

@Test("Remove leaves other settings alone")
func removeLeavesOtherSettings() {
    let removed = removingClaudeHook(from: installed)
    #expect(!hasClaudeHook(removed) && removed["model"] as? String == "opus")
}

@Test("Remove keeps your other hooks")
func removeKeepsOtherHooks() {
    let removed = hooks(removingClaudeHook(from: installed))
    #expect((removed["Stop"] as? [[String: Any]])?.count == 1 && removed["PreToolUse"] != nil)
}

@Test("Events only we used are cleaned up")
func removeCleansUpOurEvents() {
    #expect(hooks(removingClaudeHook(from: installed))["UserPromptSubmit"] == nil)
}

@Test("Paths are single-quoted for the shell")
func pathsAreShellQuoted() {
    #expect(shellQuoted("/Apps/It's $HOME/x") == "'/Apps/It'\\''s $HOME/x'")
}

@Test("A look-alike user script is never treated as ours")
func lookAlikeScriptIsNotOurs() {
    #expect(!isOurHook("~/bin/notify-ExerciseMoose --agent"))
}

@Test("Hooks installed by older versions are still recognised")
func olderHooksAreRecognised() {
    #expect(isOurHook("\"/Applications/Exercise Moose.app/Contents/MacOS/ExerciseMoose\" --agent"))
}
