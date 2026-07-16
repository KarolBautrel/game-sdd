# 008 Dungeon Exit Navigation V1

Status: active
Date: 2026-07-16

## Intent

Make dungeon exploration usable without clicking directly on the abstract graph.

The current graph remains visible, but the player-facing HUD should expose connected exits as explicit commands and support number-key shortcuts for fast traversal.

## Rules

- `DungeonDebug.tscn` remains the temporary playable dungeon scene.
- The HUD shows one exit command per connected room.
- Exit command labels include a stable slot number and the target room display name.
- Pressing an exit command calls the same dungeon state model movement path as graph clicks.
- Number keys `1` through `9` trigger matching visible exit commands.
- Movement rejection feedback remains player-facing.
- Pending combat still takes priority: combat entry remains the primary action when the current room has a pending combat request.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/007_dungeon_exit_navigation_v1.md
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- path preview animation;
- controller focus polish;
- replacing the room graph with a tile map.
