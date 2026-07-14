# 014 Victory Last Enemy Defeated

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that combat ends with `victory` when the last enemy is defeated.

## Scenario

Player is active and attacks the only enemy. Enemy HP reaches 0.

## Expected Result

- enemy HP becomes `0`;
- event log contains `unit_defeated`;
- event log contains `combat_ended`;
- `combat_ended.result` is `victory`;
- final combat result is `victory`.

