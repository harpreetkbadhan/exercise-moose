---
name: Exercise Moose
description: A movement break set like a Swiss poster, your own figure on one full-strength field.
colors:
  field-ultramarine: "#1D3FD6"
  field-signal-yellow: "#FFC400"
  field-green: "#00875A"
  done-red: "#E30613"
  done-red-pressed: "#B8000F"
  field-ink-white: "#FFFFFF"
  ground-white: "#FFFFFF"
  ground-black: "#0B0B0B"
  ink-black: "#0A0A0A"
  ink-white: "#F2F2F2"
  ink-secondary-light: "#5C5C5C"
  ink-secondary-dark: "#A3A3A3"
  rule-light: "#E3E3E3"
  rule-dark: "#2E2E2E"
  page-ground-dark: "#0D1117"
  terminal-ground: "#1E1F22"
typography:
  countdown:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "126px"
    fontWeight: 700
    lineHeight: 0.9
    letterSpacing: "-0.04em"
    fontFeature: "tnum"
  stamp-figure:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "270px"
    fontWeight: 700
    lineHeight: 0.8
    letterSpacing: "-0.04em"
  title:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.02em"
  stamp-line:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "17px"
    fontWeight: 700
  step-number:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "15px"
    fontWeight: 700
  button:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "15px"
    fontWeight: 700
  step-current:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "13px"
    fontWeight: 700
  step-other:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "13px"
    fontWeight: 500
  label:
    fontFamily: "Helvetica Neue, Inter Tight, sans-serif"
    fontSize: "12px"
    fontWeight: 700
  readme-headline:
    fontFamily: "Helvetica Neue, Helvetica, sans-serif"
    fontSize: "98px"
    fontWeight: 700
    lineHeight: 0.95
    letterSpacing: "-0.045em"
  readme-panel-heading:
    fontFamily: "Helvetica Neue, Helvetica, sans-serif"
    fontSize: "38px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.035em"
  readme-wordmark:
    fontFamily: "Helvetica Neue, Helvetica, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    letterSpacing: "-0.01em"
  readme-line:
    fontFamily: "Helvetica Neue, Helvetica, sans-serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: 1.4
rounded:
  none: "0px"
  panel: "12px"
spacing:
  bar: "3px"
  field-inset: "12px"
  step-gap: "12px"
  after-title: "12px"
  after-field: "14px"
  card: "16px"
  after-steps: "16px"
  readme-inset: "44px"
  readme-column-gap: "40px"
  readme-rule: "3px"
components:
  card-light:
    backgroundColor: "{colors.ground-white}"
    textColor: "{colors.ink-black}"
    rounded: "{rounded.panel}"
    padding: "{spacing.card}"
    width: "380px"
  card-dark:
    backgroundColor: "{colors.ground-black}"
    textColor: "{colors.ink-white}"
    rounded: "{rounded.panel}"
    padding: "{spacing.card}"
    width: "380px"
  field-stretch:
    backgroundColor: "{colors.field-ultramarine}"
    textColor: "{colors.field-ink-white}"
    rounded: "{rounded.none}"
    height: "300px"
  field-strength:
    backgroundColor: "{colors.field-signal-yellow}"
    textColor: "{colors.ink-black}"
    rounded: "{rounded.none}"
    height: "300px"
  field-move:
    backgroundColor: "{colors.field-green}"
    textColor: "{colors.field-ink-white}"
    rounded: "{rounded.none}"
    height: "300px"
  button-done:
    backgroundColor: "{colors.done-red}"
    textColor: "{colors.field-ink-white}"
    typography: "{typography.button}"
    rounded: "{rounded.none}"
    width: "116px"
    height: "44px"
  button-done-pressed:
    backgroundColor: "{colors.done-red-pressed}"
    textColor: "{colors.field-ink-white}"
  button-snooze:
    textColor: "{colors.ink-secondary-light}"
    typography: "{typography.step-other}"
    height: "44px"
  time-bar:
    backgroundColor: "{colors.rule-light}"
    rounded: "{rounded.none}"
    height: "{spacing.bar}"
  stamp-counted:
    backgroundColor: "{colors.done-red}"
    textColor: "{colors.field-ink-white}"
    padding: "28px"
  readme-banner-light:
    backgroundColor: "{colors.ground-white}"
    textColor: "{colors.ink-black}"
    typography: "{typography.readme-headline}"
    width: "1280px"
    height: "460px"
  readme-banner-dark:
    backgroundColor: "{colors.page-ground-dark}"
    textColor: "{colors.ink-white}"
    typography: "{typography.readme-headline}"
    width: "1280px"
    height: "460px"
  readme-banner-field:
    backgroundColor: "{colors.field-ultramarine}"
    rounded: "{rounded.none}"
    width: "470px"
  readme-terminal:
    backgroundColor: "{colors.terminal-ground}"
    rounded: "10px"
    height: "400px"
  readme-card-gif:
    width: "340px"
  readme-menu:
    width: "318px"
---

# Design System: Exercise Moose

## Overview

**Creative North Star: "The Swiss Break Poster"**

Every break is set like an International Typographic Style poster: the user's own figure stands on the bottom edge of one full-strength colour field, one monumental number holds the top right, and everything else sits on a strict grid in a single grotesque. The card is the product's point, so the system is built to be read in one glance from across a desk: one hue, one number, three steps, one red thing to press.

The world is flat, square-edged and saturated. Depth, decoration and motion are withheld so the avatar and the countdown carry the moment. Light and Dark appearance swap only the card's ground, ink and rules; the exercise fields and the red stay identical in both, because they are signals, not surfaces.

This system governs the native break card (`Sources/ExerciseMoose/PopupCard.swift`, `PopupContent.swift`), the Settings and menu that borrow its ultramarine, and the 300px web copy of the card on the landing page. The landing page around that copy keeps its own pre-existing paper-and-teal world (Unbounded, Figtree, Kalam; `website/app/globals.css`); it is context for the card, not part of this system.

The same world also sets the GitHub README (`README.md`) and the `docs/` pages it links to. GitHub allows no CSS, so the world arrives there as pictures: every picture is a light and dark pair of 2x rasters, built around offscreen renders of the real AppKit views (the break card from `PopupCard.swift`, the menu header from `MenuHeader.swift`), each baking in the page's own ground so it sits on the README like printed matter rather than a screenshot in a frame. The text between pictures is GitHub's own type; the pictures carry Helvetica Neue, the ultramarine field and the held-back red.

**Key Characteristics:**
- One full-strength field per exercise kind; the figure stands on its bottom edge.
- One monumental number per card: the countdown, or the stamp's count or time.
- Helvetica Neue only, bold and medium, display sizes tracked tight.
- Sharp edges everywhere inside a 12pt panel radius.
- Swiss red held back for Done and the counted stamp alone.
- Nothing decorative moves; stamps are hard cuts.
- On the README, every picture is a real render on the page's own ground, flush with the text edge.

## Colors

Three full-strength signal hues, one reserved red, and a strictly neutral ground that flips with the appearance.

### Primary
- **Ultramarine** (field-ultramarine): the stretch field. Also the app's one accent outside the card: the Settings form tint and the history chart's bars (full strength on goal days, 40% opacity below goal).
- **Signal Yellow** (field-signal-yellow): the strength field. The only field that takes near-black ink.
- **Signal Green** (field-green): the move field.

### Secondary
- **Swiss Red** (done-red): the Done block and the full-card stamp after a counted break. Pressed, Done drops to **Deep Swiss Red** (done-red-pressed).

### Neutral
- **Card White / Card Black** (ground-white / ground-black): the card ground in Light and Dark Mode.
- **Ink Black / Ink White** (ink-black / ink-white): title, step numbers, current step, time-bar fill. Ink Black is also the ink on the yellow field.
- **Secondary Grey** (ink-secondary-light / ink-secondary-dark): steps not yet or no longer current, and Snooze.
- **Rule Grey** (rule-light / rule-dark): the unfilled track of each time bar.
- **Field White** (field-ink-white): ink on ultramarine, green and red.
- **Page Ground Dark** (page-ground-dark): GitHub's dark canvas, baked into every dark README raster so the picture has no visible edge. The light rasters bake Card White, which is also GitHub's light canvas.
- **Terminal Ground** (terminal-ground): the illustrated terminal panels in the README's before/after picture only; the same in both appearances, because a terminal is dark either way.

### Named Rules
**The One Field Rule.** Each exercise kind owns exactly one hue, at full strength, identical in Light and Dark Mode. On the card a field is never tinted, graded or shared with another kind.

**The Held-Back Red Rule.** Swiss red appears on the card only where you press (Done) and on the stamp that thanks you for pressing it. Snooze and agent stamps take the exercise's own field; red is never a warning or a flash.

**The Ink-on-Field Rule.** White on ultramarine, green and red; Ink Black on signal yellow. Every field/ink pair holds WCAG AA at the 12pt bold label size.

**The Page's Own Ground Rule.** A README raster's background is exactly the page it sits on: Card White for light, Page Ground Dark for dark, swapped by `<picture>` and `prefers-color-scheme`. No picture brings its own backdrop, frame or card behind the composition.

## Typography

**Display Font:** Helvetica Neue (web: Helvetica Neue, else self-hosted Inter Tight, via `--font-grid`)
**Body Font:** the same family; there is no second face.
**Label Font:** the same family.

**Character:** One neutral grotesque in two weights, bold and medium, doing everything. Hierarchy comes from scale and weight contrast, not from changing faces.

### Hierarchy
Sizes below are the medium card (380pt); the small and large cards scale with them.
- **Countdown** (bold, 42% of the field height: 109 / 126 / 151pt, tracking -0.04em, right-aligned with "seconds" under it at 12pt bold): the one monumental number, top-right of the field.
- **Stamp Figure** (bold, up to 90% of the field height, fitted to the card width; -0.04em for a single numeral, -0.02em for a time like 21:45 so digits never touch): today's count or the snooze return time, standing on the stamp's detail line.
- **Title** (bold, 26 / 30 / 34pt, tracking -0.02em, one line, truncates): the exercise name under the field.
- **Stamp Line** (bold, 17pt): the stamp's headline at top and detail at bottom.
- **Step Number** (bold, 15pt): the anchor of each step column.
- **Step** (13pt, bold in ink when current, medium in secondary grey otherwise, up to three lines): the exercise tips.
- **Label** (bold, 12pt): the field's reason line top-left ("Seated · Stretch", "Claude is working") and the countdown unit.

### README compositions
The README's prose is GitHub's type and is not styled. Type set inside the README pictures (at 1x composition size, captured at 2x) uses the same family, Helvetica Neue bold and medium:
- **README Headline** (bold, 98px, line-height 0.95, tracking -0.045em, two lines): the banner's "Move while / your AI codes.", nudged 4px left so its optical edge meets the text edge.
- **README Panel Heading** (bold, 38px, tracking -0.035em, one line): each before/after column heading; its lead-in ("Without:", "With Moose:") is set in secondary grey, the claim in full ink.
- **README Wordmark** (bold, 22px, tracking -0.01em): "Exercise Moose" beside the 40px logo, top-left of the banner.
- **README Line** (medium, 18px, line-height 1.4, secondary grey, max 640px): the banner's one-line pitch, its opening phrase bold in ink.

### Named Rules
**The One Family Rule.** Helvetica Neue in bold and medium is the only type on the card. No second face, no italic, no system display fallback chosen on purpose.

**The Monumental Number Rule.** Each card state has exactly one oversized number, and it is set tight. Nothing else on the card competes with it in size.

**The Bold-Means-Now Rule.** Only the current step is bold in full ink; columns are measured in bold so switching steps never reflows the card.

## Layout

A single-column card on a strict grid. Card widths are 340 / 380 / 440pt with a 300px web copy; the field is 260 / 300 / 360pt tall (236px on the web). The card pads 16pt on all sides, and the field spans the full content width.

Inside the field: the figure, cropped to its visible pixels, stands on the bottom-left edge at 62% of the content width; the reason label sits 12pt in from the top-left; the countdown sits 12pt in from the top-right, cap height aligned to the inset.

Below the field the rhythm is fixed: 14pt to the title, 12pt to the steps, 16pt to the footer. The three step columns divide the content width evenly with 12pt gutters; each column is number, tip, then a 3pt time bar on a shared baseline, all columns equal height. The footer sets Snooze as text at left and the 116 x 44pt Done block at right.

Stamps cover the whole card, inset 28pt (card padding plus field inset): headline at top-left, figure and detail line at bottom-left.

### README
The README is one column at GitHub's text measure. Pictures stack above the text that explains them, never beside it. Full-width compositions (`width="100%"`) are drawn at 1280px: the banner is 1280 x 460 with a 470px ultramarine field bleeding off the right edge and the 300px card set 70px in from the right and 34px down from the top, while the wordmark and line sit 44px in from the top and bottom. The before/after is two equal columns with 40px between them, each opened by a 3px ink rule, the heading 14px below, then a 400px terminal 22px below that. Fixed-width pictures are shown at half their pixel width: the card GIF at 340px (680px raster), the menu at 318px (636px raster). At phone width the full-width pictures scale down with the column; nothing reflows beside them.

**The One Left Edge Rule.** The banner's wordmark, headline and line, the before/after rules and headings, the card GIF and the menu all start exactly at the README's text edge. A composition never adds its own left margin.

**The No Float Rule.** No `align`ed images. GitHub adds 20px of padding beside them, and a float either squeezes the text into slivers or overflows at phone width. A picture goes above its text.

The `docs/` pages are plain reference prose. Each opens with a breadcrumb line, `[Exercise Moose](../README.md) / Page name`, above its single H1, and reuses the README's rasters rather than shooting new ones.

## Elevation & Depth

Flat. Nothing inside the card casts or receives a shadow; layering is done by the field's colour against the ground. The only depth is the floating panel's own system window shadow under the card's 12pt corners (on the web, one soft drop shadow, `0 24px 50px -18px rgb(0 0 0 / 0.55)`, stands in for it).

On the README the panel shadow is baked into the rasters, and it falls only right and down so nothing crosses the shared text edge. The light card GIF keeps a soft panel shadow on white; on the dark ground, where a shadow would not read, the card takes a hairline rim instead. The menu picture carries a 0.5px rim and a shadow offset right and down (`0 0 0 0.5px rgb(0 0 0 / .18), 16px 14px 30px -10px rgb(0 0 0 / .35)`). The card set inside the banner and the before/after terminal casts a plain drop shadow downward (`drop-shadow(0 22px 40px rgb(0 0 0 / .35))` in the banner, `drop-shadow(0 16px 26px rgb(0 0 0 / .5))` in the terminal), clear of the left edge.

### Named Rules
**The Flat Poster Rule.** The card is printed, not stacked: no inner shadows, glows, gradients or translucent layers on the field, the steps or the buttons.

**The Right-and-Down Rule.** On the README a shadow is cast only to the right and downward, never left past the text edge. Where a shadow would vanish on the dark ground, a hairline rim replaces it.

## Shapes

Square inside a soft frame. The panel's outer corners round at 12pt (10px on the web copy) and clip everything inside; the field, the Done block, the time bars and the stamp are all sharp rectangles. There are no pills, rings or circles.

**The Sharp Inside Rule.** The only radius in the system is the panel's outer corner. Anything set inside the card is square.

The README pictures add no shapes of their own. Rounded corners appear only where they depict real macOS chrome: the card panel, the menu (10px) and the illustrated terminal windows (10px, with their three window controls). The banner field and the before/after rules are sharp.

## Components

### Field (signature)
A full-strength rectangle in the exercise kind's hue. Holds the avatar video or still standing on its bottom edge, the 12pt bold reason label top-left, and the countdown with its "seconds" unit top-right ("time's up" at zero). VoiceOver reads the countdown as "N seconds left".

### Step Columns and Time Bars (signature)
Three equal columns, one per tip. The exercise time splits evenly across them; each column's 3pt bar fills in ink across its share, so bars fill one after another. Fills animate linearly over one second per tick so per-second updates read as one continuous fill; with Reduce Motion they jump without animation.

### Buttons
- **Shape:** sharp rectangle (0px).
- **Done:** Swiss red block, 116 x 44pt, "Done" in white 15pt bold, centred. Pressed: Deep Swiss Red. No Return shortcut, so Enter typed in another app never counts a break.
- **Snooze:** borderless text, "Snooze N min" in 13pt medium secondary grey, as tall as Done so it is just as easy to hit.

### Cards / Containers
- **Corner Style:** 12pt outer radius, clipping.
- **Background:** Card White in Light Mode, Card Black in Dark Mode.
- **Shadow Strategy:** system panel shadow only (see Elevation & Depth).
- **Border:** none.
- **Internal Padding:** 16pt.

### Stamp (signature)
Before the card leaves, a full-card stamp covers it: headline top-left, one monumental figure, detail line bottom-left, all in the field's ink. Counted breaks take Swiss red with today's count ("Nice!" / "3" / "of 6 today"); snoozes take the exercise field with the return time ("Back at" / "21:45" / "Snoozed"); an agent's finish takes the exercise field with a heavy checkmark in place of the number ("Claude is done" / "Back to work"). The stamp is a hard cut, like a print changing over, and it swallows clicks so Done counts once.

### README Picture
A `<picture>` with a dark `<source>` (`media="(prefers-color-scheme: dark)"`) over a light `<img>`. Both rasters are 2x, bake their page ground, and embed their provenance ("Origin: rendered, not generated", naming the source view and the composition), in PNG metadata or, for GIFs, in a `.json` sidecar beside the file. The alt text describes what the picture shows and the numbers in it. The app views in each picture are real offscreen renders; the surrounding compositions (`.impeccable/mocks/readme/*.html`) are captured with Playwright, and the terminal output and menu items in them are illustrations.

### README Banner
Wordmark with logo top-left, the two-line README Headline below it, the README Line at the bottom-left, and on the right an ultramarine field running full height with the break card in its "Claude is working" state on it. It replaces a title, tagline and badge row.

### Before/After
Two equal columns under 3px ink rules: "Without: 4 minutes sitting." over a terminal in which Claude Code works for 4m 12s, and "With Moose: 30 seconds moving." over the same terminal with the break card on top of it. The story is told by the two pictures, not by a feature list.

### Card GIF (signature motion)
`docs/readme/card-{light,dark}.gif`: 32 frames of the real card, a neck stretch counting 30 to 0 at 0.28s per frame with each step's bar filling in turn, then a 2.2s hold on the "Claude is done" stamp. 680px wide and shown at 340px, with one shared palette. Light sits on white with the soft panel shadow; dark sits on Page Ground Dark with a hairline rim. The cut to the stamp is a hard cut, as in the app.

### Menu Picture
The real menu header (next break, streak, Claude Code context and plan limits as bars, the warning at 80% and above) over illustrated native menu items in the system font, flush left, shown at 318px. It is used on the README and again on the `docs/` pages that describe the menu.

## Do's and Don'ts

### Do:
- **Do** give each exercise kind its own field: ultramarine for stretch, signal yellow for strength, green for move, identical in Light and Dark Mode.
- **Do** keep the avatar standing on the field's bottom edge, cropped to its visible pixels.
- **Do** set one monumental number per card state at 42% (countdown) or up to 90% (stamp) of the field height, tracked -0.04em.
- **Do** use Helvetica Neue bold and medium only, and the `--font-grid` stack on the web copy.
- **Do** keep everything inside the card square; round only the panel's outer corners (12pt).
- **Do** let the ultramarine field colour carry the app's accent elsewhere (Settings tint, history chart).
- **Do** honor Reduce Motion by dropping the time-bar animation, and announce cards and stamps to VoiceOver.
- **Do** build README pictures from offscreen renders of the real views, at 2x, as light and dark pairs on #FFFFFF and #0D1117, with their provenance embedded.
- **Do** start every README picture at the text edge and cast its shadow only right and down; use a hairline rim on the dark ground.
- **Do** stack each README picture above the text it illustrates.
- **Do** tell the README in prose under plain headings, and keep the health note on the README itself.
- **Do** move long reference material to a `docs/` page that opens with a breadcrumb back to the README.

### Don't:
- **Don't** use Swiss red for anything on the card except Done and the counted stamp.
- **Don't** add gradients, progress rings, pill buttons or inner shadows to the card.
- **Don't** tint, lighten or mix the field hues on the card, or let two kinds share one.
- **Don't** introduce a second typeface or set any other element at a size that competes with the monumental number.
- **Don't** fade, slide or bounce the stamp in; it cuts.
- **Don't** float README images with `align`, or set two images side by side as separate elements; a side-by-side is one composed raster.
- **Don't** show the app in the README through mockups or redrawn imitations of its views; render the real views (the avatar inside them is the user's own figure, as in the app).
- **Don't** put badge rows, feature-bullet lists or eyebrow labels above headings on the README.
