# 021 Ranged Attack In Range

Status: verified  
Date: 2026-07-14

## Intent

Verify that a unit can damage a living enemy with `ranged_attack` at range 3.

## Given

- player is the active unit;
- player has 1 AP and `ranged_attack`;
- enemy is alive at Chebyshev distance 3;
- no line of sight or cover rule is applied in this slice;
- deterministic hit chance resolves as a hit.

## When

Player performs `ranged_attack` against the enemy.

## Then

- player spends 1 AP;
- hit roll resolves as `hit`;
- enemy receives deterministic damage;
- event log contains:
  - `combat_started`
  - `turn_started`
  - `action_performed`
  - `hit_roll_resolved`
  - `damage_applied`
