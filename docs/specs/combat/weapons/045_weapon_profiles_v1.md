# 045 Weapon Profiles V1

Status: implemented  
Date: 2026-07-14

## Intent

Move basic attack tuning out of hardcoded resolver constants and into encounter data.

## Rules

- Encounters may define `weapon_profiles`.
- A unit may define `equipped_weapon_id`.
- If a unit has no equipped weapon, legacy fallback attack values are used.
- If a unit has an equipped weapon, that weapon profile controls:
  - supported `action_id`;
  - attack range;
  - AP cost;
  - optional ranged base hit chance;
  - optional damage bonus.
- If a unit has an equipped weapon for a different action, that weapon profile is ignored for this action and legacy fallback attack values are used.
- If a unit references a missing weapon profile, the command is rejected with `missing_weapon_profile`.

## Non-Goals

- inventory;
- weapon swapping;
- durability;
- rarity;
- loot.
