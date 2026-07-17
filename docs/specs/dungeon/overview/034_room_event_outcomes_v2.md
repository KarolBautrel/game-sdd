# Room Event Outcomes V2

Status: implemented
Owner: dungeon overview

## Purpose

Make room event choices mechanically expressive without requiring the final roster, skill, or inventory systems.

## Rules

- Room event choices may declare `requires_supply`.
- A choice with `requires_supply` is unavailable when the run has none of that supply.
- Room event outcomes may declare `tone`: `positive`, `neutral`, or `negative`.
- Room event outcomes may declare `skill_check` as future-facing metadata.
- `skill_check` records:
  - `skill_id`;
  - `difficulty`;
  - optional `target_id`.
- V2 does not roll skill checks yet; the metadata is preserved in pending prompts and resolved room event logs.
- Weighted outcomes remain supported for the same choice.
- Consequences may target party slots through existing `target_id` handling.
- Resolved room event logs and history record outcome tone.

## Current Scope

This version adds supply-gated choices, outcome tone, weighted risk examples, and skill-check metadata. It does not yet implement roster stats, skill roll resolution, or advanced UI for predicted odds.

## Proof

- `resources/schemas/dungeon_room_event.schema.json`
- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
