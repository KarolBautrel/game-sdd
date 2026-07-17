# Slice 040: Room Event System V2

Status: implemented
Owner spec: `docs/specs/dungeon/overview/033_room_event_system_v2.md`

## Acceptance

- Room event schema accepts the expanded beta event types.
- Old Mine room event catalogue includes chest, corpse, note, curio, and hidden-cache style reusable events.
- Room event pools reference the expanded catalogue.
- Resolving a room event updates `room_event_history` with event id, type count, and tag counts.
- Existing authored and generated room-event prompts still resolve through the same pending room-event flow.

## Proof

- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
