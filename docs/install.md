[Exercise Moose](../README.md) / Install

# Install

Needs macOS 14 or later, on Apple silicon or Intel. Pick one:

## 1. Terminal (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/harpreetkbadhan/exercise-moose/main/install.sh | bash
```

This downloads the latest release, checks it against the release's SHA-256 checksum (nothing is installed if
it doesn't match), installs **Exercise Moose** into Applications, adds the `moose`
terminal command (it may ask for your password to write `/usr/local/bin/moose`) and starts the app.
Installing from the terminal also skips macOS's "unidentified developer" prompt.

## 2. Download

1. Download `ExerciseMoose-x.y.zip` from the [latest release](https://github.com/harpreetkbadhan/exercise-moose/releases/latest), unzip it and drag **Exercise Moose** into Applications.
2. The app isn't signed with a paid Apple developer certificate, so macOS blocks the first launch. Open it once,
   then go to **System Settings → Privacy & Security** and click **Open Anyway**.

## 3. Build from source

Needs the Swift toolchain (`xcode-select --install`) and ffmpeg (`brew install ffmpeg`).

```bash
git clone https://github.com/harpreetkbadhan/exercise-moose.git
cd exercise-moose
./build.sh          # builds "Exercise Moose.app" with the sample avatar and installs it into /Applications
open "/Applications/Exercise Moose.app"
sudo ln -sf "/Applications/Exercise Moose.app/Contents/MacOS/ExerciseMoose" /usr/local/bin/moose   # optional: terminal command
```

The app comes with a sample avatar (the author), so it works straight away. [Make your own](avatar.md) any time.

Next: [using Exercise Moose](using.md), or [connect Claude Code](claude-code.md).
