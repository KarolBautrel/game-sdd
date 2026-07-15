# 084 Bleeding Death Skips Turn

Status: implemented
Date: 2026-07-15

## Purpose

Prevent combat from locking when a unit dies from bleeding at the start of its own turn.

The owning status rules live in:

```text
docs/specs/combat/attacks/077_bleeding_status_v1.md
```

## Acceptance

- A unit with `bleeding` starts its own turn at 1 HP.
- Bleeding tick damage reduces that unit to 0 HP.
- `damage_applied` and `unit_defeated` are emitted for the bleeding tick.
- If combat is still in progress, the dead actor's turn is ended automatically.
- Turn ownership advances to the next living unit in `turn_order`.
- The next living unit receives refreshed AP/MP and can act.
- No `end_turn` command is required from the defeated unit.

## Proof

Automated coverage:

- Data:
  - `resources/data/combat_encounters/slice_84_bleeding_death_skips_turn.json`
  - `tests/data/combat_commands/slice_84_bleeding_death_skips_turn_commands.json`
- Godot combat slice tests:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`

## Non-Goals

- corpse cleanup presentation;
- bleed resistance;
- simultaneous turn starts.
