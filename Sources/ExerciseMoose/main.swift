// Exercise Moose: menu-bar app that pops up every N minutes and shows you an exercise.
// Build + install: ./build.sh    Tests: swift test    Flags: --test (popup every 10s), --make-icon <png>
import AppKit

let args = CommandLine.arguments
if isInvokedAsCLI(args) {
    exit(runMooseCommand(Array(args.dropFirst())))
}
if args.contains("--statusline") {
    exit(runStatuslineCommand())
}
if let flag = args.firstIndex(of: "--agent") {
    exit(runAgentCommand(arguments: Array(args[(flag + 1)...])))
}
if let flag = args.firstIndex(of: "--make-icon") {
    guard flag + 1 < args.count else {
        FileHandle.standardError.write(Data("usage: --make-icon <output.png>\n".utf8))
        exit(2)
    }
    do {
        try writeAppIcon(to: URL(fileURLWithPath: args[flag + 1]))
        exit(0)
    } catch {
        FileHandle.standardError.write(Data("make-icon failed: \(error)\n".utf8))
        exit(1)
    }
}
UserDefaults.standard.register(defaults: DEFAULT_PREFS)
let mooseApp = MooseApp(isTestMode: args.contains("--test"))
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = mooseApp
app.run()
