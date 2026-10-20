import AppKit

/// Claude Code usage arriving from the status line (shown in the menu header, see MenuHeader.swift),
/// plus a walk break when the 5-hour limit runs out.
extension MooseApp {
    func observeUsage() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(usageReceived(_:)),
                                                            name: USAGE_NOTIFICATION, object: nil)
    }

    @objc func usageReceived(_ notification: Notification) {
        guard let text = notification.userInfo?["json"] as? String,
              let json = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] else { return }
        let now = Date()
        let usage = parseClaudeUsage(json, now: now)
        claudeUsage = recordingUsage(usage, in: claudeUsage, now: now)
        if usage.hasLimits { claudeLimits = usage }
        let lines = usageLines(combinedUsage(context: latestUsage(claudeUsage, now: now), limits: claudeLimits, now: now),
                               isConnected: true, now: now)
        UserDefaults.standard.set(lines, forKey: CLAUDE_LINES_KEY)  // for `moose status`
        if shouldSuggestLimitBreak(usage, alreadyShownFor: limitBreakShownFor, isHeld: isHolding(hold, at: now)) {
            suggestLimitBreak(usage)
        }
    }

    /// Out of Claude usage for now: the best moment for a real walk.
    func suggestLimitBreak(_ usage: ClaudeUsage) {
        // Not now (busy, away, on a call)? Retried on the next status line update while the limit stays used up.
        guard panel == nil, isWorkTime(Date(), hours: Prefs.workHours), !presence.isAway, !Presence.isOnCall,
              let walk = loadExercises(dir: activeExercisesFolder()).first(where: { $0.file == "walk" }) else { return }
        limitBreakShownFor = usage.fiveHourResetsAt
        lastFile = walk.file
        present(walk, size: Prefs.popupSize, chipText: "Claude limit reached")
    }
}
