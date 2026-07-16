# Dungeon Reusable Room Events V1

Status: implemented
Owner: dungeon overview

## Purpose

Rooms need reusable exploration events that are independent from corridor hazards. Corridor hazards answer "what happens between rooms"; room events answer "what is discovered inside this room".

## Rules

- Room events live in `resources/data/dungeon_room_events/`.
- Room event pools live in `resources/data/dungeon_room_event_pools/`.
- Dungeon room content may include `type: "room_event"` with either `event_id` or `room_event_pool_id`.
- A room event has:
  - stable `id`;
  - event `type`;
  - tags;
  - player-facing message;
  - choices;
  - outcomes.
- The first implementation supports `inspect` and `ignore` choices.
- Room event outcomes may grant rewards, change light, consume supplies, apply HP loss/debuff consequences, or log only.
- A room event is resolved once per run by its runtime content id.
- Unresolved room events create `pending_room_event` when the party enters the room.
- The party cannot move deeper, claim rewards, finish the dungeon, or enter combat while a room event choice is pending.

## Generated Dungeons

Generated dungeons may attach room-event pool refs to eligible non-entrance, non-exit rooms by seed. The selected room shape may be curated, but the event placement must remain seed driven.

## Proof

- `resources/schemas/dungeon_room_event.schema.json`
- `resources/schemas/dungeon_room_event_pool.schema.json`
- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/domain/dungeon_procedural_draft_tests.gd`
