# 078 Guard Break V1

Status: implemented
Date: 2026-07-15

## Purpose

Prove that a melee debuff can lower target defense and make a follow-up hit stronger before expiring.

The owning rules live in:

```text
docs/specs/combat/actions/078_guard_break_v1.md
```

## Acceptance

- Hero has `guard_break`.
- `guard_break` hits an adjacent enemy.
- `guard_break` applies `guard_broken`.
- `guard_broken` emits `status_applied`.
- A follow-up `basic_attack` against the same target uses lowered effective defense.
- The follow-up attack deals more damage than it would against the target's base defense.
- `guard_broken` expires on the affected unit's next own-turn start and emits `status_expired`.
- Godot presentation can show `GUARD BROKEN` and a compact guard-broken status icon.

## Proof

Automated coverage:

- Data:
  - `resources/data/combat_encounters/slice_78_guard_break_v1.json`
  - `tests/data/combat_commands/slice_78_guard_break_v1_commands.json`
- Python combat slice validator:
  `python -m tools.validators.validate_combat_slice`
- Godot combat slice tests:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`
- Presentation helper tests:
  - `combat_floating_text_tests.gd`

Manual UI verification gap:

- There is no screenshot/UI harness yet that asserts the guard-broken icon is visible above the unit.
- Until that exists, verify in `CombatDebug.tscn` by using `Guard break`, then `Melee attack`, then ending the turn.
