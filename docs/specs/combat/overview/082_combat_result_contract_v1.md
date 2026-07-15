# 082 Combat Result Contract V1

Status: implemented
Date: 2026-07-15

## Intent

Define the result payload tactical combat exposes when combat ends.

This is the first data bridge from tactical combat back to dungeon exploration. Combat remains responsible for determining combat result and summarizing combat state. Dungeon exploration remains responsible for room clearing, reward application, quest state, and navigation.

Related dungeon boundary:

```text
docs/specs/dungeon/overview/001_dungeon_combat_boundary.md
```

## Rules

- Combat must expose a queryable result payload after combat has ended.
- While combat is still in progress, the queryable result payload reports `result: in_progress` and empty terminal summaries.
- The result payload must be deterministic for the same encounter, seed, and command sequence.
- The result payload must not require dungeon code to inspect raw combat internals to know whether the battle was won or lost.
- Commands after combat end remain rejected by existing combat rules.
- The first result payload should include:
  - `result`: `victory` or `defeat`;
  - `combat_id`;
  - optional `source_dungeon_id` when the encounter was launched by dungeon mode;
  - optional `source_room_id` when the encounter was launched by dungeon mode;
  - surviving player unit summaries;
  - defeated enemy unit ids;
  - remaining enemy summaries, if any;
  - reward-shaped data, if the encounter defines it.
- Combat encounters may define optional boundary metadata:
  - `source_dungeon_id`;
  - `source_room_id`;
  - `rewards`.
- Unit summaries should include at least:
  - unit id;
  - team;
  - hp;
  - max hp;
  - statuses;
  - position only if useful for debug.
- Reward-shaped data may be a stub until inventory/progression exists, but it should be shaped as data:
  - XP amount;
  - gold amount;
  - item ids.
- The result payload should be available from both:
  - the returned `simulate()` result;
  - the terminal `combat_ended.result_payload` event.

## Non-Goals

- dungeon room clearing implementation;
- inventory application;
- XP leveling;
- loot generation;
- campaign defeat consequences;
- scene transition code.

## Acceptance Path

To implement this spec, add:

```text
docs/specs/combat/slices/082_combat_result_contract.md
```

The slice proves victory and defeat payloads in Python and Godot combat slice tests.
