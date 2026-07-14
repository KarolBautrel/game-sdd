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
  - `base_hit_chance + attacker.accuracy - target.evasion`
- `accuracy` and `evasion` default to 0 when omitted.
- Final hit chance is clamped to 10-95.
- Roll range is 1-100.
- A roll hits when `roll <= hit_chance`.
- The roll is deterministic from encounter seed and command id.
- The resolver emits `hit_roll_resolved` before damage is applied.
- A hit continues to `damage_applied`.
- A miss does not emit `damage_applied`.
- AP is spent whether the attack hits or misses.

## Event Shape

`hit_roll_resolved` contains:

- `command_id`
- `actor_id`
- `target_unit_id`
- `roll`
- `base_hit_chance`
- `accuracy_modifier`
- `evasion_modifier`
- `hit_chance`
- `outcome`

`outcome` is either `hit` or `miss`.

## Deferred

- weapon accuracy modifiers;
- equipment modifiers;
- shield modifiers;
- status modifiers;
- cover modifiers;
- distance modifiers;
- highground modifiers;
- graze;
- critical hit;
- UI preview before command confirmation.
