# 015 Defeat Last Player Defeated

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that combat ends with `defeat` when the last player unit is defeated.

## Scenario

Enemy is active and attacks the only player unit. Player HP reaches 0.

## Expected Result

- player HP becomes `0`;
- event log contains `unit_defeated`;
- event log contains `combat_ended`;
- `combat_ended.result` is `defeat`;
- final combat result is `defeat`.

