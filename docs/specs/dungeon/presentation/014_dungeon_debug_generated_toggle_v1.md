# 014 Dungeon Debug Generated Toggle V1

Status: implemented
Date: 2026-07-16

## Intent

Expose the first generated dungeon draft in the playable debug dungeon scene.

The generated draft is not production content yet. The debug scene should let development switch between the authored Old Mine and the generated draft so corridor planning, reusable hazards, loadouts, traversal, and combat transitions can be tested through the same UI.

## Rules

- `DungeonDebug.tscn` remains the playable dungeon scene.
- The debug screen originally shipped with authored `Old Mine` as the default source; current beta testing now starts from generated medium-mine content while keeping `Old Mine` available through the source toggle.
- During expedition preparation, the player can switch between authored and generated dungeon data.
- Switching into generated data should create a fresh generated seed.
- Clicking the generated source action while already on generated data should reroll the generated draft during preparation.
- Switching source resets the current dungeon preparation state, selected room, selected loadout, pending hazards, and session data.
- Stage86 correction (2026-11-05): preview resets retain the session's
  `town_preparation` origin. Switching source, rerolling or changing generated
  difficulty never converts owned campaign preparation into a sandbox. These
  actions spend no company supplies and create no run receipt. Start continues
  through the ordinary `CampaignSession.begin_run` transaction; a failed packing
  transaction leaves preparation active. Standalone previews remain standalone.
  Proof: slices/056_managed_preparation_context.md and
  `scripts/presentation/dungeon_preparation_context_tests.gd`.
- Switching source rebuilds the graph and refreshes the resource tray, loadout panel, detail panel, route copy, and title.
- The source cannot be switched mid-expedition in this first debug slice.
- Returning from combat should preserve the active dungeon data from the session, including generated draft data.

## Non-Goals

- production dungeon selection UI;
- saving generated dungeons to disk;
- variable generator settings;
- player-facing seed input;
- art pass for generated layouts.

## Implementation Notes

Implemented in:

```text
scripts/presentation/dungeon_debug.gd
```
