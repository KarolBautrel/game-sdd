# 006 Combat Slice 01

Status: verified  
Date: 2026-07-14

## Intent

This is the first executable combat scenario. It proves that the combat core can load data, accept a command, mutate combat state, and emit a deterministic event log.

## Scenario

Player and enemy start adjacent on a 6x6 grid. The player performs `basic_attack`. The enemy loses HP, the player loses AP, and the event log records the result.

## Reference Files

- Encounter: `resources/data/combat_encounters/slice_01_basic_attack.json`
- Commands: `tests/data/combat_commands/slice_01_basic_attack_commands.json`
- Encounter schema: `resources/schemas/combat_encounter.schema.json`
- Command schema: `resources/schemas/combat_command.schema.json`
- Python resolver: `tools/combat/simulate_combat.py`

## Initial State

Grid:

- width: 6
- height: 6
- all tiles are `floor`

Units:

- `unit_player_001`
  - team: `player`
  - position: `{ "x": 1, "y": 1 }`
  - HP: 10
  - AP: 1
  - strength: 4
  - defense: 1
- `unit_enemy_001`
  - team: `enemy`
  - position: `{ "x": 2, "y": 1 }`
  - HP: 6
  - AP: 1
  - strength: 3
  - defense: 2

## Command List

```json
[
  {
    "id": "cmd_001",
    "type": "perform_action",
    "actor_id": "unit_player_001",
    "action_id": "basic_attack",
    "target": {
      "type": "unit",
      "unit_id": "unit_enemy_001"
    }
  }
]
```

## Expected Result

Damage:

```text
max(1, attacker.strength - target.defense)
max(1, 4 - 2) = 2
```

Final state:

- player AP: 0
- enemy HP: 4
- combat result: `in_progress`

Required event types:

1. `combat_started`
2. `turn_started`
3. `action_performed`
4. `damage_applied`

## Acceptance Criteria

### Slice passes

- Given the reference encounter and command list
- When `python tools/validators/validate_all.py` is run
- Then schemas pass
- And the Python combat simulation passes
- And the event log contains the required event sequence

### No Godot dependency

- Given Godot is not running
- When the combat slice is simulated
- Then the result is still deterministic and valid
