# 022 Line Of Sight

Status: specified  
Date: 2026-07-14

## Intent

Line of sight determines whether a unit can target another unit or tile with ranged actions.

## Scope V1

- `ranged_attack` and `aimed_shot` require the same terrain line of sight.
- Line of sight is traced from attacker tile center to target tile center.
- Attacker and target tiles do not block their own line.
- Intermediate `blocked` tiles block line of sight.
- Units do not hard-block line of sight in v1.
- Living units on the shot line may intercept ranged attacks; see `../hit_resolution/044_ranged_intercept.md`.
- `floor` and `highground` do not block line of sight.
- A blocked line rejects the command with `target_not_visible`.

## Deferred

- AI line-of-fire risk evaluation;
- low cover and high cover;
- line-of-sight preview overlay;
- highground line-of-sight exceptions;
- corner peeking;
- projectile arcs.

## Acceptance Criteria

### Blocked ranged attack

- Given an attacker and target are in ranged attack range
- And a `blocked` tile lies between them
- When the attacker performs `ranged_attack`
- Then the command is rejected with `target_not_visible`
- And AP and HP do not change
- The same rejection applies to `aimed_shot`, including equipment-granted and
  fallback action profiles; rejection spends no AP, adds no cooldown, and does
  not consume a hit/intercept roll.

### Clear ranged attack

- Given no `blocked` tile lies between attacker and target
- When the attacker performs `ranged_attack`
- Then hit chance resolution may continue

## Regression proof (2026-11-05)

Desktop Painted Six play exposed an aimed shot passing through terrain that
rejected a basic shot. Slice104 and `combat_playtest_regression_tests.gd` /
`tests/test_combat_playtest_regressions.py` cover shared preview/resolution
legality, endpoint exclusions, clear lines and atomic rejection.
