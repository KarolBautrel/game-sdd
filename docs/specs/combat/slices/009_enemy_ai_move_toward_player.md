# 009 Enemy AI Move Toward Player

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that enemy AI v0 moves toward the nearest living player when no adjacent attack is available.

## Scenario

Enemy is active at `{ "x": 4, "y": 1 }`. Player is at `{ "x": 1, "y": 1 }`. Enemy is not adjacent and has 1 AP. AI chooses `move` to `{ "x": 3, "y": 1 }`.

## Expected Result

- generated command action is `move`;
- generated command target is `{ "x": 3, "y": 1 }`;
- enemy AP is reduced from `1` to `0`;
- enemy position changes from `{ "x": 4, "y": 1 }` to `{ "x": 3, "y": 1 }`;
- event log contains `action_performed` and `unit_moved`;
- combat remains `in_progress`.

## AI Rule Proven

Enemy AI v0 priority:

1. If adjacent to a living player unit and has AP, use `basic_attack`.
2. If not adjacent and has AP, move one legal orthogonal tile that reduces Manhattan distance to the nearest living player.
3. Otherwise, use `end_turn`.

