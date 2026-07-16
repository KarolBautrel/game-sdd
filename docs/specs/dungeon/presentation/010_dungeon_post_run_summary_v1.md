# 010 Dungeon Post-Run Summary V1

Status: active
Date: 2026-07-16

## Intent

Show a first post-run summary after the player finishes the authored dungeon.

This stays inside `DungeonDebug.tscn` for now. It is a summary panel state, not a separate post-run scene.

## Rules

- After dungeon completion, the HUD shows a summary of:
  - completion room;
  - visited rooms;
  - secured rooms;
  - claimed gold;
  - claimed XP;
  - claimed items.
- The summary uses dungeon run state only.
- `Finish Expedition` is hidden after completion.
- Exit navigation may remain visible until a real world-map return flow exists.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/010_dungeon_post_run_summary_v1.md
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- separate post-run scene;
- world-map return;
- persistent save data.
