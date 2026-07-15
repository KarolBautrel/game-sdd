# 063 Aimed Shot From Bow

Status: implemented
Date: 2026-07-14

## Acceptance

This slice proves the `aimed_shot` equipment-granted special attack scenario. The owning action rules live in:

```text
docs/specs/combat/actions/063_aimed_shot_v1.md
```

- `aimed_shot` can be granted by a bow item profile;
- player does not list `aimed_shot` in legacy `available_actions`;
- `hunting_bow` grants `ranged_attack` and `aimed_shot`;
- `aimed_shot` costs `2 AP`;
- `aimed_shot` uses bow profile `base_hit_chance 90`, `damage_bonus 2`, and `cooldown_turns 2`;
- hit roll succeeds deterministically;
- player AP changes from `2` to `0`;
- enemy HP changes from `10` to `5`;
- player gains `skill_cooldown` for `aimed_shot`.
