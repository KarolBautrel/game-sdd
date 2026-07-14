# 058 Armor Reduces Damage

Status: implemented  
Date: 2026-07-14

## Acceptance

- enemy has `basic_attack`;
- player equips `chainmail` in `loadout.armor`;
- `chainmail` is an armor item profile with `armor_reduction: 2`;
- enemy attacks player;
- raw damage is 4;
- armor reduction lowers final damage to 2;
- player HP changes from 10 to 8;
- `damage_applied` records `damage_reduction: 2` and `armor_id: "chainmail"`.
