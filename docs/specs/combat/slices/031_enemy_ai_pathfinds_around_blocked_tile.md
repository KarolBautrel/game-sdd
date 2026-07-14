# 031 Enemy AI Pathfinds Around Blocked Tile

Status: implemented  
Date: 2026-07-14

## Intent

Verify that enemy AI does not get stuck when a blocked tile prevents the direct approach.

## Setup

- enemy is the active unit;
- enemy has 1 AP, `move`, and `ranged_attack`;
- player is behind a `blocked` tile;
- the blocked tile also prevents a legal ranged shot;
- a walkable route exists around the obstacle.

## Command

Enemy AI chooses one command.

## Expected Result

- AI does not choose `ranged_attack`;
- AI chooses `move`;
- destination is `{ "x": 4, "y": 2 }`;
- enemy AP becomes 0.
