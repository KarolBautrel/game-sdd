# 075 Targeting Preview Completion

Status: implemented
Date: 2026-07-15

## Purpose

Prove that targeted actions expose enough pre-click information to be playable without reading the debug log.

The owning presentation rules live in:

```text
docs/specs/combat/presentation/068_combat_interaction_preview.md
```

## Acceptance

- Legal melee/special targets show guaranteed hit as `100% HIT`.
- Legal ranged/rolled targets show hit chance as `% HIT`.
- Legal targets show expected damage as `DMG X` when damage can be resolved in preview.
- Legal targeted actions show action cost as `COST X AP`.
- Rejected targets do not show unit-local damage or cost preview panels.
- Move preview continues to show movement cost as MP before confirmation.

## Proof

Automated coverage:

- Godot targeting preview helper test:
  `Godot --headless --path ... --script res://scripts/presentation/combat_targeting_preview_tests.gd --resolution 2560x1440`
- `python tools\validators\validate_all.py`
- Godot project load:
  `Godot --headless --path ... --quit --resolution 2560x1440`
- Godot combat domain slices:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`

Manual UI verification gap:

- There is no screenshot/UI harness yet that asserts panel layout or text placement on the board.
- Until that exists, verify in `CombatDebug.tscn` by selecting melee, ranged, and an out-of-range target.
