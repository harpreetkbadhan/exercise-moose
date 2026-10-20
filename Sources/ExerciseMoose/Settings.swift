import AppKit
import Charts
import ServiceManagement
import SwiftUI

enum PrefKey {
    static let workMinutes = "workMinutes"
    static let exerciseSeconds = "exerciseSeconds"
    static let snoozeMinutes = "snoozeMinutes"
    static let popupSize = "popupSize"
    static let dailyGoal = "dailyGoal"
    static let waitForCalls = "waitForCalls"
    static let resetWhenAway = "resetWhenAway"
    static let standMinutes = "standMinutes"
    static let workHoursEnabled = "workHoursEnabled"
    static let workStartHour = "workStartHour"
    static let workEndHour = "workEndHour"
    static let weekdaysOnly = "weekdaysOnly"
    static let agentBreaks = "agentBreaks"
}

let DEFAULT_PREFS: [String: Any] = [
    PrefKey.workMinutes: 30,
    PrefKey.exerciseSeconds: 30,
    PrefKey.snoozeMinutes: 5,
    PrefKey.popupSize: PopupSize.medium.rawValue,
    PrefKey.dailyGoal: 6,
    PrefKey.waitForCalls: true,
    PrefKey.resetWhenAway: true,
    PrefKey.standMinutes: 90,
    PrefKey.workHoursEnabled: true,
    PrefKey.workStartHour: 9,
    PrefKey.workEndHour: 18,
    PrefKey.weekdaysOnly: true,
    PrefKey.agentBreaks: true,
]

enum PopupSize: String, CaseIterable {
    case small, medium, large

    var width: CGFloat {
        switch self {
        case .small: 340
        case .medium: 380
        case .large: 440
        }
    }

    /// The colour field your figure stands in.
    var fieldHeight: CGFloat {
        switch self {
        case .small: 260
        case .medium: 300
        case .large: 360
        }
    }
}

/// Current saved settings (defaults registered in main.swift).
enum Prefs {
    // At least 1: a 0 written by hand with `defaults write` would otherwise loop popups instantly.
    static var workMinutes: Int { max(1, UserDefaults.standard.integer(forKey: PrefKey.workMinutes)) }
    static var exerciseSeconds: Int { max(1, UserDefaults.standard.integer(forKey: PrefKey.exerciseSeconds)) }
    static var snoozeMinutes: Int { max(1, UserDefaults.standard.integer(forKey: PrefKey.snoozeMinutes)) }
    static var dailyGoal: Int { max(1, UserDefaults.standard.integer(forKey: PrefKey.dailyGoal)) }
    static var waitForCalls: Bool { UserDefaults.standard.bool(forKey: PrefKey.waitForCalls) }
    static var resetWhenAway: Bool { UserDefaults.standard.bool(forKey: PrefKey.resetWhenAway) }
    static var standMinutes: Int { max(1, UserDefaults.standard.integer(forKey: PrefKey.standMinutes)) }
    static var agentBreaks: Bool { UserDefaults.standard.bool(forKey: PrefKey.agentBreaks) }
    static var workHours: WorkHours {
        let defaults = UserDefaults.standard
        return WorkHours(isEnabled: defaults.bool(forKey: PrefKey.workHoursEnabled),
                         startHour: defaults.integer(forKey: PrefKey.workStartHour),
                         endHour: defaults.integer(forKey: PrefKey.workEndHour),
                         weekdaysOnly: defaults.bool(forKey: PrefKey.weekdaysOnly))
    }
    static var popupSize: PopupSize {
        PopupSize(rawValue: UserDefaults.standard.string(forKey: PrefKey.popupSize) ?? "") ?? .medium
    }
}

struct SettingsView: View {
    @AppStorage(PrefKey.workMinutes) private var workMinutes = 30
    @AppStorage(PrefKey.exerciseSeconds) private var exerciseSeconds = 30
    @AppStorage(PrefKey.snoozeMinutes) private var snoozeMinutes = 5
    @AppStorage(PrefKey.popupSize) private var popupSize = PopupSize.medium.rawValue
    @AppStorage(PrefKey.dailyGoal) private var dailyGoal = 6
    @AppStorage(PrefKey.waitForCalls) private var waitForCalls = true
    @AppStorage(PrefKey.resetWhenAway) private var resetWhenAway = true
    @AppStorage(PrefKey.standMinutes) private var standMinutes = 90
    @AppStorage(PrefKey.workHoursEnabled) private var workHoursEnabled = true
    @AppStorage(PrefKey.workStartHour) private var workStartHour = 9
    @AppStorage(PrefKey.workEndHour) private var workEndHour = 18
    @AppStorage(PrefKey.weekdaysOnly) private var weekdaysOnly = true
    @AppStorage(PrefKey.agentBreaks) private var agentBreaks = true
    @State private var isHookInstalled = false
    @State private var isStatuslineInstalled = false
    @State private var hookMessage: String?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @State private var videoCount = 0
    @State private var week: [DayCount] = []
    @State private var streakDays = 0

    let onShowNow: () -> Void
    let onIntervalChange: () -> Void
    let onOpenFolder: () -> Void

    var body: some View {
        Form {
            progressSection
            Section("Reminders") {
                Picker("Remind me every", selection: $workMinutes) {
                    ForEach([15, 20, 30, 45, 60, 90], id: \.self) { Text("\($0) min").tag($0) }
                }
                .onChange(of: workMinutes) { _, _ in onIntervalChange() }
                Picker(selection: $standMinutes) {
                    ForEach([60, 90, 120], id: \.self) { Text($0 == 60 ? "1 hour" : $0 == 90 ? "1.5 hours" : "2 hours").tag($0) }
                } label: {
                    Text("Stand-up break every")
                    Text("Other breaks are exercises you do sitting in your chair.")
                }
                Picker("Exercise timer", selection: $exerciseSeconds) {
                    ForEach([15, 30, 45, 60], id: \.self) { Text("\($0) sec").tag($0) }
                }
                Picker("Snooze for", selection: $snoozeMinutes) {
                    ForEach([5, 10, 15], id: \.self) { Text("\($0) min").tag($0) }
                }
                Picker("Daily goal", selection: $dailyGoal) {
                    ForEach([4, 6, 8, 10, 12], id: \.self) { Text("\($0) breaks").tag($0) }
                }
            }
            Section("Work hours") {
                Toggle(isOn: $workHoursEnabled) {
                    Text("Only remind me during work hours")
                    Text("No popups in the evening or, if you like, at the weekend.")
                }
                if workHoursEnabled {
                    Picker("From", selection: $workStartHour) {
                        ForEach(5...12, id: \.self) { Text("\($0):00").tag($0) }
                    }
                    Picker("Until", selection: $workEndHour) {
                        ForEach(13...23, id: \.self) { Text("\($0):00").tag($0) }
                    }
                    Toggle("Weekdays only", isOn: $weekdaysOnly)
                }
            }
            .onChange(of: workHoursEnabled) { _, _ in onIntervalChange() }
            .onChange(of: workStartHour) { _, _ in onIntervalChange() }
            .onChange(of: workEndHour) { _, _ in onIntervalChange() }
            .onChange(of: weekdaysOnly) { _, _ in onIntervalChange() }
            Section("AI agents") {
                Toggle(isOn: $agentBreaks) {
                    Text("Exercise while AI agents work")
                    Text("When Claude Code works on a task for over a minute, do a quick seated exercise until it's done.")
                }
                LabeledContent {
                    Button(isHookInstalled ? "Remove hook" : "Install hook", action: toggleClaudeHook)
                } label: {
                    Text("Claude Code")
                    Text(isHookInstalled ? "Connected" : "Adds a small hook to ~/.claude/settings.json (backed up first).")
                }
                LabeledContent {
                    Button(isStatuslineInstalled ? "Remove" : "Install", action: toggleStatusline)
                } label: {
                    Text("Usage in the menu")
                    Text(isStatuslineInstalled
                         ? "Connected. Context and plan limits show in the menu."
                         : "Shows context and plan limits in the menu. Your current status line keeps working.")
                }
                if let hookMessage {
                    Text(hookMessage).font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Smart pause") {
                Toggle(isOn: $waitForCalls) {
                    Text("Wait until calls end")
                    Text("Holds the popup while your camera or microphone is in use, for up to 30 minutes.")
                }
                Toggle(isOn: $resetWhenAway) {
                    Text("Restart the timer when I'm away")
                    Text("A locked screen, sleep or 5 minutes without using your Mac counts as a break.")
                }
            }
            Section("Popup") {
                Picker("Size", selection: $popupSize) {
                    ForEach(PopupSize.allCases, id: \.rawValue) { Text($0.rawValue.capitalized).tag($0.rawValue) }
                }
                Button("Show a test popup now", action: onShowNow)
            }
            Section("Exercises") {
                LabeledContent("Exercise videos", value: "\(videoCount) found")
                Button("Open Exercises Folder", action: onOpenFolder)
            }
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, isOn in setLaunchAtLogin(isOn) }
                if let loginError {
                    Text(loginError).foregroundStyle(.red).font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .tint(Color(nsColor: ExerciseKind.stretch.field))  // the stretch field's ultramarine, like the chart and popup
        .frame(width: 440, height: 720)  // grouped Forms scroll, so they need an explicit size
        .onAppear(perform: refresh)
        // Back to this window (e.g. after running convert.sh): read the files again.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in refresh() }
        // Defaults change often (every Claude Code status line update), so only the cheap progress numbers follow them.
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshProgress()
        }
    }

    private var progressSection: some View {
        Section("This week") {
            LabeledContent("Streak") {
                if streakDays > 0 {
                    Label("\(streakDays) \(streakDays == 1 ? "day" : "days")", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                } else {
                    Text("Do a break to start one")
                }
            }
            Chart {
                ForEach(week) { day in
                    BarMark(x: .value("Day", day.day, unit: .day), y: .value("Breaks", day.count))
                        .foregroundStyle(Color(nsColor: ExerciseKind.stretch.field).opacity(day.count >= dailyGoal ? 1 : 0.4))
                }
                RuleMark(y: .value("Goal", dailyGoal))
                    .foregroundStyle(Color.secondary)  // a neutral reference line; .secondary alone tints it accent blue
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal \(dailyGoal)").font(.caption2).foregroundStyle(.secondary)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated)) }
            }
            .frame(height: 120)
        }
    }

    private func refresh() {
        videoCount = videoFiles(in: activeExercisesFolder()).count
        let claudeSettings = try? readClaudeSettings()
        isHookInstalled = claudeSettings.map(hasClaudeHook) ?? false
        isStatuslineInstalled = claudeSettings.map(isOurStatusline) ?? false
        refreshProgress()
    }

    /// Sets only what changed, so unrelated defaults writes don't redraw the window.
    private func refreshProgress() {
        let latestWeek = Stats.week
        if latestWeek != week { week = latestWeek }
        let latestStreak = Stats.currentStreak
        if latestStreak != streakDays { streakDays = latestStreak }
    }

    private func toggleClaudeHook() {
        guard let executable = Bundle.main.executablePath else {
            hookMessage = "Couldn't find the app's own program to register."
            return
        }
        do {
            let command = claudeHookCommand(executable: executable)
            try updateClaudeSettings { isHookInstalled ? removingClaudeHook(from: $0) : addingClaudeHook(to: $0, command: command) }
            isHookInstalled.toggle()
            hookMessage = isHookInstalled ? "Done. New Claude Code sessions will pick it up." : "Removed."
        } catch {
            hookMessage = "Couldn't update Claude Code settings: \(error)"
        }
    }

    private func toggleStatusline() {
        guard let executable = Bundle.main.executablePath else {
            hookMessage = "Couldn't find the app's own program to register."
            return
        }
        do {
            if isStatuslineInstalled { try removeStatusline() } else { try installStatusline(executable: executable) }
            isStatuslineInstalled.toggle()
            hookMessage = isStatuslineInstalled
                ? "Done. The numbers appear after Claude Code's next reply."
                : "Removed. Your original status line is back."
        } catch {
            hookMessage = "Couldn't update Claude Code settings: \(error)"
        }
    }

    private func setLaunchAtLogin(_ isOn: Bool) {
        do {
            if isOn { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn't change launch at login: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
