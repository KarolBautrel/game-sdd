# 021 Dungeon Reusable Event Catalogue V1

Status: implemented
Date: 2026-07-16

## Intent

Move corridor hazards toward reusable event templates.

Dungeon events should not be authored only as inline data inside one dungeon. Future procedural dungeons need to select hazards from a catalogue, instantiate them on generated corridors, and keep the same choice/outcome/consequence contract used by authored dungeons.

## Catalogue Contract

Reusable corridor hazards live under:

```text
resources/data/dungeon_events/
```

A catalogue file contains:

```json
{
  "id": "base_corridor_hazards",
  "events": [
    {
      "id": "rubble_minor",
      "type": "rubble",
      "required_supply_id": "pickaxe",
      "choices": [],
      "outcomes": []
    }
  ]
}
```

Each event template owns:

- event id;
- hazard type;
- player-facing message;
- required supply;
- available choices;
- weighted outcomes;
- structured consequences.

## Dungeon Reference Contract

Authored or generated corridors may use:

```json
{
  "hazard_refs": [
    {
      "id": "rubble_crossing_cache",
      "event_id": "rubble_minor",
      "trigger": { "mode": "first_traversal" }
    }
  ]
}
```

`id` is the run-instance id used by state tracking. `event_id` points to a reusable event template. `trigger` remains per-corridor so the same template can be used as first-traversal, always-on, or future generated variants.

Inline `hazards` remain supported for debug or one-off authored exceptions. Exact authored placement can use `hazard_refs`. Generated corridors should prefer `hazard_pool_refs` from `022_dungeon_event_pools_v1.md`.

## Implementation Notes

Implemented first-pass support in:

```text
resources/schemas/dungeon_event.schema.json
resources/data/dungeon_events/base_corridor_hazards.json
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
tools/validators/validate_all.py
```

`Old Mine` now references reusable `rubble_minor` and `needle_trap_basic` templates.

## Future Work

- Add event pools with weights for procedural corridor generation.
- Add room-event templates for shrine, chest, clue, locked object, and camp events.
- Add biome/dungeon tags so generators can select hazards by theme.
- Add generated/static event art references to templates.

## Non-Goals

- procedural dungeon graph generation;
- final event balance;
- final event art;
- room event catalogue.
