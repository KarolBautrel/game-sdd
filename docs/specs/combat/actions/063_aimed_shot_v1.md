# 063 Aimed Shot V1

Status: implemented
Date: 2026-07-15

## Intent

Define the first ranged special attack that can be granted by equipment.

`aimed_shot` proves that item profiles can grant more than a basic weapon action while still using the same resolver-owned action, hit, damage, AP, and cooldown rules.

## Rules

- `aimed_shot` is a targeted ranged special action.
- `aimed_shot` may be granted by an equipped item profile through `grants_actions`.
- `aimed_shot` uses an action profile from the granting item when available.
- The item action profile may define:
  - AP cost;
  - range;
  - base hit chance;
  - damage bonus;
  - cooldown turns.
- `aimed_shot` uses ranged target validation, including range and line of sight.
- `aimed_shot` resolves hit chance through the normal hit resolution pipeline.
- `aimed_shot` applies normal weapon/profile damage calculation on hit.
- If the profile defines `cooldown_turns`, using `aimed_shot` applies `skill_cooldown` to the actor.
- A unit does not need legacy `available_actions` for `aimed_shot` when the equipped item grants it.
- A missing granted action profile falls back only when the action has a valid domain fallback. Otherwise the command is rejected through the normal unavailable-action path.

## Acceptance Proof

Implemented by:

```text
docs/specs/combat/slices/063_aimed_shot_from_bow.md
```

## Non-Goals

- full skill tree;
- projectile animation;
- area targeting;
- ammunition;
- inventory UI.
