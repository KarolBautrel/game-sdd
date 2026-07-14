# 012 Combat Slice 07 End Turn

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that `end_turn` advances active unit control to the next living unit.

## Scenario

Player is active. Turn order is `unit_player_001`, then `unit_enemy_001`. Player performs `end_turn`.

## Expected Result

- active unit becomes `unit_enemy_001`;
- event log contains `action_performed`, `turn_ended`, and `turn_started`;
- combat remains `in_progress`.

