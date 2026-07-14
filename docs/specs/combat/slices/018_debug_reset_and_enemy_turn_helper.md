# 018 Debug Reset And Enemy Turn Helper

Status: verified  
Date: 2026-07-14

## Intent

This debug scenario makes manual testing of the combat loop faster.

## Expected Debug Scene Behavior

- `reset` reloads the reference debug encounter.
- `enemy_turn` advances from player control into enemy AI and back toward player control when possible.
- If the player is active, `enemy_turn` first performs player `end_turn`.
- If the enemy is active, `enemy_turn` asks AI v0 for a command.
- If enemy AI spends its AP and remains active, `enemy_turn` asks AI v0 again so the enemy ends its turn.
- The event log keeps the generated sequence.
- Feedback label reports that the helper ran.

## Manual Acceptance

1. Start the combat debug scene.
2. Click `enemy_turn`.
3. The player turn ends, enemy acts, and control returns to the player when possible.
4. Click `reset`.
5. The board and event log return to the initial debug state.

