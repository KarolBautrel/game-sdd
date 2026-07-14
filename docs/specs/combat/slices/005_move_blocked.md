# 010 Combat Slice 05 Move Blocked

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that blocked tiles prevent movement.

## Scenario

Player starts at `{ "x": 1, "y": 1 }`. Tile `{ "x": 2, "y": 1 }` is `blocked`. The player attempts to move onto that tile.

## Expected Result

- command is rejected;
- rejection reason is `destination_not_walkable`;
- player AP remains `1`;
- player position remains `{ "x": 1, "y": 1 }`;
- no mutation events are emitted.

