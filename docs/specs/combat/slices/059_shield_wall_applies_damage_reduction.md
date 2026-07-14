# 059 Shield Wall Applies Damage Reduction

Status: implemented
Date: 2026-07-14

## Acceptance

- player equips `wooden_shield` in `loadout.off_hand`;
- player equips `chainmail` in `loadout.armor`;
- `wooden_shield` grants `shield_wall`;
- player performs `shield_wall`;
- `shield_wall` applies a status with `damage_reduction: 2`;
- player ends turn;
- enemy attacks player;
- raw damage is 4;
- armor reduction and shield wall reduction stack to `damage_reduction: 4`;
- final damage is clamped to minimum 1;
- player HP changes from 10 to 9;
- `damage_applied` records `damage_reduction: 4` and `armor_id: "chainmail"`.
