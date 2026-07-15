# 006 Dungeon Exploration Scene V1

Status: active
Date: 2026-07-15

## Intent

Make the first usable dungeon exploration scene flow: move through authored rooms, start combat from a pending combat room, and return to dungeon after combat resolves.

This is still a debug-facing vertical slice. It proves scene handoff and state persistence, not final dungeon UI.

## Rules

- `DungeonDebug.tscn` owns the visible dungeon exploration debug flow.
- The dungeon scene uses `DungeonStateModel` for movement, room state, and combat result application.
- A pending combat room exposes a `Start Combat` command.
- Dungeon room combat content must reference a presentation-ready combat encounter, not a low-level regression slice.
- Dungeon-launched combat encounters must use the same board presentation paradigm as authored showcases:
  - a generated `background_path`;
  - a board large enough for the combat HUD, currently at least 10x8;
  - authored terrain data for blocked, cover, highground, and floor tiles;
  - no `slice_*` encounter ids or paths.
- Starting combat stores the current dungeon run state and pending combat request in a session object.
- Starting combat changes to `CombatDebug.tscn`.
- Combat launched from dungeon loads the encounter path from the pending combat request.
- Combat launched from dungeon stamps the loaded encounter with source dungeon id and source room id before combat starts.
- Combat launched from dungeon may use an authored board preset while randomizing enemy composition.
- Current enemy composition rule:
  - keep player units from the encounter preset;
  - replace preset enemy units;
  - spawn 2-3 enemies;
  - choose enemies from the current dungeon archetype pool;
  - place enemies on legal non-blocked tiles in the enemy-side region of the authored board.
- After combat ends, `CombatDebug.tscn` exposes `Return to Dungeon`.
- Returning to dungeon applies the combat result payload to the stored dungeon run state.
- Victory clears the room; guarded treasure victory unlocks its reward marker.
- Defeat returns to the dungeon without clearing the room.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/005_dungeon_exploration_scene_v1.md
scripts/session/dungeon_run_session.gd
scenes/dungeon/DungeonDebug.tscn
scripts/presentation/dungeon_debug.gd
scenes/combat/CombatDebug.tscn
scripts/presentation/combat_debug.gd
```

## Non-Goals

- final dungeon art;
- loading screens;
- inventory or XP application;
- campaign defeat consequences;
- replacing the combat debug UI with a production combat UI.
