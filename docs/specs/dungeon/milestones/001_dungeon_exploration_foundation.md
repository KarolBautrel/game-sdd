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
- Combat now exposes the stable result payload dungeon needs to consume after a battle.

## Owning Specs

```text
docs/specs/dungeon/overview/000_dungeon_exploration_loop.md
docs/specs/dungeon/overview/001_dungeon_combat_boundary.md
docs/specs/dungeon/overview/002_dungeon_data_contract_v1.md
docs/specs/dungeon/presentation/003_dungeon_debug_view_v1.md
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

4. **Next - Dungeon State Model V1**
   - Goal: create a small deterministic model for current room, visited rooms, cleared rooms, and pending combat request.
   - Expected behavior:
     - enter adjacent room;
     - reject non-adjacent movement;
     - expose room content;
     - mark combat room pending when enemies are present.
   - Proof: Python or Godot unit/domain test.

5. **Dungeon Combat Transition V1**
   - Goal: prove dungeon can launch a combat request and consume a combat result payload.
   - Expected behavior:
     - combat room creates an encounter request;
     - victory clears the room;
     - guarded reward becomes available;
     - defeat does not clear the room.
   - Proof: executable dungeon slice or equivalent domain test.

6. **Dungeon Exploration Scene V1**
   - Goal: build the first usable dungeon exploration scene.
   - Expected behavior:
     - render room/corridor graph;
     - move between connected rooms;
     - show current room content state;
     - transition into combat scene for combat rooms;
     - return after combat result.
   - Proof: Godot headless load plus documented manual UI verification gap until a scene automation harness exists.

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
```

Dungeon domain tests will be added with Dungeon State Model V1.
