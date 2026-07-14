# 027 Highground Increases Ranged Hit Chance

Status: verified  
Date: 2026-07-14

## Intent

Verify that a ranged attacker standing on `highground` receives a hit chance bonus.

## Given

- player is the active unit;
- player stands on a `highground` tile;
- player has `accuracy: 0`;
- enemy has `evasion: 0`;
- base ranged hit chance is 70;
- highground terrain modifier is 10;
- deterministic roll is 72.

## When

Player performs `ranged_attack`.

## Then

- final hit chance is 80;
- `hit_roll_resolved` has `terrain_modifier: 10`;
- `hit_roll_resolved` has `outcome: hit`;
- damage is applied.

