# 025 Accuracy Increases Hit Chance

Status: verified  
Date: 2026-07-14

## Intent

Verify that attacker accuracy increases ranged hit chance.

## Given

- player is the active unit;
- player has `accuracy: 10`;
- enemy has `evasion: 0`;
- base ranged hit chance is 70;
- deterministic roll is 72.

## When

Player performs `ranged_attack`.

## Then

- final hit chance is 80;
- `hit_roll_resolved` has `outcome: hit`;
- damage is applied.

