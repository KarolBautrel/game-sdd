# 013 Dungeon Presentation Vertical Slice V1

Status: implemented
Date: 2026-07-16

## Intent

Move the dungeon debug scene toward a playable dungeon screen while preserving the current mechanics and data flow.

This slice is still pre-production presentation. It should make the dungeon easier to read and test before final art, generated event illustrations, or a full layout replacement.

## Rules

- Keep `DungeonDebug.tscn` as the playable dungeon scene.
- Preserve existing dungeon state, supply loadout, corridor hazards, party targeting, and combat bridge behavior.
- Add a stronger map frame so the authored room graph reads as the primary exploration surface.
- Add a resource tray that shows light, oil, pickaxe, trap tools, and active effects as distinct scan targets.
- Add a compact map legend for room markers and path danger.
- Add corridor hazard markers for authored hazards such as rubble and traps.
- Add a current route/state line that tells the player whether they are preparing, resolving an event, or exploring from the current room.
- Keep the route map, resource tray, legend, and detail panel in stable non-overlapping screen regions at the current debug resolution.
- Layout regions should be derived from the viewport size, and authored room positions should be fit into the available map rectangle rather than relying on fixed graph coordinates.
- Use Godot theme/stylebox helpers for the first fantasy UI pass: dark parchment/stone panels, restrained gold borders, compact rooms, and readable labels.
- Do not introduce final art dependencies in this slice.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/024_dungeon_presentation_vertical_slice_v1.md
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- final dungeon artwork;
- generated bitmap event images;
- tile-map exploration;
- fog of war;
- controller navigation;
- production inventory/character UI.
