# 023 Dungeon Procedural Corridor Plan V1

Status: implemented
Date: 2026-07-16

## Intent

Add a small procedural planning layer for generated corridors.

Future dungeon generation should create corridor data from reusable rules instead of hand-authoring every rubble pile, trap, or supply check. This first version does not generate the room graph. It only answers: given a corridor theme and danger value, which reusable hazard pool should this corridor reference?

## Contract

A procedural corridor plan returns data shaped like authored corridor data:

```json
{
  "corridor_id": "generated_corridor_01",
  "hazard_pool_refs": [
    {
      "id": "generated_corridor_01_generated_hazard",
      "pool_id": "old_mine_trap_pool",
      "trigger": { "mode": "first_traversal" }
    }
  ]
}
```

The returned `hazard_pool_refs` must use the same runtime contract as authored corridors, so generated and hand-authored corridors go through the same event materialization, prompt, consequence, and validator logic.

## Pool Selection Rules

Event pools may define optional danger bands:

```json
{
  "id": "old_mine_trap_pool",
  "tags": ["mine", "corridor", "trap"],
  "danger_min": 0.2,
  "danger_max": 1.0,
  "entries": []
}
```

Selection rules:

- all requested profile tags must exist in the pool tags;
- corridor `danger` must be within the pool danger band;
- omitted `danger_min` means `0.0`;
- omitted `danger_max` means `1.0`;
- if multiple pools match, selection is deterministic from corridor id and profile id;
- if no pool matches, the plan returns an empty `hazard_pool_refs` array.

## Non-Goals

- procedural room graph generation;
- final encounter density tuning;
- runtime non-determinism;
- multi-hazard corridor planning;
- biome/depth rules beyond tags and danger bands.

## Implementation Notes

Implemented in:

```text
resources/schemas/dungeon_event_pool.schema.json
resources/data/dungeon_event_pools/base_old_mine_pools.json
scripts/domain/dungeon_state_model.gd
```

The prototype is intentionally small so the later generator can call the same function and still produce ordinary corridor data.
