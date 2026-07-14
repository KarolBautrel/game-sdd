# 012 Enemy AI No AP End Turn

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that enemy AI v0 ends its turn when it has 0 AP.

## Scenario

Enemy is active and adjacent to the player, but enemy AP is `0`.

## Expected Result

- generated command action is `end_turn`;
- active unit becomes `unit_player_001`;
- enemy AP remains `0`;
- player AP refreshes to max AP;
- event log contains `turn_ended` and `turn_started`.

## Rule Proven

Enemy AI cannot attack or move without AP and must pass control instead.

