# 040 Multi Enemy Pathing And Targeting

Status: implemented  
Date: 2026-07-14

## Intent

Verify that multiple enemies make movement decisions against the current board state.

## Setup

- one player and two enemies;
- enemy 001 is active first;
- both enemies have `move`;
- both enemies path toward the same living player.

## Expected Result

- enemy 001 chooses `move` first;
- enemy 001 moves to `{ "x": 3, "y": 1 }`;
- enemy 001 ends turn;
- enemy 002 chooses `move` after enemy 001 has moved;
- enemy 002 moves to `{ "x": 3, "y": 2 }`;
- enemy 002 does not move onto enemy 001's occupied tile;
- replay event log is deterministic.
