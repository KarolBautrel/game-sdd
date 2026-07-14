# 044 Ranged Intercept

Status: implemented  
Date: 2026-07-14

## Intent

Ranged intercept makes units on the firing line tactically relevant without making them hard line-of-sight blockers.

## Scope V1

- Only `ranged_attack` can be intercepted.
- `blocked` terrain still blocks line of sight and rejects the command.
- Living units on the line between attacker and original target can intercept.
- Attacker and original target are ignored as intercept candidates.
- Defeated units do not intercept.
- If multiple units are on the line, the one closest to the original target is checked.
- Intercept is resolved after AP is spent and `action_performed` is emitted.
- If intercept succeeds, the blocker becomes the final target for hit chance and damage.
- If intercept fails, the original target remains the final target.

## Chance Formula

Progress is stored as an integer percentage:

```text
progress = round(distance(attacker, blocker) * 100 / distance(attacker, original_target))
intercept_chance = clamp(20 + round(60 * progress / 100), 20, 80)
```

## Event

`shot_intercept_resolved` contains:

- `command_id`
- `actor_id`
- `original_target_unit_id`
- `blocker_unit_id`
- `final_target_unit_id`
- `blocker_progress`
- `intercept_chance`
- `roll`
- `outcome`

`outcome` is `intercepted` or `clear`.

## Deferred

- AI avoiding risky friendly intercept shots;
- multiple intercept checks along one shot;
- projectile arcs;
- friendly fire policy controls;
- UI preview before confirming ranged attack.
