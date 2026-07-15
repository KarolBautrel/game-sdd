# 077 Bleeding Status V1

Status: implemented
Date: 2026-07-15

## Purpose

Prove the first damage-over-time status from attack application through turn-start tick and expiry.

The owning status rules live in:

```text
docs/specs/combat/attacks/077_bleeding_status_v1.md
```

## Acceptance

- Hero has `deep_cut`.
- `deep_cut` hits an adjacent enemy.
- `deep_cut` applies normal damage.
- `deep_cut` applies `bleeding` to the target.
- `bleeding` emits `status_applied`.
- When the bleeding unit starts its own turn, bleeding deals 1 damage.
- Bleeding tick emits `damage_applied` with `source_status_id: "bleeding"`.
- Bleeding duration decreases on each affected own-turn start.
- Bleeding expires after its configured turns and emits `status_expired`.
- Godot presentation can show `BLEEDING`, `-X DMG`, and a compact bleeding status icon.

## Proof

Automated coverage:

- Data:
  - `resources/data/combat_encounters/slice_77_bleeding_status_v1.json`
  - `tests/data/combat_commands/slice_77_bleeding_status_v1_commands.json`
- Python combat slice validator:
  `python -m tools.validators.validate_combat_slice`
- Godot combat slice tests:
  `Godot --headless --path ... --script res://scripts/domain/combat_slice_tests.gd --resolution 2560x1440`
- Existing presentation helper tests:
  - `combat_floating_text_tests.gd`
  - `combat_unit_visual_state_tests.gd`

Manual UI verification gap:

- There is no screenshot/UI harness yet that asserts the bleeding icon is visible above the unit.
- Until that exists, verify in `CombatDebug.tscn` by using `Deep cut` and advancing turns until bleeding ticks and expires.
