# Combat Encounter Board Structure

This document defines how tactical combat boards should be authored for dungeon encounters.

## Core Rule

A combat board must look like a place that a thinking level designer built. Terrain, blockers, cover, highground, props, and spawn positions should explain the same fictional space and support the same tactical idea.

## Floor And Visual Cohesion

- Use one coherent base floor per board.
- Avoid checkerboard noise: do not mix visually unrelated floor families tile by tile.
- Floor variation should read as wear, cracks, dirt, or mine detail, not as separate rooms pasted together.
- A board can have zones, but the transition between zones should be deliberate: tunnel to gallery, gallery to ledge, ledge to vault, and so on.

## Blocked Terrain

- `blocked` means the tile cannot be crossed and should look impossible or unreasonable to cross.
- Use believable large blockers: cave wall, collapsed shaft, large boulders, heavy timber, mine cart pile, thick column, machinery, or sealed structural debris.
- Do not use tiny stones, small props, loose tools, small busts, candles, or decorative clutter as hard blockers.
- Blockers should usually form readable shapes: wall chunks, pillars, collapsed bands, side boundaries, or tactical chokepoints.
- Single isolated blockers are allowed only when the asset clearly reads as large enough.

## Cover

- `cover_low` should be visibly usable as cover.
- Good cover: carts, crates, barricades, waist-high rubble, timber stacks, broken machinery, low stone formations.
- Cover should shape decisions without making the board unreadable.
- Cover should not be visually confused with floor clutter.

## Highground

- `highground` should be a coherent raised feature, not a single random stripe.
- Good highground: stone ledge, raised walkway, scaffold, platform, ramped shelf, collapsed upper tunnel, or mining deck.
- A highground area should usually be at least two connected tiles.
- Highground should have a visible visual cue: ledge rim, shadow/drop edge, platform asset, or repeated raised-ground decoration.
- If the current art does not fully sell elevation, use layout and renderer cues to make the raised area unmistakable.

## Tactical Shape

- Every board should have a tactical idea:
  - choke and flank;
  - ranged perch versus cover approach;
  - broken central blocker with side lanes;
  - vault room with pillars;
  - narrow gallery opening into a wider chamber.
- Player and enemy spawns should support that idea.
- Ranged units should have plausible sightlines, not perfect full-board dominance unless that is the point of the encounter.
- Melee units need routes that are clear enough to avoid pathing nonsense.

## Worldbuilding

- The board should match the room concept:
  - spider nest: webs, side pockets, cramped approach;
  - mine gallery: rails, columns, rubble, carts;
  - vault: columns, sealed corners, treasure-side defensive cover;
  - sump: lower floor feel, debris, constrained movement;
  - guardroom: clear defended approach and believable barricades.
- Props should cluster where a human or dungeon ecology would put them.
- Avoid placing ornate or symbolic props in tactically critical locations unless the room fiction explains it.

## Current Old Mine Rules

- Prefer dungeon stone backgrounds.
- Use columns, rubble, large dungeon stone pieces, and heavy mine debris for blockers.
- Use rubble/timber/cart-like assets for cover.
- Use connected highground shelves with strong visual renderer cues until dedicated highground assets exist.
- Do not use statues/busts as default blockers for generated Old Mine combat boards.
