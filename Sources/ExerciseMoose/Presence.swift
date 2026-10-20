import AppKit
import CoreAudio
import CoreMediaIO

let AWAY_THRESHOLD: TimeInterval = 5 * 60
let TEST_AWAY_THRESHOLD: TimeInterval = 20
let PRESENCE_CHECK_SECONDS: TimeInterval = 30
let TEST_PRESENCE_CHECK_SECONDS: TimeInterval = 5
let CALL_RECHECK_SECONDS: TimeInterval = 60
let MAX_CALL_WAIT: TimeInterval = 30 * 60

enum BreakDecision: Equatable {
    case show, wait
}

/// Hold the popup while you're away or on a call, but never wait on a call forever
/// (some apps keep the mic open all day).
func breakDecision(isAway: Bool, isOnCall: Bool, waitForCalls: Bool, waitedSoFar: TimeInterval) -> BreakDecision {
    if isAway { return .wait }
    return waitForCalls && isOnCall && waitedSoFar < MAX_CALL_WAIT ? .wait : .show
}

/// Being away long enough counts as a break, so the timer restarts. A running pause or snooze keeps its own end.
func shouldResetAfterAway(awayFor: TimeInterval, resetWhenAway: Bool, threshold: TimeInterval, isHeld: Bool) -> Bool {
    resetWhenAway && !isHeld && awayFor >= threshold
}

/// Camera, microphone and idle checks. None of these need a permission prompt.
enum Presence {
    static var isOnCall: Bool { isCameraInUse() || isMicrophoneInUse() }

    static func idleSeconds() -> TimeInterval {
        guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }

    static func isCameraInUse() -> Bool {
        var address = cmioAddress(CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices))
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var dataSize: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &dataSize) == noErr else { return false }
        var devices = [CMIOObjectID](repeating: 0, count: Int(dataSize) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, dataSize, &used, &devices) == noErr else { return false }
        return devices.contains { device in
            var runningAddress = cmioAddress(CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere))
            var isRunning: UInt32 = 0
            var outSize: UInt32 = 0
            let status = CMIOObjectGetPropertyData(device, &runningAddress, 0, nil,
                                                   UInt32(MemoryLayout<UInt32>.size), &outSize, &isRunning)
            return status == noErr && isRunning != 0
        }
    }

    /// True when any app is recording from a microphone right now.
    static func isMicrophoneInUse() -> Bool {
        var address = audioAddress(kAudioHardwarePropertyProcessObjectList)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &dataSize) == noErr else { return false }
        var processes = [AudioObjectID](repeating: 0, count: Int(dataSize) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &dataSize, &processes) == noErr else { return false }
        return processes.contains { process in
            var inputAddress = audioAddress(kAudioProcessPropertyIsRunningInput)
            var isRunning: UInt32 = 0
            var size = UInt32(MemoryLayout<UInt32>.size)
            return AudioObjectGetPropertyData(process, &inputAddress, 0, nil, &size, &isRunning) == noErr && isRunning != 0
        }
    }

    private static func cmioAddress(_ selector: CMIOObjectPropertySelector) -> CMIOObjectPropertyAddress {
        CMIOObjectPropertyAddress(mSelector: selector,
                                  mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                  mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    }

    private static func audioAddress(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }
}

/// Notices when you leave (screen lock, sleep, no input for a while) and reports how long you were gone.
final class PresenceMonitor: NSObject {
    private let threshold: TimeInterval
    private let checkInterval: TimeInterval
    private let onReturn: (TimeInterval) -> Void
    private var awaySince: Date?
    private var isLocked = false
    private var idleTimer: Timer?

    var isAway: Bool { awaySince != nil }

    init(threshold: TimeInterval, checkInterval: TimeInterval, onReturn: @escaping (TimeInterval) -> Void) {
        self.threshold = threshold
        self.checkInterval = checkInterval
        self.onReturn = onReturn
        super.init()
    }

    func start() {
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(screenLocked),
                                name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        distributed.addObserver(self, selector: #selector(screenUnlocked),
                                name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(willSleep),
                                                          name: NSWorkspace.willSleepNotification, object: nil)
        idleTimer = Timer.scheduledTimer(timeInterval: checkInterval, target: self, selector: #selector(checkIdle),
                                         userInfo: nil, repeats: true)
    }

    @objc private func screenLocked() {
        isLocked = true
        markAway(since: Date())
    }

    @objc private func screenUnlocked() {
        isLocked = false
        markBack()
    }

    @objc private func willSleep() {
        markAway(since: Date())
    }

    @objc private func checkIdle() {
        let idle = Presence.idleSeconds()
        if idle >= threshold {
            markAway(since: Date().addingTimeInterval(-idle))
        } else if !isLocked {
            markBack()
        }
    }

    private func markAway(since: Date) {
        if awaySince == nil { awaySince = since }
    }

    private func markBack() {
        guard let since = awaySince else { return }
        awaySince = nil
        onReturn(Date().timeIntervalSince(since))
    }
}
