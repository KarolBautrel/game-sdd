# 016 Dungeon Trap Tools V1

Status: implemented
Date: 2026-07-16

## Intent

Define the first trap-disarm corridor hazard.

Some corridors contain traps. If the party has trap tools, it can attempt or automatically perform safer disarm. Without tools, a party member may trigger the trap and receive HP loss, poison, bleeding, crippled movement, or another dungeon debuff.

## Required Supply

Working supply id:

- `trap_tools`

The name can be changed later, but future implementation should keep a stable supply id in data.

## Trap Types

Initial planned trap families:

- `blade_trap`: bleeding, HP loss, armor damage later;
- `needle_trap`: poison, HP over time, accuracy/evasion penalty later;
- `snare_trap`: crippled/limping, MP reduction;
- `falling_rocks`: HP loss, stunned/fatigued, possible light loss;
- `alarm_trap`: ambush or stronger next encounter.

## Target Flow

1. Corridor trap triggers.
2. If trap tools are available, player can disarm or auto-resolve safely depending on final design.
3. Without tools, a party member triggers it.
4. Resolution selects a target and outcome.
5. Outcome applies dungeon debuff, HP loss, light loss, or ambush modifier.

## Target Selection Direction

Before full character roster exists, tests may target a placeholder party member id. Later:

- choose front character;
- choose random living party member;
- choose lowest scouting/evasion member;
- choose based on party formation.

Target selection must be deterministic under test seed.

## Implementation Timing

Implement after the hazard outcome contract and debuff table exist. Traps need debuffs, target selection, and deterministic weighted outcomes.

## Implementation Notes

Implemented first-pass support in:

```text
resources/data/dungeons/dungeon_old_mine.json
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
```

`crossing_to_nest` now contains `needle_trap_crossing_nest`, a corridor trap before `Spider Nest`.

The player gets a corridor popup and can choose:

- `Use trap tools`: consumes `trap_tools` and disarms the trap safely;
- `Force passage`: triggers `poisoned_by_needle_trap`, applying HP loss and `poisoned`.

This is intentionally still party-level until character roster targeting exists. Future versions should choose a deterministic party member target.

## Non-Goals

- full skill checks;
- trap detection/scouting system;
- trap visuals;
- inventory economy.
