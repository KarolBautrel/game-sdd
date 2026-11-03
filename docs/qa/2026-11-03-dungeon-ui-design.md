# Dungeon interface design evidence

HISTORICAL V1 — superseded by the user's world-travel style correction on2026-11-04.
The original result is browser-review-v1.json; original screenshots remain in the
dated ignored run below. Default prototype/screenshots now refer to the revised
world-family candidate; see2026-11-04-dungeon-world-family.md for current evidence.

Date: 2026-11-03. Status: DESIGN DELIVERED / AWAITING USER REVIEW.
Owner: presentation026/slice026/milestone021. No playable UI replacement.

## Delivered

- Internet research with four primary-source skill files, version receipts,
  evaluation and adaptation limits in docs/design/dungeon-ui/RESEARCH.md.
- Complete dark fantasy layout, materials/type/state/asset and ordered native
  implementation plan in docs/design/dungeon-ui/README.md.
- Local clickable prototype with existing project assets/fonts and five review
  fixtures: exploration, low light, rubble obstacle, preparation and guarded-cache
  reward. Browser fixtures deliberately do not simulate a complete expedition.
- Five1920x1080 review screenshots beside the prototype; additional resolution
  captures in the ignored artifacts directory. No existing raster pixels edited.

## Browser evidence

Command: `node tools/qa/render_dungeon_ui_design.cjs`.
Final run: `artifacts/dungeon-ui-design/2026-11-03T22-59-24-909Z/review.json`.
Portable summary: `docs/design/dungeon-ui/browser-review.json`.
Result: PASS,37 checks,17 screenshots,0 JavaScript runtime exceptions.

Exploration, corridor choice and packing captured at1920x1080,1280x720,
2560x1440,3440x1440 and3840x2160. Checks cover local image/font loading, page
and header bounds, modal bounds, packing default/capacity/costs, low-light action,
forced-choice Escape rejection, modal focus loop, inert background, unlock after
choice, optional journal focus return, locked/non-adjacent travel rejection and
adjacent destination preview. Input is browser-local CDP, never OS input.

Visually inspected exploration1080p/720p/4K, obstacle1080p/4K and packing1080p.
Corrected the narrow inspector opener's stacked text and initial chart scroll
so the current company room remains visible. Enlarged decision sheets at1440p/4K.
The affected complete browser matrix was rerun successfully after these changes.

Chrome ran headless with a fresh task-owned profile, without visible windows,
desktop focus or access to the user's browser session. It was closed after review.
The harness uses installed Node24/Chrome and adds no package dependency.

Repository validation: `tools/validators/validate_all.py` PASS; `git diff --check`
PASS; local Markdown reference existence PASS. Product-file diff is empty.
Handoff completed2026-11-04 local time; browser run above is dated in UTC.

## Remaining acceptance

This is browser composition evidence only. It is not a Godot rendering check,
ordinary expedition victory, physical keyboard/gamepad test or user art approval.
UI scaling125%, long Polish text and the complete native state flow are specified
future Godot acceptance cases, not claimed by these37 checks.

The preview explicitly separates the review controls from its proposed game HUD.
Displayed fixture counts/effects are examples using current data, not the player's
save. Product scripts/scenes/resources, all character art and persistent saves
remain unchanged. Current source master is still the published656a15ed checkpoint;
this design work is local and uncommitted. No new skill/plugin is installed.

Next: user reviews the dark chart/material direction and preview/travel choice,
then can request the bounded opt-in Godot pilot described in presentation026.
