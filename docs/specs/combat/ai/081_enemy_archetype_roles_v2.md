# 081 Enemy Archetype Roles V2

Status: implemented
Date: 2026-07-15

## Intent

Define reusable enemy combat roles that dungeon encounters can reference without repeating action and loadout setup on every unit.

This builds on `ai/065_enemy_archetype_loadout_v1.md`.

## Rules

- Encounters may define named enemy role archetypes in `enemy_archetypes`.
- Humanoid combat archetypes should cover at least:
  - `raider_swordsman`: melee weapon role;
  - `raider_shieldman`: tougher melee role with shield access;
  - `raider_archer`: ranged weapon role.
- Beast combat archetypes should cover at least:
  - `beast_stalker`: fast melee beast role for wolves, spiders, and similar low-profile monsters;
  - `beast_bruiser`: heavier melee beast role for boars, hounds, and similar larger beasts.
- Humanoid archetypes use item loadouts for weapons and shields.
- Beast archetypes may use natural-weapon item profiles, such as fangs or claws, through the same `loadout` contract as humanoids.
- Units keep unit-local stats, resources, position, team, visual art, and explicit overrides.
- Archetype metadata such as `role`, `family`, and `display_name` is allowed for validators, authoring tools, and debug UI.
- AI action choice remains driven by the concrete actions made available after archetype application:
  - melee roles close distance or attack adjacent players;
  - ranged roles shoot legal visible targets before moving;
  - beast roles attack adjacent players or move toward them using the same pathing rules.

## Acceptance Proof

Implemented by:

```text
docs/specs/combat/slices/081_enemy_archetype_roles_v2.md
```

## Non-Goals

- final monster taxonomy;
- unique AI behavior trees per monster species;
- loot, XP, or dungeon spawn-table balancing;
- new combat actions for poison, webbing, pounce, or fear.
