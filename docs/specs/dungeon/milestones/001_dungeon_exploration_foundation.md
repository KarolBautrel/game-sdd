# Milestone 001: Dungeon Exploration Foundation

Status: active
Date: 2026-07-15

## Summary

Dungeon exploration is the planned gameplay phase that connects authored rooms, corridor traversal, room content, combat transitions, and post-combat rewards.

The target feel is an abstract dungeon-crawler exploration layer: the party moves through corridors between room checkpoints, resolves authored room content, and switches into tactical combat when a room contains enemies.

## Current State

- Dungeon specs exist.
- Dungeon data contract v1 is implemented.
- `dungeon_old_mine` is authored as a small room/corridor graph.
- `DungeonDebug.tscn` renders the authored dungeon as an abstract graph.
- Dungeon state model v1 tracks current room, visited rooms, cleared empty rooms, and pending combat requests.
- Dungeon combat transition v1 consumes combat result payloads, clears victorious combat rooms, and unlocks guarded rewards.
- Dungeon exploration scene v1 can start combat from a pending dungeon room and return after combat result.
- Combat now exposes the stable result payload dungeon needs to consume after a battle.

## Owning Specs

```text
docs/specs/dungeon/overview/000_dungeon_exploration_loop.md
docs/specs/dungeon/overview/001_dungeon_combat_boundary.md
docs/specs/dungeon/overview/002_dungeon_data_contract_v1.md
docs/specs/dungeon/presentation/003_dungeon_debug_view_v1.md
docs/specs/dungeon/overview/004_dungeon_state_model_v1.md
docs/specs/dungeon/overview/005_dungeon_combat_transition_v1.md
docs/specs/dungeon/presentation/006_dungeon_exploration_scene_v1.md
```

Related combat owner:

```text
docs/specs/combat/overview/082_combat_result_contract_v1.md
```

## Ordered Dungeon Queue

1. **Done - Combat Result Contract V1**
   - Owner spec: `docs/specs/combat/overview/082_combat_result_contract_v1.md`
   - Slice: `docs/specs/combat/slices/082_combat_result_contract.md`
   - Goal: combat can return victory/defeat, surviving player summaries, defeated enemy ids, and reward-shaped data.
   - Proof: Python and Godot combat slice tests.

2. **Done - Dungeon Data Contract V1**
   - Goal: define authored dungeon graph data.
   - Expected data:
     - dungeon id;
     - rooms;
     - corridors;
     - start room;
     - room content entries;
     - combat encounter references;
     - reward payloads.
   - Expected files:
     - `resources/schemas/dungeon_run.schema.json` or similar;
     - one minimal reference dungeon in `resources/data/dungeons/`.
   - Proof: schema validation through `python tools/validators/validate_all.py`.

3. **Done - Dungeon Debug View V1**
   - Goal: make the first visible dungeon exploration screen.
   - Owner spec: `docs/specs/dungeon/presentation/003_dungeon_debug_view_v1.md`
   - Slice: `docs/specs/dungeon/slices/002_dungeon_debug_view_v1.md`
   - Implementation:
     - `scenes/dungeon/DungeonDebug.tscn`
     - `scripts/presentation/dungeon_debug.gd`
   - Proof: Godot headless project load plus manual UI verification gap.

4. **Done - Dungeon State Model V1**
   - Goal: create a small deterministic model for current room, visited rooms, cleared rooms, and pending combat request.
   - Owner spec: `docs/specs/dungeon/overview/004_dungeon_state_model_v1.md`
   - Slice: `docs/specs/dungeon/slices/003_dungeon_state_model_v1.md`
   - Expected behavior:
     - enter adjacent room;
     - reject non-adjacent movement;
     - expose room content;
     - mark combat room pending when enemies are present.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`.

5. **Done - Dungeon Combat Transition V1**
   - Goal: prove dungeon can launch a combat request and consume a combat result payload.
   - Owner spec: `docs/specs/dungeon/overview/005_dungeon_combat_transition_v1.md`
   - Slice: `docs/specs/dungeon/slices/004_dungeon_combat_transition_v1.md`
   - Expected behavior:
     - combat room creates an encounter request;
     - victory clears the room;
     - guarded reward becomes available;
     - defeat does not clear the room.
   - Proof: `scripts/domain/dungeon_state_model_tests.gd`.

6. **Done - Dungeon Exploration Scene V1**
   - Goal: build the first usable dungeon exploration scene.
   - Owner spec: `docs/specs/dungeon/presentation/006_dungeon_exploration_scene_v1.md`
   - Slice: `docs/specs/dungeon/slices/005_dungeon_exploration_scene_v1.md`
   - Expected behavior:
     - render room/corridor graph;
     - move between connected rooms;
     - show current room content state;
     - transition into combat scene for combat rooms;
     - return after combat result.
   - Proof: Godot headless load, dungeon state tests, session bridge tests, and manual UI verification gap for click-through.

## First Implementation Guidance

- Keep the first dungeon map small: start room, one empty room, one treasure room, and one combat room.
- Use authored data before procedural generation.
- Do not implement puzzles, traps, camping, hunger, or inventory UI in this milestone.
- Keep combat boards data-driven through existing combat encounter files.
- Reward payloads may be data-shaped stubs until inventory/progression systems are ready.

## Validation

Current validation:

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
```

Next dungeon work should focus on replacing debug controls with a cleaner production-facing exploration UI and applying rewards to progression/inventory once those systems exist.
