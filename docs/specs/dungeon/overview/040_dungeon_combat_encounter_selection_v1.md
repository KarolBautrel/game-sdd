# 040 Dungeon Combat Encounter Selection V1

Status: implemented
Date: 2026-07-17

## Intent

Replace the single generated-dungeon debug combat reference with seed-driven encounter selection by dungeon theme, generated profile, difficulty, and room kind.

The goal is not to mass-produce tactical boards yet. The goal is to create the data boundary that lets future map work be deliberate and world-aware.

## Rules

- Authored combat content may still pin `combat_encounter_path`.
- Generated/template combat content may declare `combat_encounter_pool_id`.
- Pool selection filters entries by:
  - dungeon theme;
  - generated profile;
  - difficulty range;
  - combat room kind.
- Selection is deterministic from seed, room id, and pool id.
- The selected combat path is materialized into the generated dungeon content before the state model enters rooms.
- Pending combat requests expose the selected encounter path and encounter selection metadata.

## Tactical Map Design Rules

Combat maps selected for dungeon rooms must be tactically legible and visually grounded.

Detailed authoring guidance lives in:

```text
resources/data/combat_encounters/STRUCTURE.md
```

- The base floor should read as one coherent place, not random tile noise.
- Blocked tiles must correspond to believable large blockers such as cave walls, collapsed shafts, big boulders, mine carts, timber piles, or heavy machinery.
- Small visual props must not become hard blockers unless the asset clearly communicates obstruction.
- Cover should be readable as cover: crates, carts, barricades, pillars, large rock formations, timber braces, or similar.
- High ground should be justified by the environment: ledges, raised walkways, platforms, ramps, scaffold, or broken mine levels.
- Tactical layout and worldbuilding should support each other: a spider nest, guarded spur, vault, sump, or gallery should fight differently and look like that place.
- Gameplay readability wins over decoration.

## Non-Goals

- creating a final combat map set;
- final enemy roster balance;
- final asset pass;
- free-form encounter generation;
- combat AI changes.

## Proof

- schema validation for combat encounter pools;
- validator checks that pool entries reference presentation-ready combat encounter JSON files;
- generated dungeon tests prove selected encounter paths vary through pool selection;
- state model tests prove pending combat requests include selected encounter metadata.
