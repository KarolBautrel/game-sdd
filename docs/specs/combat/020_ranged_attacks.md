# 020 Ranged Attacks

Status: specified  
Date: 2026-07-14

## Intent

Ranged attacks allow units to target enemies beyond adjacent melee range.

## Scope V1

- `ranged_attack` is a single-target enemy action.
- The action costs 1 AP.
- The action has maximum range 3.
- Range uses Chebyshev distance, matching the current 8-way movement and melee adjacency model.
- The target must be a living enemy unit.
- The actor must be the active living unit.
- The actor must have `ranged_attack` in `available_actions`.
- Hit chance is resolved by `021_hit_chance.md`.
- On hit, damage uses the current deterministic prototype formula:
  - `max(1, attacker.strength - target.defense)`
- The action emits the same deterministic event shape as melee:
  - `action_performed`
- `hit_roll_resolved`
- optional `damage_applied`
  - optional `unit_defeated`
  - optional `combat_ended`

## Rejections

- `target_out_of_range` when target distance is greater than 3.
- Existing action rejection reasons still apply:
  - `missing_actor`
  - `missing_target`
  - `actor_is_not_active_unit`
  - `actor_defeated`
  - `target_defeated`
  - `target_is_not_enemy`
  - `not_enough_ap`
  - `action_not_available`

## Deferred

- minimum range;
- ammunition;
- cooldowns;
- line of sight;
- cover;
- reaction attacks;
- area ranged skills.
