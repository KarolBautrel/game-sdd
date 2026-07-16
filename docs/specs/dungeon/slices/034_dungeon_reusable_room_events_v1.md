# Slice 034: Dungeon Reusable Room Events V1

Status: implemented
Owner spec: `docs/specs/dungeon/overview/028_dungeon_reusable_room_events_v1.md`

## Acceptance

- Given authored Old Mine has a room event, entering that room creates `pending_room_event`.
- Given the player inspects a room event, the selected outcome is applied once and the event is marked resolved.
- Given the player ignores a room event, it is marked resolved without applying inspect rewards.
- Given generated Old Mine is built from a template, seed-driven room event pool refs are attached to eligible rooms.

## Proof

- `python tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
