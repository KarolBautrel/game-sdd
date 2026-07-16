# 026 Dungeon Template Pool Generation V1

Status: implemented
Date: 2026-07-16

## Intent

Replace free-form generated dungeon graphs with a curated pool of predefined layouts.

The first generated dungeons should be reliable, readable, and visually sane. Layout randomness should come from selecting one authored template from a pool, while corridor events remain generated from reusable hazard pools.

## Contract

Generated dungeon data uses:

```text
resources/data/dungeon_templates/generated_old_mine_templates.json
```

Each template defines:

- `id`;
- `difficulty`;
- `display_name`;
- normal dungeon-shaped `rooms`;
- normal dungeon-shaped `corridors`;
- which corridors should request generated hazard pool refs.

`DungeonStateModel.procedural_dungeon_draft(config)` still accepts `seed` and `difficulty`, but it now:

- filters templates by difficulty;
- selects one template deterministically from the seed;
- instantiates the selected rooms/corridors;
- applies generated hazard pool refs to marked corridors through `procedural_corridor_plan`;
- guarantees the selected dungeon still uses the normal state model contract.

## Hazard Rules

Templates may mark corridors with `hazard_profile: "planned"`.

Marked corridors are hazard candidates. The generator must not apply hazards to every marked corridor and must not reserve specific corridors for a fixed hazard type. Instead, for each generated dungeon instance it must:

- choose a small number of marked candidate corridors by seed;
- assign hazard pool types by seed, so rubble and trap can swap between candidate corridors across rerolls;
- produce at least one rubble pool ref and one trap pool ref when the selected template has at least two planned candidates;
- keep unselected candidates hazard-free for that generated instance.

This preserves corridor hazard randomness without risking broken procedural graph layouts.

Each template should include multiple planned candidates where practical, so rerolling can move both rubble and traps to different corridors within the same layout.

## Initial Pool

The first pool contains five Old Mine layouts across difficulties 1-3.

## Non-Goals

- fully procedural graph generation;
- production-quality biome variety;
- player-facing seed input;
- final layout art;
- final reward/encounter balancing.

## Implementation Notes

Implemented in:

```text
resources/schemas/dungeon_template.schema.json
resources/data/dungeon_templates/generated_old_mine_templates.json
scripts/domain/dungeon_state_model.gd
tools/validators/validate_all.py
```
