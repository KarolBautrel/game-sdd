# 001 Dungeon Combat Boundary

Status: planned
Date: 2026-07-15

## Intent

Define the data boundary between dungeon exploration and tactical combat.

Dungeon exploration owns navigation, room state, encounter triggers, and reward application. Tactical combat owns combat command resolution, combat events, victory/defeat, and surviving combat unit state.

## Transition To Combat

When a room triggers combat, dungeon mode creates a combat request with:

- source dungeon id;
- source room id;
- combat encounter id or encounter resource path;
- optional encounter seed;
- optional battle theme or map override;
- party/unit state needed to spawn player units;
- reward payload to unlock after victory, if the room is guarded.

The combat scene loads the requested encounter and resolves battle using combat rules.

## Return From Combat

When combat ends, combat returns a result payload to dungeon mode with:

- `result`: `victory` or `defeat`;
- `combat_id`;
- source dungeon id, when provided;
- source room id, when provided;
- surviving player unit summaries;
- defeated enemy unit ids;
- remaining enemy unit summaries, if combat ends without victory;
- deterministic event log tail or reference, if needed for debug;
- reward-shaped payload copied or resolved for dungeon application.

## Dungeon Response

On `victory`:

- mark the room encounter as resolved;
- mark guarded treasure as unlocked;
- apply or queue rewards;
- return the party to the dungeon room;
- allow further movement.

On `defeat`:

- stop normal dungeon exploration;
- route to the future defeat/retreat/campaign consequence flow;
- do not mark the room as cleared.

## Ownership Rules

- Combat result payload shape is specified in combat because combat produces it.
- Dungeon consumes the result payload and updates dungeon state.
- Dungeon must not infer victory/defeat by inspecting enemy HP directly when a combat result field exists.
- Combat must not mark dungeon rooms as cleared directly.

## Acceptance Path

The next combat milestone item should define and validate the combat-produced result payload:

```text
docs/specs/combat/overview/082_combat_result_contract_v1.md
docs/specs/combat/slices/082_combat_result_contract.md
```

Dungeon executable slices should start after there is a minimal dungeon state model or scene harness.
