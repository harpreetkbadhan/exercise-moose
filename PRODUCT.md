# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Developers who sit at a Mac all day, many of them using Claude Code. They meet the app mid-focus: a card drops
from the menu bar while they are coding, and they follow a 30-second chair exercise at a glance, then get back to
work. The popup has to be glanceable, quick to act on, and never feel like nagging.

## Product Purpose

Exercise Moose turns sitting time into small movement breaks: every 30 minutes (configurable), and whenever an AI
agent such as Claude Code works on a long task, it shows a short exercise the user can do in their chair, with a
stand-up break every 1–2 hours. Success is the user actually doing the exercise and pressing Done, day after day
(daily goal and streak), without the reminders becoming something they mute.

## Positioning

The user's own avatar, made from their photo, demonstrates each exercise. Break reminders tell you to move; this
one shows you how, with you. It also knows when Claude Code is busy and turns that wait into the break.

## Operating Context

- Lives in the macOS menu bar; no Dock icon. A popup card drops down under the menu bar icon.
- Breaks wait while the camera or microphone is in use, stay quiet outside work hours, and count time away from
  the Mac as a break.
- Agent breaks: Claude Code hooks signal start/stop; after a minute of work a seated exercise appears with
  "Claude is working", then "Claude is done" when it finishes. When the 5-hour Claude limit runs out, a walk is
  suggested.
- The menu also shows Claude Code context and plan-limit usage, the next break and today's streak.
- A `moose` terminal command reports status and starts, pauses or resumes breaks.

## Capabilities and Constraints

- The core product is a native macOS 14+ menu bar app (Swift, AppKit and SwiftUI, no dependencies) in
  `Sources/ExerciseMoose/`. `website/` is the web landing page. Impeccable's platform field has no macOS value;
  native work follows Apple's macOS Human Interface Guidelines.
- Popup content per break: exercise name, three form tips, posture (seated / stand up), type (stretch, strength,
  move), a countdown (15–60 s), Done (counts toward the streak) and Snooze. Agent and limit breaks add a reason
  ("Claude is working", "Claude limit reached").
- Popup sizes: small, medium, large (user setting). Respects Reduce Motion.
- 18 built-in exercises (12 seated, 6 standing); any extra clip the user adds becomes a seated exercise.
- Avatar media: transparent HEVC video loops (`.mov` with alpha) per exercise, plus still pictures
  (`character.png` standing, `character-seated.png` seated) shown when an exercise has no video.
- Everything stays on the Mac: no accounts, analytics or network calls.

## Brand Commitments

- Name: Exercise Moose.
- The moose mark (teal moose with a sweatband; `raw/logo.png`, `raw/menubar-icon.png`) stays.
- Colors, typography and the look of the popup are open.
- The avatar is the hero of every break: it is the product's point.

## Evidence on Hand

- Sample avatar (the author) with two exercise clips: `raw/neck-stretch.mp4`, `raw/shoulder-rolls.mp4`.
- The sample's standing picture is currently identical to the seated one (`raw/character.png` and
  `raw/character-seated.png`); a real standing picture still has to be made by the author.
- No testimonials, user counts or press exist; do not invent any.

## Product Principles

1. The avatar shows, the words support: a glance at the card should be enough to start moving.
2. Interrupt kindly: arrive at the right moment, say why, and make leaving (Done, Snooze) effortless.
3. Never nag: respect calls, focus, work hours and absence; a skipped break is not a failure.
4. Progress over pressure: streaks and goals encourage, they don't scold.
5. Private by default: nothing leaves the Mac.

## Accessibility & Inclusion

Gentle desk movements, not medical advice: every surface keeps the health note's spirit (move slowly, stop if it
hurts). Honor Reduce Motion and VoiceOver; the popup announces itself because it never takes focus.
