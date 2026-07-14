# 022 Line Of Sight

Status: specified  
Date: 2026-07-14

## Intent

Line of sight determines whether a unit can target another unit or tile with ranged actions.

## Scope V1

- `ranged_attack` requires line of sight.
- Line of sight is traced from attacker tile center to target tile center.
- Attacker and target tiles do not block their own line.
- Intermediate `blocked` tiles block line of sight.
- Units do not block line of sight in v1.
- `floor` and `highground` do not block line of sight.
- A blocked line rejects the command with `target_not_visible`.

## Deferred

- units blocking line of sight;
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

### Clear ranged attack

- Given no `blocked` tile lies between attacker and target
- When the attacker performs `ranged_attack`
- Then hit chance resolution may continue
