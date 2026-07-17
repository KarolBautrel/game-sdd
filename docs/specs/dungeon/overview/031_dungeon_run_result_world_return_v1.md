# Dungeon Run Result And World Return V1

Status: implemented
Owner: dungeon overview

## Purpose

Turn the end of a dungeon run into a stable payload that can be consumed by the wider game. The first implementation does not build a full world-map scene; it creates the handoff contract and stores it in the dungeon session.

## Rules

- A dungeon run result payload has `type: dungeon_run_result`.
- Supported outcomes are `completed`, `retreated`, and `failed`.
- The payload includes dungeon id, display name, current room, completion room, visited room ids, cleared room ids, claimed rewards, reward totals, persistent effects, and `next_scene_path`.
- `completed` is produced by finishing an exit room.
- `retreated` may be produced only when dungeon exit rules allow retreat and there is no pending combat, corridor hazard, or room event.
- `failed` may be produced by session or future defeat/failure flow and preserves persistent dungeon effects.
- Session code stores the accepted payload as `pending_world_return_payload`.
- `next_scene_path` is a hook for the future world-map/app return flow. The first hook targets `res://scenes/app/App.tscn`.

## Current Scope

This does not yet apply rewards to a durable inventory, persist injuries to roster data, or change scenes to a dedicated world map. It gives those systems a stable payload to consume later.

## Proof

- `scripts/domain/dungeon_state_model_tests.gd`
- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
