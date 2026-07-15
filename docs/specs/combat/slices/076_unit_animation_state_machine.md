# 076 Unit Animation State Machine

Status: implemented
Date: 2026-07-15

## Purpose

Prove that unit visual state selection is reusable and event-driven.

The owning presentation rules live in:

```text
docs/specs/combat/presentation/076_unit_animation_state_machine.md
```

## Acceptance

- `unit_moved` maps actor visual action to `walk`.
- `damage_applied` maps actor visual action to `combat`.
- `damage_applied` maps a living target to `hit`.
- `damage_applied` maps a defeated target to `death`.
- `hit_roll_resolved` maps actor visual action to `combat`.
- `status_applied` maps target visual action to `status_reaction`.
- `combat_debug.gd` uses the shared state helper instead of duplicating the event-to-visual-action mapping.

## Proof

Automated coverage:

- Godot unit visual state helper test:
  `Godot --headless --path ... --script res://scripts/presentation/combat_unit_visual_state_tests.gd --resolution 2560x1440`
- `python tools\validators\validate_all.py`
- Godot project load:
  `Godot --headless --path ... --quit --resolution 2560x1440`
- Godot combat domain slices:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`

Manual UI verification gap:

- There is no screenshot/UI harness yet that asserts the exact sprite frame shown on the board.
- Until that exists, verify in `CombatDebug.tscn` by moving, attacking, taking damage, and defeating a unit.
