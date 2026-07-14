# 041 Multi Enemy Bottleneck Spacing

Status: implemented  
Date: 2026-07-14

## Intent

Verify that enemies do not stack or emit invalid moves when they queue through a one-tile corridor.

## Setup

- one player waits at the left side of a corridor;
- two enemies approach from the right;
- only row `y:1` is walkable;
- enemy 001 acts before enemy 002.

## Expected Result

- enemy 001 moves from `{ "x": 4, "y": 1 }` to `{ "x": 3, "y": 1 }`;
- enemy 001 ends turn;
- enemy 002 sees `{ "x": 3, "y": 1 }` as occupied;
- enemy 002 moves from `{ "x": 5, "y": 1 }` to `{ "x": 4, "y": 1 }`;
- no enemy stacks on another enemy;
- no command is rejected;
- replay event log is deterministic.
