# 044 Ranged Intercept By Unit

Status: implemented  
Date: 2026-07-14

## Intent

Verify that a living unit on the shot line can intercept a ranged attack instead of hard-blocking line of sight.

## Rule

- `blocked` terrain still blocks line of sight.
- Living units on the shot line do not reject the command.
- A living unit between attacker and target can intercept the shot.
- Attacker and original target do not intercept their own shot.
- Defeated units do not intercept.
- If several units can intercept, the unit closest to the original target is checked.

## Intercept Chance

The chance depends on blocker progress from attacker to original target:

```text
progress = distance(attacker, blocker) / distance(attacker, original_target)
intercept_chance = clamp(20 + round(60 * progress), 20, 80)
```

The event stores progress as an integer percentage.

## Expected Result

- player shoots at `unit_enemy_001`;
- `unit_enemy_002` stands near the original target on the shot line;
- intercept chance is 60%;
- intercept roll is 34;
- `unit_enemy_002` becomes the final target;
- hit roll succeeds;
- `unit_enemy_002` takes damage;
- `unit_enemy_001` is not damaged.
