# 053 Loadout And Item Profiles V1

Status: implemented  
Date: 2026-07-14

## Intent

Move combat action availability toward equipment-driven data.

This is the first step toward real inventory rules without building the full inventory system yet.

## Rules

- Encounters may define `item_profiles`.
- A unit may define a `loadout` with:
  - `main_hand`;
  - `off_hand`;
  - `armor`.
  - presentation010 also permits `helmet` and `boots`; their catalogue profiles
    grant no actions or hidden combat bonuses. Existing legacy three-slot data
    remains valid. Managed campaign handoff carries all five matching item slots.
- An item profile defines:
  - item `id`;
  - equipment `slot`;
  - optional `two_handed`;
  - `grants_actions`;
  - per-action `action_profiles`.
- An action is available if it exists in either:
  - the unit's legacy `available_actions`;
  - an equipped item's `grants_actions`.
- Equipped item action profiles override fallback combat values for their granted action.
- A two-handed main-hand item cannot be used together with an off-hand item.
- Invalid two-handed plus off-hand loadout rejects equipment-granted actions with `invalid_loadout_two_handed_with_off_hand`.
- If a unit has no bow item granting `ranged_attack`, `ranged_attack` is rejected with `action_not_available`.
- If a unit has no shield item granting `shield_wall`, `shield_wall` is rejected with `action_not_available`.

## Compatibility

- Legacy `equipped_weapon_id` and `weapon_profiles` remain supported for current slices.
- New combat data should prefer `item_profiles + loadout`.

## Non-Goals

- inventory screen;
- swapping equipment during combat;
- loot generation;
- durability;
- rarity;
- armor mitigation rules.
