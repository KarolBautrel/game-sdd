# 001 Dungeon Data Contract V1

Status: implemented
Date: 2026-07-15

## Acceptance

This slice proves the first authored dungeon graph data contract. The owning rules live in:

```text
docs/specs/dungeon/overview/002_dungeon_data_contract_v1.md
```

- `resources/schemas/dungeon.schema.json` validates dungeon graph data;
- `resources/data/dungeons/dungeon_old_mine.json` defines start room, rooms, corridors, content entries, combat encounter references, and rewards;
- every corridor references existing rooms;
- `start_room_id` references an existing room;
- every combat content entry references an existing combat encounter JSON;
- every guarded treasure entry includes reward-shaped data;
- validation is covered by `python tools/validators/validate_all.py`.
