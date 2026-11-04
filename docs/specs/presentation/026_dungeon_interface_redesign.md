# Dungeon exploration interface redesign proposal

Status: WORLD-FAMILY DESIGN REVISION / NATIVE FOLLOW-UP AUTHORIZED.
Date: 2026-11-04.

The user requests a fresh dark fantasy dungeon UI plan and internet skill
research before continuing combat play. This authorizes research and review
artifacts. Later the user rejects the initial flat style and explicitly points
to the approved world-travel panel, reiterating DARK FANTASY. They then authorize
about two hours of staged native/gameplay polish, full desktop control and a push
after each episode. See milestone022; actual user art approval is not inferred.
The active presentation007 and dungeon/campaign domain rules remain in force
unless a subsequent owning spec explicitly extends them.

## Proposed presentation contract

Latest player review2026-11-04: the implemented dungeon is NOT visually accepted.
Dungeon-only correction brief is recorded in
[the ordered review checklist](../../qa/2026-11-04-player-review-checklist.md).
Keep the current world-travel view as the concrete comparison: no obvious square
texture repetition on backdrop/panel interiors, integrated party portraits with
fully readable current/max HP and one HP style/color, restrained truthful room
paths, and text/values within frame padding. This latest request supersedes
omitting every connector overlay in027; its rejected heavy pipes/crosses stay
excluded and all preview/confirm/event/domain guards remain. The later "DO dziela"
authorized implementation under031: correction is implemented / automated PASS,
awaiting user retest. See [stage72 evidence](../../qa/2026-11-04-dungeon-visual-cohesion.md).
No fresh user visual acceptance is inferred.

- Follow the approved world-travel panel directly. The user rejects the initial
  flat/minimal chart as visually unlike that target and reiterates DARK FANTASY.
  Reuse its actual textured charcoal leather, engraved brass/iron frame and
  button exports, illustrated aged parchment and Cinzel/Source Sans3 typography.
- Build the real room/corridor chart over an illustrated mine parchment, with
  readable native location plates, compact lamp/supply header and company rail.
  A light parchment inspector may accompany the dark panels, as in the approved
  inventory. Do not substitute olive flat fills, hairline-only frames or modern
  minimalist controls for this material family.
- Additional illustration concepts use the same built-in image-generation /
  editable Aseprite preparation workflow as campaign006. Keep exact prompts,
  references and deterministic export sources; concept art remains design-only.
- Distinguish current location, selection, visited/locked/threat/reward states
  using labels/symbols as well as color. Keep keyboard focus visibly separate.
- Offer a destination preview before an explicit travel commit. This is a
  proposed interaction change, not current implemented behavior. Route cost and
  available actions must come from the existing domain state/commands.
- Preparation, exploration, low light, pending corridor/room choice, combat
  pending, claimable reward/claimed loot, recovery/camp, exit/retreat and result
  each need a deliberate visible state. Only legal actions can execute.
- Pending events keep exclusive input ownership; a forced choice cannot be
  escaped to perform travel, recovery or retreat. Optional sheets restore focus.
- Do not introduce free walking, fog/scouting, extra heroes, stress, stamina,
  timers, loot capacity or new retreat penalties through a visual concept.
- Retain 2560x1440/canvas_items/expand settings. Use native responsive containers,
  a readable720p inspector drawer and scrollable long maps, not miniature labels.
- Production text/values remain native controls. Any future raster art uses
  provenance, editable Aseprite sources and deterministic exports.

## Review and evidence

Design brief and complete state/asset/implementation plan:
[dungeon-ui/README.md](../../design/dungeon-ui/README.md).
Primary-source skill comparison and limitations:
[RESEARCH.md](../../design/dungeon-ui/RESEARCH.md).
Proof/review owner: [slice026](slices/026_dungeon_interface_redesign.md).

Browser fixture evidence is design-only. An approved native target, affected
Godot tests, GPU capture matrix and normal managed expedition remain necessary
before a replacement could be accepted. No current player save is touched.
