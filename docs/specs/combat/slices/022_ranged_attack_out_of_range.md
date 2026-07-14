# 022 Ranged Attack Out Of Range

Status: verified  
Date: 2026-07-14

## Intent

Verify that `ranged_attack` rejects targets beyond range 3.

## Given

- player is the active unit;
- player has 1 AP and `ranged_attack`;
- enemy is alive at Chebyshev distance 4.

## When

Player performs `ranged_attack` against the enemy.

## Then

- command is rejected with `target_out_of_range`;
- player AP does not change;
- enemy HP does not change;
- event log contains:
  - `combat_started`
  - `turn_started`
  - `command_rejected`

