# 004 Dungeon State Model V1

Status: active
Date: 2026-07-15

## Intent

Create the first deterministic state model for dungeon exploration.

The model owns where the party is inside an authored dungeon graph, which rooms have been visited, which simple rooms are cleared, and whether the current room is requesting tactical combat.

## Rules

- A dungeon run state stores:
  - `dungeon_id`;
  - `current_room_id`;
  - `visited_room_ids`;
  - `cleared_room_ids`;
  - `pending_combat_request`.
- Initial state starts in the dungeon `start_room_id`.
- The start room is marked visited.
- Empty rooms are cleared automatically when entered.
- Moving to a room is legal only when a corridor connects the current room and the target room.
- Moving to a missing room is rejected.
- Moving to a non-adjacent room is rejected.
- Entering a legal room updates `current_room_id` and adds the room to `visited_room_ids`.
- Entering a combat or guarded treasure room with unresolved combat content sets `pending_combat_request`.
- A pending combat request includes:
  - `dungeon_id`;
  - `room_id`;
  - `content_type`;
  - `combat_encounter_path`.
- Treasure rooms expose their content but are not auto-looted or cleared by this model yet.
- The model does not launch scenes, resolve combat, apply rewards, or mutate inventory.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/003_dungeon_state_model_v1.md
scripts/domain/dungeon_state_model.gd
scripts/domain/dungeon_state_model_tests.gd
```

## Non-Goals

- scene transitions;
- applying combat result payloads;
- reward claiming;
- inventory, XP, or quest state;
- procedural dungeon generation.
