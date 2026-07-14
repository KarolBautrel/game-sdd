# 057 Weapon Grants Power Strike

Status: implemented  
Date: 2026-07-14

## Acceptance

- player does not list `power_strike` in legacy `available_actions`;
- player equips two-handed `greatsword`;
- `greatsword` grants `power_strike`;
- `power_strike` is accepted;
- attack spends 2 AP and damages the enemy;
- `skill_cooldown` is applied with 3 remaining turns;
- `action_performed` records item-derived profile id `greatsword_power_strike`.
