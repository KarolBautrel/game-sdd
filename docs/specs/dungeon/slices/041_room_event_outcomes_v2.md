# Slice 041: Room Event Outcomes V2

Status: implemented
Owner spec: `docs/specs/dungeon/overview/034_room_event_outcomes_v2.md`

## Acceptance

- A room event choice can require a supply and becomes unavailable when that supply is missing.
- Room event outcomes can record positive, neutral, or negative tone.
- Weighted outcomes for one choice remain deterministic under the dungeon hazard seed.
- Room event logs include outcome tone and skill-check metadata when present.
- Room event history counts resolved outcome tones.

## Proof

- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
