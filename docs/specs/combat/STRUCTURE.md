# Combat Spec Structure

Status: active  
Date: 2026-07-14

## Intent

Combat specs are organized by tactical domain, while executable slices remain in one chronological folder.

This keeps rule ownership clear without scattering acceptance history across many folders.

## Folder Map

```text
docs/specs/combat/
  README.md
  STRUCTURE.md
  overview/
    Core combat loop, event log, replay stability.
  grid/
    Grid rules, terrain, line of sight, cover.
  turns/
    Turn order, rounds, active unit rules.
  actions/
    Generic action rules such as move, defend, end turn.
  attacks/
    Melee/ranged attack rules, damage, statuses.
  hit_resolution/
    Hit chance, accuracy, evasion, future hit modifiers.
  equipment/
    Loadout, item slots, equipment-granted actions.
  weapons/
    Weapon profile rules: range, AP cost, base hit chance, damage modifiers.
  ai/
    Enemy decision rules and tactical behavior.
  slices/
    Executable acceptance scenarios, kept chronological.
  milestones/
    Human-readable implementation summaries and next steps.
```

## Rules

- Put rule specs in the domain folder that owns the mechanic.
- Keep `slices/` flat and numbered; slices are implementation proofs, not rule ownership folders.
- When a rule spans domains, place it where the calculation is owned and link to related specs.
- Update `README.md` when adding a new rule spec.
- Update the current milestone after a meaningful combat commit.

## Current Domain Boundaries

- `overview/`: combat lifecycle and event log contract.
- `grid/`: position, terrain, line of sight, cover.
- `turns/`: active unit, turn order, round progression.
- `actions/`: action availability, command shape, movement, defend, end turn.
- `attacks/`: attack action definitions and damage/status effects.
- `hit_resolution/`: hit chance formula and modifiers.
- `equipment/`: equipped items, slots, and action availability from loadout.
- `weapons/`: weapon profile ownership for attack tuning data.
- `ai/`: enemy command selection and tactical behavior.
