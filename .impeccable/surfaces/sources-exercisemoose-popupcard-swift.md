---
version: 1
slug: "sources-exercisemoose-popupcard-swift"
primary_target: "Sources/ExerciseMoose/PopupCard.swift"
related_targets: ["Sources/ExerciseMoose/MooseApp.swift","Sources/ExerciseMoose/Settings.swift"]
---

# Surface: break popup (Mac app)

Scope: the popup card that drops from the menu bar (regular, agent and limit breaks; Done/Snooze marks),
plus Settings and the menu following its palette. Mode: Operate (the visitor completes a task: do the move,
press Done).

Audience and job: a developer mid-focus follows a 30-second chair exercise at a glance, then returns to work.
Constraints: avatar is the hero; bigger card (sizes ~340/380/440pt); the timer guides step by step through the
exercise's three tips; nothing cartoonish or gamey; Reduce Motion and VoiceOver honored; light and dark appearance.
Unresolved: the sample avatar has no real standing picture (author to provide).

## Direction contract

THESIS: Each break is set like a Swiss poster, your figure on a full-strength field and one monumental number; it refuses the fitness-app card of gradient stage, progress ring and pill buttons.

OWN-WORLD: White ground (near-black in Dark Mode), Helvetica Neue bold and medium on a strict grid, sharp edges inside the 12pt panel. Each exercise type owns one hue at full strength: stretch ultramarine #1D3FD6, strength signal yellow #FFC400, move green #00875A. Swiss red #E30613 is held back for Done alone.

STORY: A glance says what to do and for how long; the current step leads; Done counts the break, Snooze says when it returns.

FIRST VIEWPORT: A 380pt card under the menu bar icon. A full-width field fills the top half with the figure standing on its bottom edge, the reason label top-left, the countdown top-right at about 40% of the field's height. Below: the exercise name at 30pt, three step columns with 3pt time bars, Snooze as text left, a red Done block right.

FORM: Swiss International Typographic Style grid, candidate 7 of 7, seed:ab28427c4c3f1337. Signature move: steps 1·2·3 fill in time beneath the monumental countdown, and Done stamps today's count on a red field before the card leaves. Raises: Manual Tab Board (one colour held back), Warm Consumer App (red only where you press), Ticket Wallet (Done and Snooze mark the card), Datamatics (Reduce Motion: nothing decorative moves).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
