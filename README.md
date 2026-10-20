<p align="center">
  <img src="docs/logo.png" width="200" alt="Exercise Moose logo: a smiling teal moose in a headband">
</p>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/banner-dark.png">
  <img src="docs/readme/banner-light.png" width="100%" alt="Exercise Moose. Move while your AI codes. A Mac menu bar app: your own avatar shows you a 30-second chair exercise while Claude Code works. Beside it, the break card: Claude is working, Neck Stretch, 17 seconds left.">
</picture>

**Claude Code has been refactoring for four minutes. You have been watching the spinner.**
Exercise Moose turns that wait into a 30-second chair exercise, shown by your own avatar, and tells you
when Claude is done.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/before-after-dark.png">
  <img src="docs/readme/before-after-light.png" width="100%" alt="Without: 4 minutes sitting, a terminal where Claude Code reads, plans, edits and runs tests for 4 minutes 12 seconds. With Moose: 30 seconds moving, the same terminal with the break card showing a neck stretch.">
</picture>

```bash
curl -fsSL https://raw.githubusercontent.com/harpreetkbadhan/exercise-moose/main/install.sh | bash
```

macOS 14 or later, Apple silicon and Intel. Free, MIT, native Swift. Nothing leaves your Mac.
Other ways to install: [download or build from source](docs/install.md).

## One Claude task, three moments

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/card-dark.gif">
  <img src="docs/readme/card-light.gif" width="340" alt="The break card counting down a neck stretch while Claude is working: the seconds fall, each step's bar fills in turn, then the card turns to Claude is done.">
</picture>

**1. Claude starts working.**
Send Claude Code a task. If it's still going after a minute, a card drops down from your menu bar:
*Claude is working*.

**2. You move for 30 seconds.**
Your avatar shows the exercise on its field. Three steps, the current one in bold, each bar filling as the
seconds count down.

**3. Claude is done.**
The card says so and leaves. Back to your terminal.

No agent running? It still works on its own: a break every 30 minutes, 12 seated exercises and a stand-up
break every 1–2 hours. [Connect Claude Code](docs/claude-code.md) with one button in Settings.

## Your limits, one click away

Click your face in the menu bar. The next break and your streak sit on top; under them, Claude Code's
context window and its 5-hour and weekly plan limits, as bars.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/menu-dark.png">
  <img src="docs/readme/menu-light.png" width="318" alt="The menu: next break in 31 minutes, a 1-day streak with 6 of 6 breaks today, then Claude Code on Opus 5.5 with context at 43% of 1M, the 5-hour limit at 71% and the weekly limit at 85% with a warning, then Show now, Pause 1 hour, Settings and Quit.">
</picture>

Limits at 80% or more get a warning. A nearly full context tells you it's time to `/compact`. When the
5-hour limit runs out, your avatar suggests a walk.

Turn it on with **Install** next to Usage in the menu (Settings → AI agents). The numbers come from Claude
Code's own status line data, your status line still looks exactly as before, and plan limits show on Pro and
Max plans. [How it works](docs/claude-code.md#usage-in-the-menu).

```console
$ moose status
Next break in 23 min
3-day streak, 4 of 6 today
Claude Code: Opus 5.5
   Context 68% of 1M
   5-hour limit 4%, resets 18:40
   Weekly limit 16%, resets Fri 14:00
```

## It stays out of your way

While your camera or mic is on, the break waits until the call ends, for up to 30 minutes. It only reminds
you between 9:00 and 18:00 on weekdays unless you change that, and a locked screen, sleep or 5 idle minutes
counts as a break.

The figure on the card is a person, not a mascot: the repo ships with the author as a sample avatar, and you
can [make your own](docs/avatar.md) from a photo with ChatGPT and Kling. It is Swift and AppKit, with no
Electron and no dependencies, about 7 MB with the sample avatar. No network calls, no accounts, no login tokens.

> [!IMPORTANT]
> **Health note:** Exercise Moose is a reminder tool, not medical advice. The exercises are gentle desk
> movements, but everyone's body is different. Move slowly, stay within a comfortable range and stop if
> anything hurts. If you have an injury, pain, a medical condition or are pregnant, ask a doctor or
> physiotherapist which exercises are right for you. The AI-generated videos can show imperfect form,
> so follow the written tips on each card. You use the app at your own risk.

## Docs

| Guide | What's in it |
|---|---|
| [Install](docs/install.md) | Terminal, download, or build from source |
| [Using Exercise Moose](docs/using.md) | The break card, the menu, Settings, the `moose` command |
| [Claude Code](docs/claude-code.md) | Agent breaks, usage in the menu, what the hook and status line do |
| [Make your own avatar](docs/avatar.md) | Prompts for your character and all 18 exercise videos |
| [Privacy and help](docs/privacy.md) | What stays on your Mac, uninstall, troubleshooting |
| [Development](docs/development.md) | Code map, tests, builds and releases |

## License

[MIT](LICENSE). The sample avatar images and videos in `raw/` show the author and are included for
demonstration; please use your own likeness in your builds.
