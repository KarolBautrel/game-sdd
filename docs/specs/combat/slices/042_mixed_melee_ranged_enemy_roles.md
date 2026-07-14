# 042 Mixed Melee Ranged Enemy Roles

Status: implemented  
Date: 2026-07-14

## Intent

Verify that melee and ranged enemies can act together without needing a formal class system yet.

## Setup

- one player;
- enemy 001 has melee and movement actions only;
- enemy 002 has `ranged_attack`;
- enemy 001 acts before enemy 002.

## Expected Result

- enemy 001 chooses `move`;
- enemy 001 moves to `{ "x": 3, "y": 1 }`;
- enemy 001 ends turn;
- enemy 002 chooses `ranged_attack`;
- enemy 002 targets `unit_player_001`;
- ranged attack resolves a deterministic hit;
- player HP is reduced from 10 to 8;
- enemy 002 does not move into enemy 001's front tile.
