# 024 Ranged Attack Miss

Status: verified  
Date: 2026-07-14

## Intent

Verify that `ranged_attack` can miss deterministically.

## Given

- player is the active unit;
- player has 1 AP and `ranged_attack`;
- enemy is alive within range 3;
- deterministic roll is above the 70% hit chance.

## When

Player performs `ranged_attack` against the enemy.

## Then

- player spends 1 AP;
- `hit_roll_resolved` is emitted with `outcome: miss`;
- enemy HP does not change;
- `damage_applied` is not emitted.

