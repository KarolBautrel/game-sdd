# 080 Highground Ranged Range Bonus

Status: implemented
Date: 2026-07-15

## Purpose

Prove that a ranged attacker standing on highground can shoot slightly farther while keeping the existing highground hit chance bonus.

The owning rules live in:

```text
docs/specs/combat/attacks/020_ranged_attacks.md
docs/specs/combat/grid/024_terrain.md
docs/specs/combat/hit_resolution/021_hit_chance.md
```

## Acceptance

- `ranged_attack` keeps base maximum range 3.
- An attacker standing on `highground` gets +1 effective maximum range for `ranged_attack`.
- A highground ranged attacker can hit a visible enemy at Chebyshev distance 4.
- The same attack still gets the existing `terrain_modifier: 10` hit chance bonus.
- The attack spends AP and emits deterministic `action_performed`, `hit_roll_resolved`, and hit damage events.
- Floor attackers do not get this range bonus and remain rejected at distance 4 by existing slice 022.

## Proof

Automated coverage:

- Data:
  - `resources/data/combat_encounters/slice_80_highground_ranged_range_bonus.json`
  - `tests/data/combat_commands/slice_80_highground_ranged_range_bonus_commands.json`
- Python combat slice validator:
  `python -m tools.validators.validate_combat_slice`
- Godot combat slice tests:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`
