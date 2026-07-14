# 008 Combat Slice 03 Move

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that a unit can move on the combat grid when the destination is legal.

## Scenario

Player starts on a 6x6 grid with 1 AP. Enemy is nearby but not occupying the destination. The player performs `move` from `{ "x": 1, "y": 1 }` to `{ "x": 2, "y": 1 }`.

## Reference Files

- Encounter: `resources/data/combat_encounters/slice_03_move.json`
- Commands: `tests/data/combat_commands/slice_03_move_commands.json`
- Python resolver: `tools/combat/simulate_combat.py`

## Initial State

- player position: `{ "x": 1, "y": 1 }`
- enemy position: `{ "x": 4, "y": 1 }`
- player AP: `1`
- destination: `{ "x": 2, "y": 1 }`
- destination tile type: `floor`

## Expected Result

Final state:

- player AP: `0`
- player position: `{ "x": 2, "y": 1 }`
- enemy HP: `6`
- combat result: `in_progress`

Required event types:

1. `combat_started`
2. `turn_started`
3. `action_performed`
4. `unit_moved`

## Acceptance Criteria

### Legal move mutates state

- Given the active player has 1 AP
- And the destination is adjacent
- And the destination is inside grid bounds
- And the destination is a `floor` tile
- And the destination is unoccupied
- When the player performs `move`
- Then player AP becomes 0
- And player position becomes `{ "x": 2, "y": 1 }`
- And event `unit_moved` is emitted

