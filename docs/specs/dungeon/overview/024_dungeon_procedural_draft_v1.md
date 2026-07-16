# 024 Dungeon Procedural Draft V1

Status: implemented
Date: 2026-07-16

## Intent

Create the first generated dungeon-shaped data draft.

This is not final procedural generation. It is a deterministic helper that produces valid temporary room/corridor graphs and uses procedural corridor plans for hazard pool references. The goal is to prove that generated dungeon data can enter the same state model as authored dungeons.

## Contract

`DungeonStateModel.procedural_dungeon_draft(config)` returns a dictionary shaped like a normal dungeon data file:

- `id`;
- `display_name`;
- `recommended_party_level`;
- `start_room_id`;
- `max_light_level`;
- `hazard_seed`;
- `starting_supplies`;
- `supply_loadout_options`;
- `default_party_formation`;
- `rooms`;
- `corridors`;
- `exit_rules`.

The first draft must include:

- an entrance room;
- at least one connecting empty room;
- one treasure room;
- one combat room;
- one exit room;
- at least one low-danger corridor using a generated rubble pool ref;
- at least one high-danger corridor using a generated trap pool ref.
- variable route length and side branches once `025_dungeon_procedural_generation_v1.md` is implemented.

## Generation Rules

The draft is deterministic and parameterized by a small config:

```json
{
  "id": "generated_old_mine_draft",
  "display_name": "Generated Old Mine Draft",
  "theme_tags": ["mine", "corridor"],
  "hazard_seed": 31
}
```

Defaults are allowed so tests and tools can request a draft with an empty config.

Corridor hazard selection must call `procedural_corridor_plan`, so generated corridors use the same `hazard_pool_refs` contract as authored corridors.

Generation V1 extends the config with seed and difficulty. See:

```text
docs/specs/dungeon/overview/025_dungeon_procedural_generation_v1.md
```

## Non-Goals

- persisted generated dungeon files;
- UI switching between authored and generated maps;
- final encounter/reward balance.

## Implementation Notes

Implemented in:

```text
scripts/domain/dungeon_state_model.gd
```

The generated draft is meant to become the seam where a later graph generator plugs in room counts, depth, branches, and biome profiles.
