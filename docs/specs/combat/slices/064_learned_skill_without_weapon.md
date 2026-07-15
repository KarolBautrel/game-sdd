# 064 Learned Skill Without Weapon

Status: implemented
Date: 2026-07-14

## Acceptance

This slice proves the learned-action-without-weapon scenario. The owning action rules live in:

```text
docs/specs/combat/actions/064_learned_actions_v1.md
```

- units may define `learned_actions`;
- learned actions are separate from item-granted actions;
- player does not list `power_strike` in legacy `available_actions`;
- player has no weapon loadout;
- player has `learned_actions: ["power_strike"]`;
- `power_strike` resolves from `action_profiles.power_strike`;
- player AP changes from `2` to `0`;
- enemy HP changes from `10` to `5`;
- player gains `skill_cooldown` for `power_strike`.
