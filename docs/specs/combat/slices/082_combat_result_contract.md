# 082 Combat Result Contract

Status: implemented
Date: 2026-07-15

## Acceptance

This slice proves the combat-produced result payload that dungeon exploration will consume. The owning combat rules live in:

```text
docs/specs/combat/overview/082_combat_result_contract_v1.md
```

Related dungeon boundary:

```text
docs/specs/dungeon/overview/001_dungeon_combat_boundary.md
```

- a combat encounter may carry `source_dungeon_id`, `source_room_id`, and reward-shaped data;
- after victory, `simulate()` returns `result_payload.result == "victory"`;
- the terminal `combat_ended` event includes the same `result_payload`;
- the payload includes `combat_id`, `source_dungeon_id`, `source_room_id`, surviving player summaries, defeated enemy ids, remaining enemy summaries, and rewards;
- victory payload includes surviving players and defeated enemies;
- defeat payload includes defeated player ids and remaining enemy summaries;
- reward data is copied as data and not applied to inventory/XP systems yet;
- replaying the same commands returns the same payload and event log.

## Non-Goals

- dungeon room clearing;
- reward application;
- inventory, XP, or loot generation;
- scene transition code.
