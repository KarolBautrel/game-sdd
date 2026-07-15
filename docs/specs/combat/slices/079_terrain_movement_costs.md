# 079 Terrain Movement Costs

Status: implemented
Date: 2026-07-15

## Purpose

Prove that movement points spend authored terrain costs instead of treating every walkable tile as one step.

The owning rules live in:

```text
docs/specs/combat/grid/024_terrain.md
```

## Acceptance

- `floor` and `cover_low` cost 1 MP to enter.
- `highground` costs 2 MP to enter.
- A unit with enough MP can enter highground and spends the increased cost.
- A unit with only 1 MP cannot enter adjacent highground and receives `not_enough_mp`.
- `unit_moved.path` still lists each traversed tile for animation.
- `unit_moved.mp_spent` and `action_performed.mp_spent` record total terrain cost, not path length.
- Enemy AI pathfinding respects terrain costs when choosing an MP move.
- Combat sandbox move preview shows the resulting total MP cost before confirmation.
- Combat presentation raises units standing on highground above the tile center.
- Combat presentation shows a small highground base/ledge marker under elevated units so low-profile units remain readable.

## Proof

Automated coverage:

- Data:
  - `resources/data/combat_encounters/slice_79_terrain_movement_costs.json`
  - `tests/data/combat_commands/slice_79_terrain_movement_costs_commands.json`
- Python combat slice validator:
  `python -m tools.validators.validate_combat_slice`
- Godot combat slice tests:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`

Manual UI verification gap:

- There is no screenshot/UI harness yet that asserts highground readability or unit elevation.
- Until that exists, verify in `CombatDebug.tscn` by selecting Move near a highground tile and checking that highground reads as raised ground, the preview labels the increased MP cost, and units on highground render higher with a visible base/ledge cue.
