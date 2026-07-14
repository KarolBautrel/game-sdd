# 016 Command After Combat End Rejected

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that commands cannot mutate combat after combat has already ended.

## Scenario

The encounter starts with no living enemies, so the combat result is already `victory`. The player attempts to move.

## Expected Result

- command is rejected;
- rejection reason is `combat_already_ended`;
- player position does not change;
- no mutation events are emitted.

