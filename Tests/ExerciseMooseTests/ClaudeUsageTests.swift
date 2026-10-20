import Foundation
import Testing
@testable import ExerciseMoose

private let now = Date(timeIntervalSince1970: 1_792_400_000)
private let reset = now.addingTimeInterval(2 * 3600)
private let sample: [String: Any] = [
    "session_id": "s1",
    "model": ["id": "claude-opus", "display_name": "Opus"],
    "context_window": ["used_percentage": 62.4, "context_window_size": 200_000],
    "rate_limits": ["five_hour": ["used_percentage": 41, "resets_at": reset.timeIntervalSince1970],
                    "seven_day": ["used_percentage": 85.0, "resets_at": "2026-10-22T09:00:00Z"]],
]
private let usage = parseClaudeUsage(sample, now: now)
private let ourStatusline = statuslineCommand(executable: "/Applications/Exercise Moose.app/Contents/MacOS/ExerciseMoose")
private let orca: [String: Any] = ["type": "command", "command": "/bin/sh ~/.orca/statusline.sh", "padding": 0]
private let settings: [String: Any] = ["model": "opus", "statusLine": orca]
private let installed = installingStatusline(in: settings, command: ourStatusline)

// MARK: Parsing

@Test("Model and context are read")
func modelAndContextAreRead() {
    #expect(usage.model == "Opus" && usage.contextPercent == 62.4 && usage.contextSize == 200_000)
}

@Test("Reset times parse from seconds and ISO text")
func resetTimesParse() {
    #expect(usage.fiveHourResetsAt == reset && usage.weeklyResetsAt != nil)
}

@Test("NaN, infinity and absurd numbers are rejected instead of crashing")
func absurdNumbersAreRejected() {
    #expect(usageNumber(Double.nan) == nil && usageNumber("inf") == nil && usageNumber(1e300) == nil)
}

@Test("Hostile numbers are simply dropped")
func hostileNumbersAreDropped() {
    let hostile = parseClaudeUsage(["context_window": ["used_percentage": "nan", "context_window_size": 1e300]], now: now)
    #expect(usageLines(hostile, isConnected: true, now: now) == ["Claude Code"])
}

// MARK: Menu lines

@Test("The header names the model")
func headerNamesModel() {
    #expect(usageLines(usage, isConnected: true, now: now).first == "Claude Code: Opus")
}

@Test("Context line")
func contextLine() {
    #expect(usageLines(usage, isConnected: true, now: now).contains { $0.hasPrefix("Context 62% of 200k") })
}

@Test("A limit line without a warning")
func limitLineWithoutWarning() {
    let lines = usageLines(usage, isConnected: true, now: now)
    #expect(lines.contains { $0.hasPrefix("5-hour limit 41%") && !$0.contains(USAGE_WARNING_SUFFIX) })
}

@Test("Over 80% gets a warning")
func highUsageGetsWarning() {
    let lines = usageLines(usage, isConnected: true, now: now)
    #expect(lines.contains { $0.hasPrefix("Weekly limit 85%") && $0.hasSuffix(USAGE_WARNING_SUFFIX) })
}

@Test("Hidden when not connected")
func hiddenWhenNotConnected() {
    #expect(usageLines(nil, isConnected: false, now: now).isEmpty)
}

@Test("Connected, no data yet")
func connectedWithoutData() {
    #expect(usageLines(nil, isConnected: true, now: now) == ["Claude Code: waiting for a session"])
}

@Test("Missing numbers are simply left out")
func missingNumbersAreLeftOut() {
    let bare = parseClaudeUsage(["session_id": "s2"], now: now)
    #expect(usageLines(bare, isConnected: true, now: now) == ["Claude Code"])
}

@Test("1M context")
func millionTokenContext() {
    #expect(formatContextSize(1_000_000) == "1M")
}

// MARK: Sessions and limits

@Test("The newest session wins")
func newestSessionWins() {
    let older = parseClaudeUsage(["session_id": "old"], now: now.addingTimeInterval(-60))
    #expect(latestUsage(["s1": usage, "old": older], now: now)?.sessionId == "s1")
}

@Test("Stale data is dropped")
func staleDataIsDropped() {
    let older = parseClaudeUsage(["session_id": "old"], now: now.addingTimeInterval(-60))
    #expect(latestUsage(["old": older], now: now.addingTimeInterval(USAGE_STALE_AFTER)) == nil)
}

@Test("Reaching the limit suggests a walk, once per limit window")
func limitReachedSuggestsWalkOnce() {
    let full = parseClaudeUsage(["rate_limits": ["five_hour": ["used_percentage": 100, "resets_at": 5000]]], now: now)
    #expect(shouldSuggestLimitBreak(full, alreadyShownFor: nil, isHeld: false))
    #expect(!shouldSuggestLimitBreak(full, alreadyShownFor: full.fiveHourResetsAt, isHeld: false))
}

@Test("No walk suggestion during a pause or snooze")
func noWalkWhileHeld() {
    let full = parseClaudeUsage(["rate_limits": ["five_hour": ["used_percentage": 100, "resets_at": 5000]]], now: now)
    #expect(!shouldSuggestLimitBreak(full, alreadyShownFor: nil, isHeld: true))
}

@Test("No walk before the limit")
func noWalkBeforeLimit() {
    #expect(!shouldSuggestLimitBreak(usage, alreadyShownFor: nil, isHeld: false))
}

@Test("A new session without limits still shows the account limits from another session")
func newSessionShowsAccountLimits() {
    let freshSession = parseClaudeUsage(["session_id": "new", "context_window": ["used_percentage": 3]], now: now)
    let combined = combinedUsage(context: freshSession, limits: usage, now: now)
    #expect(combined?.contextPercent == 3 && combined?.fiveHourPercent == 41)
}

@Test("A limit past its reset is dropped")
func limitPastResetIsDropped() {
    let freshSession = parseClaudeUsage(["session_id": "new", "context_window": ["used_percentage": 3]], now: now)
    let afterReset = combinedUsage(context: freshSession, limits: usage, now: reset.addingTimeInterval(1))
    #expect(afterReset?.fiveHourPercent == nil && afterReset?.weeklyPercent == 85)
}

@Test("No session, nothing to show")
func noSessionNothingToShow() {
    #expect(combinedUsage(context: nil, limits: usage, now: now) == nil)
}

// MARK: Remembered sessions (any process can send usage signals)

@Test("Session ids from signals lose control characters and are capped")
func sessionIdsAreSanitized() {
    let flooded = parseClaudeUsage(["session_id": "s\u{0}1\n" + String(repeating: "x", count: 100)], now: now)
    #expect(flooded.sessionId.count == MAX_LABEL_LENGTH && !flooded.sessionId.contains("\n"))
}

@Test("A flood of sessions is capped, keeping the newest")
func usageFloodKeepsNewest() {
    let flood = (0..<200).reduce([String: ClaudeUsage]()) { sessions, index in
        let at = now.addingTimeInterval(TimeInterval(index))
        return recordingUsage(parseClaudeUsage(["session_id": "s\(index)"], now: at), in: sessions, now: at)
    }
    #expect(flood.count == MAX_USAGE_SESSIONS && flood["s199"] != nil && flood["s0"] == nil)
}

@Test("The update just received is always kept, even among equal timestamps")
func latestUpdateIsKept() {
    let flood = (0..<200).reduce([String: ClaudeUsage]()) { sessions, index in
        recordingUsage(parseClaudeUsage(["session_id": "s\(index)"], now: now), in: sessions, now: now)
    }
    #expect(flood["s199"] != nil)
}

@Test("A session's newer update replaces its older one")
func newerUpdateReplacesOlder() {
    let later = now.addingTimeInterval(60)
    let newer = parseClaudeUsage(["session_id": "s1", "context_window": ["used_percentage": 70]], now: later)
    #expect(recordingUsage(newer, in: ["s1": usage], now: later)["s1"]?.contextPercent == 70)
}

@Test("Stale sessions are forgotten")
func staleSessionsAreForgotten() {
    let later = now.addingTimeInterval(USAGE_STALE_AFTER)
    let sessions = recordingUsage(parseClaudeUsage(["session_id": "new"], now: later), in: ["s1": usage], now: later)
    #expect(Array(sessions.keys) == ["new"])
}

// MARK: Status line install

@Test("Install puts our status line in")
func installPutsOurStatuslineIn() {
    #expect(isOurStatusline(installed) && !isOurStatusline(settings))
}

@Test("Your status line options are kept")
func installKeepsStatuslineOptions() {
    #expect((installed["statusLine"] as? [String: Any])?["padding"] as? Int == 0)
}

@Test("Remove restores your original status line")
func removeRestoresOriginal() {
    let restored = removingStatusline(from: installed, original: orca)
    #expect((restored["statusLine"] as? [String: Any])?["command"] as? String == orca["command"] as? String)
}

@Test("No original: the key is removed")
func removeWithoutOriginalDropsKey() {
    #expect(removingStatusline(from: installed, original: nil)["statusLine"] == nil)
}

@Test("Someone else's status line is never removed")
func foreignStatuslineIsKept() {
    #expect((removingStatusline(from: settings, original: nil)["statusLine"] as? [String: Any]) != nil)
}
