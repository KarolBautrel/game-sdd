# 032 Enemy AI Multi Turn Path Pursuit

Status: implemented  
Date: 2026-07-14

## Intent

Verify that enemy AI keeps following a path around an obstacle across multiple turns.

## Expected Result

- first AI move goes to `{ "x": 4, "y": 2 }`;
- after turn handoff and AP refresh, second AI move goes to `{ "x": 3, "y": 2 }`;
- enemy does not attempt to move diagonally through the blocked corner.
