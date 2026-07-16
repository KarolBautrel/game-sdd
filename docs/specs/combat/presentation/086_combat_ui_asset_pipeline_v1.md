# Combat UI Asset Pipeline V1

Status: active

## Intent

Combat presentation now moves toward a game-facing 2.5D tactical view. The battle board must read as an oblique/top-down tactical field, not a diamond/isometric projection.

The provided mercenary character sheets are source-scale references for the next combat redesign. Their apparent scale defines the first target relationship between units and board tiles.

## Rules

- Source sheets for hero mercenaries live under `assets/combat/characters/heroes/mercenaries/`.
- Source sheets for combat NPCs live under `assets/combat/characters/npc/`.
- Source sheets for bandit villains live under `assets/combat/characters/villains/bandits/`.
- Processed in-game sprites live in a sibling `processed/` folder for each source group.
- Processed sprites must have transparent backgrounds, stable names, and deterministic mirrored variants.
- The source direction is treated as `right`; generated mirror sprites are treated as `left`.
- Combat art lookup must not flip sprites at runtime when a matching processed left/right asset exists.
- Initial board scale for the combat debug scene is a 2.5D tactical scale:
  - rectangular/square grid cells remain screen-aligned for now;
  - no diamond/isometric board transform;
  - units are allowed to be taller than one tile, anchored by their feet near the tile bottom;
  - tile size and unit icon bounds are tuned from the processed mercenary sprites, not from the previous placeholder art.
- Combat debug V1 uses 2.5D rectangular movement cells of `140x104` pixels and `UNIT_ICON_SIZE = 208x208` so processed character sprites keep readable scale while the ground footprint is wider than the old square debug tile.
- Unit sprites are anchored by their feet to the bottom of the movement cell; the tile must read as ground under the character, not as a square floating over or around the character torso.
- Unit HP/AP/MP labels sit above the sprite body whenever there is screen space, so they do not cover the character head at the new 2.5D scale.
- Movement presentation must cycle through available `walk` frames during tile movement; a unit must not slide across the board on one frozen walk pose.
- Combat presentation must cycle through available `combat`, `hit`, and `death` frames during attack, damage, and defeat beats; these states must not be represented by one frozen sprite frame.
- After movement ends, a unit faces the nearest living opponent again instead of staying locked to the direction it just walked.
- Debug showcase loadouts should match the visible model: archer visuals use bow/ranged profiles, while melee bandits use melee weapon profiles that match their source art.
- Enemy visual fallback must prefer `archetype_id` over generated unit ids so randomized dungeon enemies do not swap ranged/melee appearances.
- Enemy archetype `visual_pool` is the preferred source of compatible visuals; hardcoded archetype presentation fallbacks are only a safety net for older data.
- A defeated unit plays through available death frames, then remains on the board as a corpse visual. The corpse is presentation-only and must not block movement.
- Static representative frames may be used until the full animation playback pass; all extracted frames still need to be saved for later animation.
- Missing processed mercenary assets fall back through the existing deterministic unit art path rather than crashing combat.

## Processed Character Contract

Each processed character folder should include:

- `manifest.json` with source path, detected frames, action assignment, and generated output names;
- action folders or stable action-prefixed PNGs for at least `pose`, `walk`, `combat`, `hit`, and `death`;
- left and right variants for every exported frame.

The first implementation may infer action rows from the current sheet layout:

- row 1: `pose`;
- row 2: `walk`;
- row 3: `combat`;
- row 4: `hit`;
- row 5: `death`.

If future source sheets include explicit metadata, metadata should override row inference.

## Acceptance

- Provided archer, rogue, guardian, warrior, NPC, and bandit sheets can be processed without manual image editing.
- Processed sprites have transparent backgrounds instead of green source backgrounds.
- Left/right sprite variants are generated.
- Combat debug can load processed warrior and bandit sprites through `CombatUnitArt`.
- Combat debug remains a 2.5D tactical board, not an isometric board.
- Movement animation shows changing walk frames while the unit crosses each path step.
- Attack, hit, and death animations show changing processed frames while the combat beat resolves.
- Units stand on the bottom of their 2.5D movement cell and face a living opponent after movement.
- Randomized/generated enemy visuals match `archetype_id` roles, not numeric unit id ordering.
- Randomized/generated enemy visuals use role-compatible archetype visual pools when available.
- Defeated units remain visible as non-blocking corpse sprites after death animation.

## Proof

- Slice: `docs/specs/combat/slices/086_combat_ui_asset_pipeline_v1.md`
- Test: `scripts/presentation/combat_mercenary_asset_pipeline_tests.gd`
- Validation:
  - `python tools\validators\validate_all.py`
  - Godot headless combat scene load
  - manual visual review of processed sprites and combat debug scale
