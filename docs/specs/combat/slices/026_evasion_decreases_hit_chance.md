# 026 Evasion Decreases Hit Chance

Status: verified  
Date: 2026-07-14

## Intent

Verify that target evasion decreases ranged hit chance.

## Given

- player is the active unit;
- player has `accuracy: 0`;
- enemy has `evasion: 40`;
- base ranged hit chance is 70;
- deterministic roll is 40.

## When

Player performs `ranged_attack`.

## Then

- final hit chance is 30;
- `hit_roll_resolved` has `outcome: miss`;
- damage is not applied.

