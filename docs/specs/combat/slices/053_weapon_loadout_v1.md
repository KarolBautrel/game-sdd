# 053 Weapon Loadout V1

Status: implemented  
Date: 2026-07-14

## Acceptance

- player does not list `basic_attack` in legacy `available_actions`;
- player equips `iron_sword` in `main_hand`;
- `iron_sword` grants `basic_attack`;
- `basic_attack` is accepted;
- attack spends AP and damages the enemy;
- `action_performed` records item-derived profile id `iron_sword_basic_attack`.
