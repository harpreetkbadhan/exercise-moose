import Foundation
import Testing
@testable import ExerciseMoose

private let t0 = Date()
private let two = AgentSessions.none.starting("a", at: t0).starting("b", at: t0.addingTimeInterval(30))

@Test("Sending a prompt starts the agent")
func promptStartsAgent() {
    #expect(agentEvent(fromHookName: "UserPromptSubmit") == .start)
}

@Test("Finishing stops it")
func stopStopsAgent() {
    #expect(agentEvent(fromHookName: "Stop") == .stop && agentEvent(fromHookName: "SessionEnd") == .stop)
}

@Test("Asking you for permission or input is waiting, not done")
func notificationWaitsForYou() {
    #expect(agentEvent(fromHookName: "Notification") == .wait)
}

@Test("Other hook events are ignored")
func otherHookEventsAreIgnored() {
    #expect(agentEvent(fromHookName: "PreToolUse") == nil)
}

@Test("The longest run comes from the earliest session")
func longestRunFromEarliestSession() {
    #expect(two.longestRun(at: t0.addingTimeInterval(90)) == 90)
}

@Test("Done only when every session has stopped")
func doneWhenAllStopped() {
    #expect(!two.stopping("a").isEmpty && two.stopping("a").stopping("b").isEmpty)
}

@Test("A repeat start keeps the first time")
func repeatStartKeepsFirstTime() {
    #expect(two.starting("a", at: t0.addingTimeInterval(60)).started["a"] == t0)
}

@Test("Forgotten sessions expire")
func forgottenSessionsExpire() {
    #expect(two.pruned(at: t0.addingTimeInterval(AGENT_STALE_AFTER + 60)).isEmpty)
}

@Test("A flood of sessions is capped")
func sessionFloodIsCapped() {
    let flood = (0..<200).reduce(AgentSessions.none) { $0.starting("s\($1)", at: Date()) }
    #expect(flood.started.count == MAX_AGENT_SESSIONS)
}

@Test("Labels from signals lose control characters and are capped")
func labelsAreSanitized() {
    #expect(sanitizedLabel("Cl\u{0}aude\n" + String(repeating: "x", count: 100)).count == MAX_LABEL_LENGTH)
}

@Test("A long run shows a break")
func longRunShowsBreak() {
    #expect(shouldShowAgentBreak(longestRun: 61, minRun: 60, sinceLastAgentBreak: .infinity, cooldown: 900,
                                 isPopupVisible: false, isEnabled: true, isHeld: false))
}

@Test("Short runs don't")
func shortRunsDont() {
    #expect(!shouldShowAgentBreak(longestRun: 30, minRun: 60, sinceLastAgentBreak: .infinity, cooldown: 900,
                                  isPopupVisible: false, isEnabled: true, isHeld: false))
}

@Test("A cooldown between agent breaks")
func cooldownBetweenAgentBreaks() {
    #expect(!shouldShowAgentBreak(longestRun: 61, minRun: 60, sinceLastAgentBreak: 300, cooldown: 900,
                                  isPopupVisible: false, isEnabled: true, isHeld: false))
}

@Test("No agent break during a pause or snooze")
func noAgentBreakWhileHeld() {
    #expect(!shouldShowAgentBreak(longestRun: 61, minRun: 60, sinceLastAgentBreak: .infinity, cooldown: 900,
                                  isPopupVisible: false, isEnabled: true, isHeld: true))
}

@Test("Never on top of another popup")
func neverOnTopOfAnotherPopup() {
    #expect(!shouldShowAgentBreak(longestRun: 61, minRun: 60, sinceLastAgentBreak: .infinity, cooldown: 900,
                                  isPopupVisible: true, isEnabled: true, isHeld: false))
}
