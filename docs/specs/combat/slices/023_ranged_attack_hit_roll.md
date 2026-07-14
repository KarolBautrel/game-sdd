# 023 Ranged Attack Hit Roll

Status: verified  
Date: 2026-07-14

## Intent

Verify that `ranged_attack` resolves a deterministic hit roll before applying damage.

## Given

- player is the active unit;
- player has 1 AP and `ranged_attack`;
- enemy is alive within range 3;
- deterministic roll is within the 70% hit chance.

## When

Player performs `ranged_attack` against the enemy.

## Then

- player spends 1 AP;
- `hit_roll_resolved` is emitted with `outcome: hit`;
- enemy receives deterministic damage;
- event log contains:
  - `combat_started`
  - `turn_started`
  - `action_performed`
  - `hit_roll_resolved`
  - `damage_applied`

