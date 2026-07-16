# Dungeon Spec Structure

Status: active
Date: 2026-07-15

## Intent

Dungeon specs own the exploration layer between world/campaign flow and tactical combat.

Dungeon exploration is not tactical combat on a second grid. It is an authored dungeon-crawler layer where the party moves through corridors and room checkpoints, resolves room content, manages expedition pressure, and launches combat when an encounter is triggered.

The target design includes dungeon-specific mechanics such as supplies, light, corridor hazards, obstacle tools, and negative exploration events. These systems belong to dungeon specs and dungeon state, not combat.

## Folder Map

```text
docs/specs/dungeon/
  README.md
  STRUCTURE.md
  overview/
    Dungeon exploration loop and boundaries with combat.
  presentation/
    Dungeon exploration debug and production-facing UI rules.
  slices/
    Executable dungeon acceptance scenarios once a dungeon validator or scene harness exists.
  milestones/
    Human-readable implementation summaries and next steps.
```

Future folders may be added when implementation needs them:

```text
  map/
    Dungeon graph, rooms, corridors, connectivity, and authored content nodes.
  encounters/
    Dungeon encounter trigger and reward rules.
  resources/
    Expedition supplies, light, corridor hazards, and dungeon-only pressure mechanics.
```

## Rules

- Durable dungeon rules live in domain specs, not only in milestones.
- Dungeon slices should be added when dungeon behavior becomes executable.
- Until an executable dungeon harness exists, dungeon specs must clearly label planned behavior as planned.
- The dungeon-combat boundary must stay data-driven: dungeon sends an encounter request to combat and receives a combat result payload back.
- Combat does not own dungeon navigation, room clearing, rewards inventory application, or quest state.
- Dungeon does not decide combat legality or combat outcomes.
- Dungeon owns exploration resources, corridor hazards, supplies, light state, and non-combat traversal consequences.
