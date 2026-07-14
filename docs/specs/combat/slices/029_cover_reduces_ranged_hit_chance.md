# 029 Cover Reduces Ranged Hit Chance

Status: verified  
Date: 2026-07-14

## Intent

Verify that a target standing on `cover_low` reduces ranged hit chance.

## Given

- player is the active unit;
- player has `ranged_attack`;
- enemy stands on `cover_low`;
- base ranged hit chance is 70;
- cover modifier is -20;
- deterministic roll is 72.

## When

Player performs `ranged_attack`.

## Then

- final hit chance is 50;
- `hit_roll_resolved` has `cover_modifier: -20`;
- `hit_roll_resolved` has `outcome: miss`;
- damage is not applied.

