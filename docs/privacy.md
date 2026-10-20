[Exercise Moose](../README.md) / Privacy and help

# Privacy and help

## Privacy and safety

- Everything stays on your Mac: no network calls, no accounts, no login tokens.
- Changing `~/.claude/settings.json` keeps a backup of your untouched original
  (`settings.json.exercisemoose-backup`), keeps the file's permissions, re-sorts keys alphabetically,
  and writes nothing if another tool changed the file at the same moment.
- The hook, status line and `moose` commands talk to the app through local macOS notifications. Other apps
  on your Mac could send look-alike signals, so the app treats them as untrusted: numbers are validated,
  labels are cleaned and capped, and at most 50 agent sessions are tracked.

## Uninstall

1. In **Settings → AI agents**, click **Remove hook** and **Remove** (this restores your Claude Code settings).
2. Quit the app (`moose quit` or **Quit** in the menu) and delete it:

```bash
rm -rf "/Applications/Exercise Moose.app"
sudo rm -f /usr/local/bin/moose
rm -rf "$HOME/Library/Application Support/Exercise Moose"   # your avatar media
defaults delete com.appdevelopment.exercisemoose            # settings and streak
```

## Troubleshooting

| Problem | Fix |
|---|---|
| "Exercise Moose can't be opened" | Downloaded zip: **System Settings → Privacy & Security → Open Anyway**, or install with the [terminal command](install.md#1-terminal-recommended) |
| No popups | Check the menu: "Off until …" means work hours, "Waiting for your call" means camera/mic is in use. Try **Show now** |
| `moose: command not found` | Run the [build-from-source](install.md#3-build-from-source) `ln -sf` line, or make sure `/usr/local/bin` is in your `PATH` |
| Green edges around the avatar | `SIMILARITY=0.35 ./convert.sh` |
| Claude Code usage missing | Click **Install** next to Usage in the menu again (another tool may have replaced the status line), then send Claude a message |
