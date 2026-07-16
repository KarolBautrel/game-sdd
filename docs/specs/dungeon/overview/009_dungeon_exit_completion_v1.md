# 009 Dungeon Exit Completion V1

Status: active
Date: 2026-07-16

## Intent

Add a first explicit completion action for authored dungeon exit rooms.

This gives the current dungeon loop a visible endpoint while campaign/world-map integration is still absent.

## Rules

- Dungeon state tracks `completed`.
- Dungeon state tracks `completed_at_room_id`.
- The completion action is accepted only in a room whose `kind` is `exit`.
- Completion is rejected while combat is pending.
- Completion is idempotent: once completed, repeating the action keeps the run completed and returns an accepted completion event.
- The dungeon HUD exposes a `Finish Expedition` command in exit rooms when no combat is pending.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/009_dungeon_exit_completion_v1.md
scripts/domain/dungeon_state_model.gd
scripts/domain/dungeon_state_model_tests.gd
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- world-map transition;
- campaign rewards;
- retreat consequences;
- post-run summary screen.
