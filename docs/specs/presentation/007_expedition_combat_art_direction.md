# Dark fantasy expedition and battle interfaces

Authorized2026-11-02 after the user explicitly approved the stage26 campaign
appearance and requested the same treatment for dungeon exploration and combat.
Extend the approved presentation006 family; campaign visuals are the selected
target. User praise records visual approval of campaign appearance, not unplayed
combat/save acceptance. Gameplay ownership stays in dungeon/combat/domain specs.

## Visual and interaction rules

- Shared aged brass, charcoal leather, quiet parchment and packaged Cinzel/Source
  Sans3 typography. Native text, values, focus and buttons remain interactive.
- Dungeon: the connected room map dominates; readable room silhouettes, names,
  current/visited/threat/reward states, genuine corridors and scroll reachability.
  A parchment room inspector shows actual room information and guarded actions.
  Preparation has readable supply controls, packing budget, source/difficulty and
  a prominent Start. Company portraits, health, supplies/light and feedback stay
  separate from the map and inspector. Event choices must fit and block background
  room actions while pending; full content must remain accessible by scrolling.
- Combat: maximize readable unobscured board area, with shared dark frame and
  leather surroundings. Encounter/turn summary, active-unit portrait/HP/AP/MP,
  action names/icons/shortcuts, parchment action/target inspector, recent actions,
  disabled/selected/hover/focus and result/return must be legible at1080p.
  Resources and combat log belong outside playable tile hit areas. Debug/scenario
  tools stay available in a separate compact developer section.
  Reserve headroom for actors on the first board row and clip the board viewport
  so tall sprites never cover the header or action tray. Reloading an encounter
  must recreate every visual after deferred deletion; UI reset cannot hide actors.
- Preserve resolver commands, legality, costs, damage, animation timing, input
  transforms, save/run checkpoints, gear/progression and all service/travel rules.
  Do not change terrain/unit art or simulation to hide UI problems.
- Target1920x1080,2560x1440 and4K with a readable1280x720 fallback. Use responsive
  native layout, bounded text and scroll where needed. No hidden actionable rows
  with no route to reach them. Retain developer layout/encounter tools explicitly;
  legacy manually positioned dungeon defaults must not override the new default
  composition unless the developer explicitly enters layout editing.

## Workflow and proof

Stages27 dungeon,28 battle,29 integrated release. Each needs spec/slice, affected
tests and actual native GPU review before the next increment. Reuse approved
materials and licensed glyph family; any new final pixel assets go through Aseprite
with source/export/provenance. No additional style reset or installation is needed.

The user's background/deferred-live policy continues: minimized no_focus native
fixtures, engine-local input, isolated in-memory saves; no OS input or activation.
Accumulated physical keyboard/hover/gameplay remains AWAITING_INTERACTIVE until
control release. Proof owner slices/007_expedition_combat_art_direction.md.
