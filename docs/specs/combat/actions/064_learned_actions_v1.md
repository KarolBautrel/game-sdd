# 064 Learned Actions V1

Status: implemented
Date: 2026-07-15

## Intent

Allow units to know combat actions independently from equipment.

Learned actions are the first step toward character progression while keeping action resolution data-driven and compatible with item-granted actions.

## Rules

- A unit may define `learned_actions`.
- `learned_actions` is separate from legacy `available_actions`.
- `learned_actions` is separate from item-granted actions.
- An action is available when it exists in any of:
  - legacy `available_actions`;
  - the unit's `learned_actions`;
  - equipped item `grants_actions`.
- Learned actions may resolve from encounter-level `action_profiles`.
- An action profile may define AP cost, range, hit chance, damage bonus, and cooldown data when the action supports those fields.
- Learned actions still use the same resolver-owned legality and outcome rules as any other action.
- Learned actions may apply `skill_cooldown` if their resolved profile defines cooldown turns.
- Equipment-provided action profiles may override fallback values for item-granted actions, but learned actions without equipment should resolve from the encounter-level action profile or the action's domain fallback.

## Acceptance Proof

Implemented by:

```text
docs/specs/combat/slices/064_learned_skill_without_weapon.md
```

## Non-Goals

- skill tree UI;
- experience points;
- character class progression;
- permanent save data;
- respec rules.
