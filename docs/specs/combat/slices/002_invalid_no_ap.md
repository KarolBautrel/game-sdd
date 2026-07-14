# 007 Combat Slice 02 Invalid No AP

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that an invalid combat command does not mutate combat state.

## Scenario

Player and enemy start adjacent on a 6x6 grid. The player attempts `basic_attack`, but the player has 0 AP. The command is rejected and no unit state changes.

## Reference Files

- Encounter: `resources/data/combat_encounters/slice_02_invalid_no_ap.json`
- Commands: `tests/data/combat_commands/slice_02_invalid_no_ap_commands.json`
- Python resolver: `tools/combat/simulate_combat.py`

## Initial State

The scenario mirrors Slice 01 with one difference:

- `unit_player_001.resources.ap` is `0`

## Expected Result

Final state:

- player AP: `0`
- player HP: `10`
- enemy HP: `6`
- player position: `{ "x": 1, "y": 1 }`
- enemy position: `{ "x": 2, "y": 1 }`
- combat result: `in_progress`

Required event types:

1. `combat_started`
2. `turn_started`
3. `command_rejected`

The `command_rejected` event must include:

```json
{
  "reason": "not_enough_ap"
}
```

Forbidden event types:

- `action_performed`
- `damage_applied`
- `unit_defeated`
- `combat_ended`

## Acceptance Criteria

### Invalid command does not mutate state

- Given the active player has 0 AP
- And the enemy is adjacent
- When the player attempts `basic_attack`
- Then the command is rejected with `not_enough_ap`
- And player AP remains 0
- And enemy HP remains 6
- And no mutation events are emitted

