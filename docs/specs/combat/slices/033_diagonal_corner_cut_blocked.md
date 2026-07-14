# 033 Diagonal Corner Cut Blocked

Status: implemented  
Date: 2026-07-14

## Intent

Verify that diagonal movement cannot cut through the corner of a blocked tile.

## Expected Result

- moving diagonally from `{ "x": 1, "y": 1 }` to `{ "x": 2, "y": 2 }` is rejected when `{ "x": 2, "y": 1 }` is blocked;
- rejection reason is `diagonal_corner_blocked`;
- actor position and AP are unchanged.
