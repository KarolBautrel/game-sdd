# 010 Diagonal Move

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that combat movement allows diagonal adjacency.

## Scenario

Player starts at `{ "x": 1, "y": 1 }` and moves diagonally to `{ "x": 2, "y": 2 }`.

## Expected Result

- command action is `move`;
- player AP is reduced from `1` to `0`;
- player position becomes `{ "x": 2, "y": 2 }`;
- event log contains `unit_moved`;
- combat remains `in_progress`.

## Rule Proven

Adjacent tiles include all 8 surrounding tiles.

