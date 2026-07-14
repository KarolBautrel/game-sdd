# 025 Accuracy And Evasion

Status: specified  
Date: 2026-07-14

## Intent

Accuracy and evasion make hit chance depend on the units involved, not only on the selected action.

## Design Direction

The long-term hit chance formula is:

```text
final_hit_chance =
  base action or weapon chance
  + attacker accuracy
  + weapon modifiers
  + status modifiers
  + terrain modifiers
  - target evasion
  - shield or equipment modifiers
  - cover modifiers
```

## Scope V1

Only the unit stat part is implemented:

```text
final_hit_chance = base_hit_chance + attacker.accuracy - target.evasion
```

Rules:

- `accuracy` increases the attacker's hit chance.
- `evasion` decreases the attacker's hit chance.
- both stats are integers;
- omitted stats default to 0;
- final hit chance is clamped to 10-95;
- `basic_attack` still always hits;
- `ranged_attack` uses the final hit chance.

## Event Log

`hit_roll_resolved` records the full minimal breakdown:

- `base_hit_chance`
- `accuracy_modifier`
- `evasion_modifier`
- `hit_chance`
- `roll`
- `outcome`

## Deferred

- weapon accuracy bonus or penalty;
- armor accuracy penalty;
- shield evasion or block modifier;
- highground modifier;
- cover modifier;
- distance modifier;
- status and trait modifiers.

