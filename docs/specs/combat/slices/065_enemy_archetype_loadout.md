# 065 Enemy Archetype Loadout

Status: implemented
Date: 2026-07-14

## Acceptance

- encounters may define `enemy_archetypes`;
- enemy units may reference an `archetype_id`;
- archetype actions and loadout are applied before AI command selection and command resolution;
- `skeleton_archer` grants `move` and `end_turn` and equips `shortbow`;
- `shortbow` grants `ranged_attack`;
- enemy unit has no inline `available_actions`;
- AI chooses `ranged_attack` through the archetype-provided loadout;
- player HP changes from `10` to `8`;
- `action_performed.profile_id` is `shortbow_ranged_attack`.
