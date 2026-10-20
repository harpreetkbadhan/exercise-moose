[Exercise Moose](../README.md) / Development

# Development

- Code: `Sources/ExerciseMoose/` (`main.swift` entry, `MooseApp.swift` menu bar + timers, `MenuHeader.swift`
  the menu's header, `Hold.swift` pause and snooze, `PopupCard.swift`, `Settings.swift`, `CLI.swift` for
  `moose`, `Agents.swift` / `ClaudeHook.swift` / `ClaudeUsage.swift` for Claude Code).
- Tests: `swift test` (Swift Testing, in `Tests/ExerciseMooseTests/`; they never touch your real `~/.claude`).
  `release.sh` and GitHub Actions run them too, along with ShellCheck.
- `./build.sh` compiles with `./compile.sh`: one universal program for Apple silicon and Intel that runs on the
  macOS version in `Info.plist` (14.0), whatever Mac builds it.
- Test mode, popup every 10 seconds: `"/Applications/Exercise Moose.app/Contents/MacOS/ExerciseMoose" --test`
- Release: `./release.sh` runs the tests, then builds `build/ExerciseMoose-<version>.zip` (with the sample avatar
  inside) and its `.zip.sha256` without installing. Upload both to the GitHub release: the install command refuses
  a download without a matching checksum.
- Usage numbers missing? Create an empty file `~/Library/Application Support/Exercise Moose/debug-statusline`;
  the next status line refresh writes `statusline-fields.json` next to it with the field names Claude Code
  sends (names and types only, no values). Delete both files when done.
- Design: `PRODUCT.md` and `DESIGN.md` describe who the app is for and the Swiss Grid system the card, menu,
  website and README share. The README's pictures in `docs/readme/` are built around offscreen renders of the
  real break card and menu header; the banner text and the terminals around them are compositions.
