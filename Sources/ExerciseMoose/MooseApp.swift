import AppKit
import AVFoundation
import SwiftUI

let TEST_INTERVAL: TimeInterval = 10
let SCREEN_MARGIN: CGFloat = 8
let MENU_BAR_GAP: CGFloat = 5
let DROP_DISTANCE: CGFloat = 8
let HAS_LAUNCHED_KEY = "hasLaunchedBefore"
let CELEBRATION_SECONDS: TimeInterval = 1.4
let FALLBACK_ICON_SIZE: CGFloat = 80
let LAST_STANDING_KEY = "lastStandingBreak"
let TEST_STAND_SECONDS: TimeInterval = 25

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class MooseApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let isTestMode: Bool
    let exercisesDir = exercisesFolder()
    let headerItem = NSMenuItem()
    let header = MenuHeaderView()
    lazy var presence = PresenceMonitor(
        threshold: isTestMode ? TEST_AWAY_THRESHOLD : AWAY_THRESHOLD,
        checkInterval: isTestMode ? TEST_PRESENCE_CHECK_SECONDS : PRESENCE_CHECK_SECONDS,
        onReturn: { [weak self] awayFor in self?.cameBack(after: awayFor) })
    var waitingSince: Date?
    var offUntil: Date?
    var hold: Hold?
    var isCelebrating = false
    var agentSessions = AgentSessions.none
    var agentName = DEFAULT_AGENT_NAME
    var lastAgentBreak: Date?
    var isAgentBreak = false
    var claudeUsage: [String: ClaudeUsage] = [:]
    var claudeLimits: ClaudeUsage?
    var celebrationTimer: Timer?
    var limitBreakShownFor: Date?
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    var breakTimer: Timer?
    var countdownTimer: Timer?
    var panel: NSPanel?
    var looper: AVPlayerLooper?
    var card: PopupCard?
    var secondsLeft = 0
    var lastFile: String?
    let launchDate = Date()

    var workInterval: TimeInterval { isTestMode ? TEST_INTERVAL : TimeInterval(Prefs.workMinutes * 60) }
    var standInterval: TimeInterval { isTestMode ? TEST_STAND_SECONDS : TimeInterval(Prefs.standMinutes * 60) }

    /// When you last got a standing break; the first one of a session comes one interval after launch.
    var lastStandingBreak: Date {
        get { UserDefaults.standard.object(forKey: LAST_STANDING_KEY) as? Date ?? launchDate }
        set { UserDefaults.standard.set(newValue, forKey: LAST_STANDING_KEY) }
    }

    init(isTestMode: Bool) {
        self.isTestMode = isTestMode
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        createExercisesFolder()
        setupMenu()
        presence.start()
        observeAgents()
        observeUsage()
        observeCommands()
        endHold()  // a pause from before a restart doesn't carry over
        schedule(after: workInterval)
        if !UserDefaults.standard.bool(forKey: HAS_LAUNCHED_KEY) {
            UserDefaults.standard.set(true, forKey: HAS_LAUNCHED_KEY)
            openSettings()
        }
    }

    /// Opening the app again (Finder, Spotlight, Dock) while it runs shows Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return false
    }

    func createExercisesFolder() {
        do {
            try FileManager.default.createDirectory(at: exercisesDir, withIntermediateDirectories: true)
        } catch {
            NSLog("Exercise Moose: could not create %@: %@", exercisesDir.path, error.localizedDescription)
        }
    }

    // MARK: Menu bar

    func setupMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let icon = bundledMenuBarIcon() ?? menuBarFace() {
            item.button?.image = icon
        } else {
            item.button?.image = NSImage(systemSymbolName: "figure.cooldown", accessibilityDescription: "Exercise Moose")
        }
        headerItem.view = header
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(headerItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Show now", action: #selector(showBreak), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Pause 1 hour", action: #selector(pauseTapped), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Quit Exercise Moose", action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    /// Rebuilds the header each time the menu opens: next break, streak, and Claude Code usage when connected.
    func menuWillOpen(_ menu: NSMenu) {
        let now = Date()
        let next = breakStatus(nextBreak: breakTimer?.isValid == true ? breakTimer?.fireDate : nil,
                               pausedUntil: hold?.pausedUntil, offUntil: offUntil, isWaitingForCall: waitingSince != nil,
                               isShowing: panel != nil, now: now)
        let isConnected = (try? readClaudeSettings()).map(isOurStatusline) ?? false
        let usage = combinedUsage(context: latestUsage(claudeUsage, now: now), limits: claudeLimits, now: now)
        header.update(next: next, streak: streakStatus(counts: Stats.counts, goal: Prefs.dailyGoal, now: now),
                      claudeTitle: usageLines(usage, isConnected: isConnected, now: now).first,
                      rows: usage.map { usageRows($0, now: now) } ?? [])
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView(
                onShowNow: { [weak self] in self?.showBreak() },
                onIntervalChange: { [weak self] in self?.settingsChanged() },
                onOpenFolder: { [weak self] in
                    guard let self else { return }
                    NSWorkspace.shared.open(self.exercisesDir)
                })
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Exercise Moose Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.center()
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: Timer

    func schedule(after seconds: TimeInterval) {
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(timeInterval: seconds, target: self,
                                          selector: #selector(breakDue), userInfo: nil, repeats: false)
        UserDefaults.standard.set(Date().addingTimeInterval(seconds), forKey: NEXT_BREAK_KEY)  // for `moose status`
    }

    /// A new interval or work hours start right away, but never end a running pause or snooze:
    /// its timer runs to the end and the next break reads the new settings.
    func settingsChanged() {
        guard !isHolding(hold, at: Date()) else { return }
        restartTimer()
    }

    func restartTimer() {
        endHold()
        offUntil = nil
        UserDefaults.standard.removeObject(forKey: OFF_UNTIL_KEY)
        if panel == nil { schedule(after: workInterval) }
    }

    /// Timer fired: show the break now, or hold it outside work hours, while you're away or on a call.
    @objc func breakDue() {
        endHold()  // the timer runs to the end of a pause or snooze, so it's over now
        if panel != nil {  // an agent break is on screen; try again shortly instead of replacing it
            schedule(after: CALL_RECHECK_SECONDS)
            return
        }
        let now = Date()
        let hours = Prefs.workHours
        if !isWorkTime(now, hours: hours), let start = nextWorkStart(after: now, hours: hours) {
            // First break comes one interval into the work day, not the moment it starts.
            offUntil = start
            UserDefaults.standard.set(start, forKey: OFF_UNTIL_KEY)
            schedule(after: start.timeIntervalSince(now) + workInterval)
            return
        }
        offUntil = nil
        UserDefaults.standard.removeObject(forKey: OFF_UNTIL_KEY)
        let waited = waitingSince.map { Date().timeIntervalSince($0) } ?? 0
        let isOnCall = Prefs.waitForCalls && Presence.isOnCall
        switch breakDecision(isAway: presence.isAway, isOnCall: isOnCall,
                             waitForCalls: Prefs.waitForCalls, waitedSoFar: waited) {
        case .show:
            showBreak()
        case .wait:
            // Only a call shows "waiting" in the menu; while you're away nobody is looking.
            if isOnCall, waitingSince == nil { waitingSince = Date() }
            schedule(after: CALL_RECHECK_SECONDS)
        }
    }

    /// Back after a long enough absence: that was your break, start a fresh interval.
    func cameBack(after awayFor: TimeInterval) {
        let threshold = isTestMode ? TEST_AWAY_THRESHOLD : AWAY_THRESHOLD
        guard shouldResetAfterAway(awayFor: awayFor, resetWhenAway: Prefs.resetWhenAway, threshold: threshold,
                                   isHeld: isHolding(hold, at: Date())) else {
            return
        }
        hide()
        schedule(after: workInterval)
    }

    @objc func showBreak() {
        breakTimer?.invalidate()
        endHold()  // asking for a break ends a pause
        waitingSince = nil
        hide()
        let now = Date()
        let posture = postureForNextBreak(now: now, lastStanding: lastStandingBreak, standInterval: standInterval)
        let mediaDir = activeExercisesFolder()
        let videos = Set(videoFiles(in: mediaDir))
        guard let exercise = pickExercise(from: loadExercises(dir: mediaDir), posture: posture,
                                          after: lastFile, videos: videos) else {
            NSLog("Exercise Moose: no %@ exercises to show", posture.rawValue)
            schedule(after: workInterval)  // keep the reminders going
            return
        }
        lastFile = exercise.file
        if posture == .standing { lastStandingBreak = now }
        present(exercise, size: Prefs.popupSize)
    }

    /// Counts the break, stamps today's count on the card, then closes the popup.
    @objc func doneTapped() {
        guard let card, !isCelebrating else { return }
        isCelebrating = true
        countdownTimer?.invalidate()
        Stats.recordBreak()
        card.stamp(.counted(today: Stats.today, goal: Prefs.dailyGoal))
        celebrationTimer = Timer.scheduledTimer(timeInterval: CELEBRATION_SECONDS, target: self,
                                                selector: #selector(finishBreak), userInfo: nil, repeats: false)
    }

    @objc func finishBreak() { hide(); schedule(after: workInterval) }
    @objc func pauseTapped() { pause(minutes: DEFAULT_PAUSE_MINUTES) }

    /// Holds every popup until the snooze ends, and stamps when it comes back before the card leaves.
    @objc func snoozeTapped() {
        guard let card, !isCelebrating else { return }
        isCelebrating = true
        countdownTimer?.invalidate()
        let seconds = TimeInterval(Prefs.snoozeMinutes * 60)
        let until = Date().addingTimeInterval(seconds)
        hold = .snoozed(until: until)
        schedule(after: seconds)
        card.stamp(.snoozed(until: until))
        celebrationTimer = Timer.scheduledTimer(timeInterval: CELEBRATION_SECONDS, target: self,
                                                selector: #selector(closeStamped), userInfo: nil, repeats: false)
    }

    @objc func closeStamped() { hide() }

    /// No popups of any kind (regular, agent or limit breaks) until the pause ends. Callers clamp `minutes`.
    func pause(minutes: Int) {
        hide()
        let until = Date().addingTimeInterval(TimeInterval(minutes * 60))
        hold = .paused(until: until)
        UserDefaults.standard.set(until, forKey: PAUSED_UNTIL_KEY)  // for `moose status`
        schedule(after: until.timeIntervalSinceNow)
    }

    func endHold() {
        hold = nil
        UserDefaults.standard.removeObject(forKey: PAUSED_UNTIL_KEY)
    }

    // MARK: Popup

    func hide() {
        countdownTimer?.invalidate()
        celebrationTimer?.invalidate()  // a pending "close after celebrating" must not close the next popup
        waitingSince = nil
        isCelebrating = false
        isAgentBreak = false
        looper = nil
        card = nil
        panel?.orderOut(nil)
        panel = nil
    }

    func present(_ exercise: Exercise, size: PopupSize, chipText: String? = nil) {
        let card = PopupCard(exercise: exercise, media: mediaView(for: exercise, size: size), size: size,
                             chipText: chipText, snoozeMinutes: Prefs.snoozeMinutes, target: self,
                             doneAction: #selector(doneTapped), snoozeAction: #selector(snoozeTapped))
        self.card = card
        let newPanel = Panel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.contentView = card
        newPanel.setContentSize(card.fittingSize)
        panel = newPanel
        dropDown(newPanel)
        startCountdown()
        announce(popupAnnouncement(for: exercise, chipText: chipText))
    }

    func mediaView(for exercise: Exercise, size: PopupSize) -> NSView {
        let url = activeExercisesFolder().appendingPathComponent(exercise.file + ".mov")
        let media = size.mediaSize
        guard FileManager.default.fileExists(atPath: url.path) else {
            return characterView(posture: exercise.posture, size: media)
                ?? fallbackIconView(size: media, color: exercise.kind.fieldInk)
        }
        let player = AVQueuePlayer()
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = .clear
        // BGRA keeps the video's alpha channel so the character stands directly on the colour field.
        playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        let view = NSView()
        view.layer = playerLayer
        view.wantsLayer = true
        sized(view, size: size.mediaSize)
        player.play()
        return view
    }

    /// Your character picture (sitting for seated exercises when you have one), or nil if convert.sh hasn't
    /// made one yet. It stands still: the field and the countdown carry the moment.
    func characterView(posture: Posture, size: NSSize) -> NSView? {
        let seated = posture == .seated ? NSImage(contentsOf: seatedCharacterImageURL()) : nil
        guard let image = seated ?? NSImage(contentsOf: characterImageURL()) else { return nil }
        let imageView = NSImageView(image: trimmingTransparentEdges(image))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignBottom
        sized(imageView, size: size)
        return imageView
    }

    func fallbackIconView(size: NSSize, color: NSColor) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "figure.cooldown", accessibilityDescription: "Exercise")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: FALLBACK_ICON_SIZE, weight: .regular)
                .applying(NSImage.SymbolConfiguration(paletteColors: [color])))
        icon.imageAlignment = .alignBottom
        sized(icon, size: size)
        return icon
    }

    func sized(_ view: NSView, size: NSSize) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: size.height).isActive = true
    }

    /// Fades the panel in right under the menu bar icon, like a menu-bar dropdown.
    func dropDown(_ target: NSPanel) {
        let iconWindow = statusItem?.button?.window
        guard let screen = (iconWindow?.screen ?? NSScreen.main)?.visibleFrame else {
            target.center()
            target.orderFrontRegardless()
            return
        }
        let size = target.frame.size
        let iconX = iconWindow?.frame.midX ?? screen.maxX
        let x = min(max(iconX - size.width / 2, screen.minX + SCREEN_MARGIN), screen.maxX - size.width - SCREEN_MARGIN)
        let endFrame = NSRect(x: x, y: screen.maxY - size.height - MENU_BAR_GAP, width: size.width, height: size.height)
        target.setFrame(endFrame.offsetBy(dx: 0, dy: DROP_DISTANCE), display: false)
        target.alphaValue = 0
        target.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            target.animator().setFrame(endFrame, display: true)
            target.animator().alphaValue = 1
        }, completionHandler: {
            target.setFrame(endFrame, display: true)
            target.alphaValue = 1
        })
    }

    func startCountdown() {
        secondsLeft = Prefs.exerciseSeconds
        card?.setRemaining(secondsLeft, total: Prefs.exerciseSeconds)
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick),
                                              userInfo: nil, repeats: true)
    }

    @objc func tick() {
        secondsLeft -= 1
        card?.setRemaining(secondsLeft, total: Prefs.exerciseSeconds)
        if secondsLeft <= 0 { countdownTimer?.invalidate() }
    }
}
