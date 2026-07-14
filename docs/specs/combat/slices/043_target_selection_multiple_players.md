# 043 Target Selection Multiple Players

Status: implemented  
Date: 2026-07-14

## Intent

Verify that enemy AI chooses a deterministic living player target when multiple player units exist.

## Setup

- two living players are legal ranged targets;
- one defeated player is closer than the living targets;
- enemy is ranged-only for this slice;
- enemy has 1 AP and `ranged_attack`.

## Expected Result

- defeated player is ignored;
- enemy chooses the nearest living legal target;
- target is `unit_player_002`;
- ranged attack resolves a deterministic hit;
- `unit_player_002` HP is reduced from 10 to 8;
- `unit_player_001` HP remains 10.
