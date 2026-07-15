# 074 Combat Action Feedback

Status: implemented
Date: 2026-07-15

## Purpose

Prove that confirmed combat actions produce reusable board-level feedback messages from resolver events.

The owning presentation rules live in:

```text
docs/specs/combat/presentation/074_combat_action_feedback.md
```

## Acceptance

- `damage_applied` event maps to a floating text message with:
  - target unit id from `target_unit_id`;
  - text `-X DMG`;
  - damage styling.
- `hit_roll_resolved` with `outcome: "miss"` maps to a floating text message with:
  - target unit id from `target_unit_id`;
  - text `MISS`;
  - miss styling.
- `status_applied` event maps to a floating text message with:
  - target unit id from `target_unit_id`;
  - uppercase status id text, such as `STUNNED` or `BLEEDING`;
  - status styling.
- Message construction is owned by `scripts/presentation/combat/combat_floating_text.gd`.
- `combat_debug.gd` may choose positions and layers, but it should not duplicate event-to-message mapping.

## Proof

Current automated coverage:

- Godot floating text helper test:
  `Godot --headless --path ... --script res://scripts/presentation/combat_floating_text_tests.gd --resolution 2560x1440`
- `python tools\validators\validate_all.py`
- Godot project load:
  `Godot --headless --path ... --quit --resolution 2560x1440`
- Godot combat domain slices:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`

Current manual verification gap:

- Automated coverage verifies event-to-message mapping, but there is no screenshot/UI harness yet that asserts the floating text appears visually on the board.
- Until that exists, verify in `CombatDebug.tscn` by executing a hit and a ranged miss scenario.
