# Room Event System V2

Status: implemented
Owner: dungeon overview

## Purpose

Expand room exploration beyond the first shrine and stash examples while keeping room events reusable, data-driven, and trackable across a run.

## Rules

- Room event catalogues support these beta event types:
  - `stash`;
  - `shrine`;
  - `chest`;
  - `locked_chest`;
  - `corpse`;
  - `note`;
  - `curio`;
  - `blocked_object`;
  - `hidden_cache`;
  - `generic`.
- Event tags describe theme, room role, and interaction family, such as `mine`, `treasure`, `lore`, `cache`, `risk`, or `locked`.
- Room event pools may mix event families, but every entry must reference a valid event id from the room-event catalogue.
- Resolving a room event records history in dungeon state.
- `room_event_history` tracks:
  - total resolved count;
  - event ids resolved;
  - counts by event type;
  - counts by tag.
- Room event history is informational in V2. It prepares pacing and anti-repetition rules but does not yet alter event selection weights.
- Generated dungeon room event pools may use the expanded event catalogue without changing the room-event prompt contract.

## Current Scope

This version adds expanded reusable event data and history tracking. It does not yet add locked-chest key consumption, skill checks, hidden-object reveal UX, or event selection rules that avoid repeated tags.

## Proof

- `resources/schemas/dungeon_room_event.schema.json`
- `resources/schemas/dungeon_room_event_pool.schema.json`
- `tools/validators/validate_all.py`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
