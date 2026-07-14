# 030 Enemy AI Ranged Attack

Status: implemented  
Date: 2026-07-14

## Intent

Verify that enemy AI can use `ranged_attack` before moving when a living player is in range and visible.

## Setup

- enemy is the active unit;
- enemy has 1 AP and `ranged_attack`;
- player is not adjacent;
- player is within range 3;
- line of sight is clear.

## Command

Enemy AI chooses one command.

## Expected Result

- AI chooses `ranged_attack`;
- target is `unit_player_001`;
- enemy AP becomes 0;
- `hit_roll_resolved` is emitted;
- deterministic roll hits;
- player HP is reduced from 10 to 8.
