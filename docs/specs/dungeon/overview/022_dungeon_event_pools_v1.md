# 022 Dungeon Event Pools V1

Status: implemented
Date: 2026-07-16

## Intent

Add reusable weighted event pools on top of the dungeon event catalogue.

Future procedural dungeon generation should not hard-code exact event ids on every generated corridor. It should be able to pick from themed pools such as mine rubble, mine traps, darkness hazards, or later crypt/forest/ruin hazards.

## Pool Contract

Event pools live under:

```text
resources/data/dungeon_event_pools/
```

A pool catalogue contains:

```json
{
  "id": "old_mine_event_pools",
  "pools": [
    {
      "id": "old_mine_rubble_pool",
      "tags": ["mine", "corridor", "rubble"],
      "danger_min": 0.0,
      "danger_max": 0.19,
      "entries": [
        { "event_id": "rubble_minor", "weight": 100 }
      ]
    }
  ]
}
```

Pool entries point at reusable event template ids. Selection is deterministic from dungeon run seed, corridor id, and pool ref id so debug runs remain reproducible.

## Dungeon Reference Contract

Corridors may use:

```json
{
  "hazard_pool_refs": [
    {
      "id": "rubble_crossing_cache",
      "pool_id": "old_mine_rubble_pool",
      "trigger": { "mode": "first_traversal" }
    }
  ]
}
```

`id` is the runtime hazard instance id. `pool_id` selects a weighted pool. `trigger` remains authored/generated per corridor.

Direct `hazard_refs` still exist for exact authored placement. `hazard_pool_refs` are the preferred path for generated corridors.

Pools may also define optional `danger_min` and `danger_max` values. Procedural corridor planning uses those values as coarse selection bands when choosing a pool for generated corridor data.

## Implementation Notes

Implemented first-pass support in:

```text
resources/schemas/dungeon_event_pool.schema.json
resources/data/dungeon_event_pools/base_old_mine_pools.json
resources/schemas/dungeon.schema.json
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
tools/validators/validate_all.py
```

`Old Mine` now proves both catalogue templates and pool-based materialization through deterministic single-entry pools.

## Future Work

- Add multi-entry pools once more hazards exist.
- Add generator rules that choose pools by biome, room depth, and supply pressure.
- Add minimum/maximum depth constraints.

## Non-Goals

- procedural graph generation;
- final event weighting;
- multi-event corridor generation;
- runtime random non-determinism.
