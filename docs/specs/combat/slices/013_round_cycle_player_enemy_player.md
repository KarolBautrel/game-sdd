# 013 Round Cycle Player Enemy Player

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that turn order can complete one full round and return control to the player with refreshed AP.

## Scenario

Player is active with 0 AP and ends turn. Enemy becomes active, moves one tile toward the player, then ends turn. Control returns to the player and round advances to 2.

## Commands

1. Player `end_turn`
2. Enemy `move` from `{ "x": 3, "y": 1 }` to `{ "x": 2, "y": 1 }`
3. Enemy `end_turn`

## Expected Result

- active unit becomes `unit_player_001`;
- round becomes `2`;
- player AP refreshes to `1`;
- enemy AP is `0`;
- enemy position becomes `{ "x": 2, "y": 1 }`;
- event log contains two `turn_ended` events and three `turn_started` events including the initial turn start.

## Rule Proven

When turn order wraps from the last living unit back to an earlier unit, the combat round increments.

