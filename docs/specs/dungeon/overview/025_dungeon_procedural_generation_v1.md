# 025 Dungeon Procedural Generation V1

Status: implemented
Date: 2026-07-16

## Intent

Turn the fixed generated draft into a first randomized generated dungeon flow.

Generated dungeon data should not be the same graph every time. In V1 this is achieved by selecting from curated templates by seed and difficulty, then generating corridor hazards from reusable pools.

## Contract

`DungeonStateModel.procedural_dungeon_draft(config)` remains the debug entrypoint, but it now accepts:

```json
{
  "seed": 12345,
  "difficulty": 2,
  "theme_tags": ["mine", "corridor"]
}
```

Rules:

- same seed and difficulty must produce the same graph;
- different seeds should be able to select different graph layouts;
- difficulty filters available authored template layouts;
- generated data must still match the normal dungeon data shape;
- generated corridors must keep using `procedural_corridor_plan` for hazard pool refs;
- generated rooms must include entrance, at least one route room, at least one treasure room, at least one combat room, and one exit.

## Difficulty Bands

First implementation bands:

- difficulty 1: short run, roughly 5 rooms;
- difficulty 2: medium run, roughly 7 rooms;
- difficulty 3: longer run, roughly 9 rooms.

The first generation pass should prefer template selection over free-form graph generation. See `026_dungeon_template_pool_generation_v1.md`.

## Debug UX Rules

The debug dungeon screen should generate a new seed when switching into Generated Draft or rerolling while already in Generated Draft during preparation.

The generated title or loadout summary should expose the seed and difficulty so testers can identify what they are testing.

## Non-Goals

- free-form graph algorithms;
- biome-specific room art;
- persisted generated dungeons;
- player-facing seed input;
- final balancing of rewards or encounter density.

## Implementation Notes

Implemented in:

```text
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
```
