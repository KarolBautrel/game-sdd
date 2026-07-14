# 030 Enemy AI Ranged V1

Status: implemented  
Date: 2026-07-14

## Intent

Enemy AI ranged v1 lets an enemy shoot instead of walking when a legal ranged target already exists.

## Decision Order

When the active unit is an enemy:

1. If a living player is adjacent and `basic_attack` is available, use `basic_attack`.
2. Otherwise, if a living player is a legal `ranged_attack` target, use `ranged_attack`.
3. Otherwise, move one legal step toward the nearest living player.
4. Otherwise, use `end_turn`.

## Legal Ranged Target

The target must pass the normal resolver rules for `ranged_attack`:

- actor is active;
- actor has at least 1 AP;
- actor has `ranged_attack` in `available_actions`;
- target is a living enemy;
- target is within range 3;
- line of sight is clear.

## Target Selection

If multiple legal ranged targets exist:

- choose the closest target by Chebyshev distance;
- break ties by unit id.

## Deferred

- AI weighing ranged attack against highground or cover movement;
- target priority by HP or threat;
- avoiding low hit chance shots;
- ammunition and reload behavior.
