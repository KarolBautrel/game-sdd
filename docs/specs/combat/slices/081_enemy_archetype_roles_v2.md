# 081 Enemy Archetype Roles V2

Status: implemented
Date: 2026-07-15

## Acceptance

This slice proves that combat encounters can use reusable role archetypes for both humanoids and beasts. The owning AI rules live in:

```text
docs/specs/combat/ai/081_enemy_archetype_roles_v2.md
```

- the encounter defines `raider_swordsman`, `raider_shieldman`, `raider_archer`, `beast_stalker`, and `beast_bruiser`;
- the showcase encounter uses archetype references on enemies instead of inline enemy action/loadout setup;
- humanoid archetypes define role-compatible `visual_pool` values;
- units without explicit `visual` receive a deterministic visual from their archetype pool;
- unit-local explicit `visual` remains an override when present;
- `raider_archer` receives bow-granted `ranged_attack` through archetype loadout;
- `beast_stalker` receives `basic_attack` through a natural-weapon loadout;
- AI chooses `ranged_attack` for the archer when a legal visible target is in range;
- AI chooses `basic_attack` for an adjacent beast stalker;
- AI chooses `move` for a distant swordsman.

## Manual Gap

There is no screenshot harness yet for verifying how every archetype reads in the debug scene. Visual confirmation remains a manual playthrough gap for later UI automation.
