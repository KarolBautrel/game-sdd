# Dungeon Beta Combat Loop V1

Status: implemented
Owner: dungeon overview

## Purpose

Make the first dungeon-combat-dungeon loop understandable as a playable beta flow. Combat may still use debug helpers, but returning from combat must leave dungeon state and player-facing feedback in a coherent state.

## Rules

- Dungeon session owns the handoff into combat and back.
- Combat returns a result payload; dungeon consumes it through `DungeonStateModel.apply_combat_result`.
- The session must clear the pending combat launch only after the dungeon result is accepted.
- On victory, the return feedback names the room, confirms whether it was secured, and tells the player what to do next.
- On guarded treasure victory, feedback must also tell the player that the reward is unlocked and summarize the reward.
- On defeat, feedback must name the room and clarify that the room remains dangerous.
- The feedback is stored in the session so the dungeon scene can display it after scene transition.

## Current Scope

This slice hardens the readable return feedback after combat. It does not yet replace debug combat controls, add world-map return payloads, or implement party injury persistence beyond the existing dungeon modifier bridge.

## Proof

- `scripts/session/dungeon_run_session_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
