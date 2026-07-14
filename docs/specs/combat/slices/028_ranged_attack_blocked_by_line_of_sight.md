# 028 Ranged Attack Blocked By Line Of Sight

Status: verified  
Date: 2026-07-14

## Intent

Verify that `ranged_attack` cannot target through a `blocked` tile.

## Given

- player is the active unit;
- player has 1 AP and `ranged_attack`;
- enemy is alive and within range 3;
- a `blocked` tile lies between player and enemy.

## When

Player performs `ranged_attack`.

## Then

- command is rejected with `target_not_visible`;
- player AP does not change;
- enemy HP does not change;
- no hit roll is emitted;
- no damage is applied.

