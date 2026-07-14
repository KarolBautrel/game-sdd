# 008 Enemy AI Adjacent Attack

Status: verified  
Date: 2026-07-14

## Intent

This executable scenario proves that enemy AI v0 can choose `basic_attack` when an enemy unit is active and adjacent to a player unit.

## Scenario

Enemy is the active unit. Player is adjacent. Enemy AI chooses and resolves `basic_attack`.

## Expected Result

- generated command action is `basic_attack`;
- player HP is reduced from `10` to `8`;
- enemy AP is reduced from `1` to `0`;
- event log contains `action_performed` and `damage_applied`;
- combat remains `in_progress`.

## AI Rule Proven

Enemy AI v0 priority:

1. If adjacent to a living player unit and has AP, use `basic_attack`.
2. Otherwise, later slices will add movement toward the player.
3. Otherwise, later slices will use `end_turn`.

