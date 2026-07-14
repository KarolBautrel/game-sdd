# 000 Combat Core

Status: draft  
Date: 2026-07-14

## Intent

Combat is the tactical layer of the game. It resolves encounters on a square grid through deterministic, turn-based commands.

The first implementation target is intentionally small:

- one player unit;
- one enemy unit;
- one 6x6 grid;
- move, basic attack, defend, end turn;
- deterministic command resolution;
- event log that can replay the outcome.

## Design Rules

1. Combat rules are domain logic.

   UI, animation, sound, and Godot scenes must not decide whether a command is legal or what effect it has.

2. Commands are explicit.

   A combat command is a data object with actor id, action id, target data, and expected preconditions.

3. Results are events.

   Combat resolution emits events. Presentation listens to events and displays feedback.

4. RNG is controlled.

   Any random result must come from the combat RNG seed and must be visible in the event log.

5. Invalid commands do not mutate combat state.

   A rejected command returns a rejection event or validation error, but HP, AP, positions, statuses, and turn order stay unchanged.

## Core Entities

### Combat Encounter

Required fields:

- `id`
- `seed`
- `grid`
- `units`
- `turn_state`
- `event_log`

### Unit

Required fields:

- `id`
- `team`
- `position`
- `stats`
- `resources`
- `statuses`
- `available_actions`

Allowed teams for the first slice:

- `player`
- `enemy`

### Stats

Minimum stats:

- `max_hp`
- `strength`
- `defense`
- `initiative`
- `move_points`
- `max_ap`

Optional hit resolution stats:

- `accuracy`
- `evasion`

### Resources

Minimum resources:

- `hp`
- `ap`

## Command Shape

Example:

```json
{
  "type": "perform_action",
  "actor_id": "unit_player_001",
  "action_id": "basic_attack",
  "target": {
    "type": "unit",
    "unit_id": "unit_enemy_001"
  }
}
```

## Acceptance Criteria

### Valid command mutates state

- Given it is `unit_player_001` turn
- And the unit has 1 AP
- And `unit_enemy_001` is adjacent
- When `unit_player_001` performs `basic_attack`
- Then player AP is reduced by 1
- And enemy HP is reduced by resolved damage
- And the event log contains `action_performed` and `damage_applied`

### Invalid command is rejected

- Given `unit_player_001` has 0 AP
- When it attempts `basic_attack`
- Then the command is rejected
- And no unit HP, AP, position, status, or turn state changes

### Combat can end

- Given all enemy units have 0 HP
- When combat state is evaluated
- Then the combat result is `victory`
- And the event log contains `combat_ended`

## Out Of Scope For First Slice

- Multi-character party.
- Cover.
- Line of sight.
- Elevation.
- Opportunity attacks.
- Morale.
- Complex AI.
- Status stacking rules beyond placeholder structure.
