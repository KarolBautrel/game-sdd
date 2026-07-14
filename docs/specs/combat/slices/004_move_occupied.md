# 009 Combat Slice 04 Move Occupied

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that a unit cannot move onto a tile occupied by another living unit.

## Scenario

Player starts at `{ "x": 1, "y": 1 }`. Enemy starts at `{ "x": 2, "y": 1 }`. The player attempts to move onto the enemy tile.

## Expected Result

- command is rejected;
- rejection reason is `destination_occupied`;
- player AP remains `1`;
- player position remains `{ "x": 1, "y": 1 }`;
- enemy position remains `{ "x": 2, "y": 1 }`;
- no mutation events are emitted.

