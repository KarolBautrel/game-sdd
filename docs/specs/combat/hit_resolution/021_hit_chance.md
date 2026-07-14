# 021 Hit Chance

Status: specified  
Date: 2026-07-14

## Intent

Hit chance resolves whether an attack hits or misses.

## Scope V1

- `ranged_attack` uses hit chance.
- `basic_attack` still always hits.
- Base ranged hit chance is 70%.
- Final hit chance uses:
  - `base_hit_chance + attacker.accuracy - target.evasion + terrain_modifier + cover_modifier`
- `accuracy` and `evasion` default to 0 when omitted.
- `terrain_modifier` is 10 when the attacker uses `ranged_attack` from `highground`; otherwise it is 0.
- `cover_modifier` is -20 when the ranged target stands on `cover_low`; otherwise it is 0.
- Final hit chance is clamped to 10-95.
- Roll range is 1-100.
- A roll hits when `roll <= hit_chance`.
- The roll is deterministic from encounter seed and command id.
- The resolver emits `hit_roll_resolved` before damage is applied.
- A hit continues to `damage_applied`.
- A miss does not emit `damage_applied`.
- AP is spent whether the attack hits or misses.
- Ranged intercept, when present, resolves before `hit_roll_resolved`; see `044_ranged_intercept.md`.

## Event Shape

`hit_roll_resolved` contains:

- `command_id`
- `actor_id`
- `target_unit_id`
- `roll`
- `base_hit_chance`
- `accuracy_modifier`
- `evasion_modifier`
- `terrain_modifier`
- `cover_modifier`
- `hit_chance`
- `outcome`

`outcome` is either `hit` or `miss`.

## Deferred

- weapon accuracy modifiers;
- equipment modifiers;
- shield modifiers;
- status modifiers;
- distance modifiers;
- graze;
- critical hit;
- UI preview before command confirmation.
