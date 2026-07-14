# 019 Highground Walkable

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that `highground` is a walkable combat tile.

## Scenario

Player starts at `{ "x": 1, "y": 1 }` and moves to adjacent `highground` at `{ "x": 2, "y": 1 }`.

## Expected Result

- command action is `move`;
- player position becomes `{ "x": 2, "y": 1 }`;
- player AP becomes `0`;
- event log contains `unit_moved`;
- combat remains `in_progress`.

