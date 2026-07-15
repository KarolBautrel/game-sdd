# 002 Dungeon Data Contract V1

Status: implemented
Date: 2026-07-15

## Intent

Define the authored data contract for the first dungeon exploration maps.

Dungeon data is a graph of room checkpoints connected by corridors. Rooms own authored content such as treasure, combat, guarded treasure, or quest hooks. The first implementation is authored data only, not procedural generation.

## Rules

- A dungeon defines:
  - `id`;
  - `display_name`;
  - `recommended_party_level`;
  - `start_room_id`;
  - `rooms`;
  - `corridors`;
  - `exit_rules`.
- A room defines:
  - `id`;
  - `display_name`;
  - `kind`;
  - a 2D `position` used by the abstract debug view;
  - one or more `content` entries.
- Corridors connect two existing room ids.
- The first room kinds are:
  - `entrance`;
  - `empty`;
  - `treasure`;
  - `combat`;
  - `guarded_treasure`;
  - `quest`;
  - `exit`.
- The first content types are:
  - `empty`;
  - `treasure`;
  - `combat`;
  - `guarded_treasure`;
  - `quest`.
- Combat content references an existing combat encounter resource path.
- Treasure and guarded treasure content may define reward-shaped data:
  - `xp`;
  - `gold`;
  - `items`.
- Dungeon data does not apply rewards, clear rooms, or launch combat by itself.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/001_dungeon_data_contract_v1.md
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
```

## Non-Goals

- procedural generation;
- inventory application;
- puzzle/trap behavior;
- scene transition code;
- final dungeon art direction.
