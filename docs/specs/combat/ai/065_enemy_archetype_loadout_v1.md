# 065 Enemy Archetype Loadout V1

Status: implemented
Date: 2026-07-15

## Intent

Move repeated enemy setup into reusable archetypes.

Enemy archetypes let encounters reference a role-style template before AI command selection and combat resolution.

## Rules

- Encounters may define `enemy_archetypes`.
- An enemy unit may reference an archetype with `archetype_id`.
- Archetype data is applied before:
  - AI command selection;
  - command validation;
  - command resolution.
- An archetype may provide:
  - available actions;
  - learned actions;
  - loadout.
- Unit-local data may still provide stats, resources, position, team, and explicit overrides.
- Archetype-provided loadout uses the same `item_profiles + loadout` rules as player units.
- AI must see actions granted by archetype loadout when choosing commands.
- Resolved events should still report the concrete action profile used by the command.
- Missing archetypes should fail validation or reject setup through the encounter-loading path rather than producing silent default behavior.

## Acceptance Proof

Implemented by:

```text
docs/specs/combat/slices/065_enemy_archetype_loadout.md
```

## Non-Goals

- final enemy roster;
- enemy leveling;
- procedural archetype generation;
- behavior trees;
- role-aware tactical scoring beyond current AI action selection.
