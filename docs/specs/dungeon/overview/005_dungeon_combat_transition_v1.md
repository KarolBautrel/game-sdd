# 005 Dungeon Combat Transition V1

Status: active
Date: 2026-07-15

## Intent

Prove the first deterministic data transition between dungeon exploration state and tactical combat result payloads.

This step still does not launch the combat scene. It prepares the request data a scene transition will use later and consumes the already-defined combat result payload after a battle.

## Rules

- Entering an unresolved combat or guarded treasure room creates `pending_combat_request`.
- A pending combat request stores:
  - `dungeon_id`;
  - `room_id`;
  - `content_type`;
  - `combat_encounter_path`.
- Applying a combat payload is legal only when it matches the pending dungeon id and room id.
- Applying a `victory` payload:
  - clears `pending_combat_request`;
  - marks the combat room cleared;
  - unlocks guarded rewards when the room content is `guarded_treasure`;
  - stores the payload as `last_combat_result`.
- Applying a `defeat` payload:
  - clears `pending_combat_request`;
  - does not clear the room;
  - does not unlock guarded rewards;
  - stores the payload as `last_combat_result`.
- Applying an `in_progress` payload is rejected.
- Applying a payload with no matching pending combat request is rejected.
- Reward data is only unlocked/queued by room id. Inventory, XP, and gold mutation remain out of scope.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/004_dungeon_combat_transition_v1.md
scripts/domain/dungeon_state_model.gd
scripts/domain/dungeon_state_model_tests.gd
```

## Non-Goals

- loading or unloading combat scenes;
- applying rewards to inventory/progression;
- defeat campaign consequences;
- final dungeon UI.
