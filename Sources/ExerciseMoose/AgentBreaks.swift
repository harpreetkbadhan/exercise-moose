import AppKit

/// "Move while your AI codes": a short seated exercise while an AI agent works on a long task.
extension MooseApp {
    var agentMinRun: TimeInterval { isTestMode ? TEST_AGENT_MIN_RUN : AGENT_MIN_RUN }
    var agentCooldown: TimeInterval { isTestMode ? TEST_AGENT_COOLDOWN : AGENT_COOLDOWN }

    func observeAgents() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(agentEventReceived(_:)),
                                                            name: AGENT_NOTIFICATION, object: nil)
    }

    @objc func agentEventReceived(_ notification: Notification) {
        guard let raw = notification.userInfo?["event"] as? String, let event = AgentEvent(rawValue: raw) else { return }
        let session = sanitizedLabel(notification.userInfo?["session"] as? String ?? DEFAULT_AGENT_NAME)
        agentName = sanitizedLabel(notification.userInfo?["name"] as? String ?? DEFAULT_AGENT_NAME)
        let now = Date()
        switch event {
        case .start:
            agentSessions = agentSessions.pruned(at: now)
            guard agentSessions.started[session] == nil else { return }  // repeat start: its timer is already set
            agentSessions = agentSessions.starting(session, at: now)
            Timer.scheduledTimer(timeInterval: agentMinRun, target: self, selector: #selector(checkAgentBreak),
                                 userInfo: nil, repeats: false)
        case .stop:
            agentSessions = agentSessions.stopping(session)
            if agentSessions.isEmpty { agentFinished() }
        }
    }

    /// Runs agentMinRun after a start: show a break if the agent is still busy and the moment suits you.
    @objc func checkAgentBreak() {
        let now = Date()
        agentSessions = agentSessions.pruned(at: now)
        let sinceLast = lastAgentBreak.map { now.timeIntervalSince($0) } ?? .infinity
        guard shouldShowAgentBreak(longestRun: agentSessions.longestRun(at: now), minRun: agentMinRun,
                                   sinceLastAgentBreak: sinceLast, cooldown: agentCooldown,
                                   isPopupVisible: panel != nil, isEnabled: Prefs.agentBreaks,
                                   isHeld: isHolding(hold, at: now)),
              isWorkTime(now, hours: Prefs.workHours), !presence.isAway, !Presence.isOnCall else { return }
        let mediaDir = activeExercisesFolder()
        guard let exercise = pickExercise(from: loadExercises(dir: mediaDir), posture: .seated, after: lastFile,
                                          videos: Set(videoFiles(in: mediaDir))) else { return }
        lastFile = exercise.file
        lastAgentBreak = now
        present(exercise, size: Prefs.popupSize, chipText: "\(agentName) is working")
        isAgentBreak = true
    }

    /// The agent is done: say so and close the agent popup. Your regular break timer keeps running.
    func agentFinished() {
        guard isAgentBreak, let card, !isCelebrating else { return }
        isCelebrating = true
        countdownTimer?.invalidate()
        card.stamp(.agentDone(name: agentName))
        celebrationTimer = Timer.scheduledTimer(timeInterval: CELEBRATION_SECONDS, target: self,
                                                selector: #selector(closeAgentBreak), userInfo: nil, repeats: false)
    }

    @objc func closeAgentBreak() {
        if isAgentBreak { hide() }
    }
}
