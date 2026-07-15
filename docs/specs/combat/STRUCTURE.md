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
  presentation/
    Combat UI, board rendering, previews, animation, and sandbox-to-production presentation rules.
  slices/
    Executable acceptance scenarios, kept chronological.
  milestones/
    Human-readable implementation summaries and next steps.
```

## Rules

- Every combat behavior change must have an owning domain/presentation spec, a chronological slice acceptance scenario, and a named test/validator proof.
- Put rule specs in the domain folder that owns the mechanic.
- Keep `slices/` flat and numbered; slices are implementation proofs, not rule ownership folders.
- A slice may introduce an acceptance scenario, but durable rules must also be captured in the owning domain spec.
- If a new mechanic has no owning domain spec, create that spec before or alongside the slice.
- Link slices for new mechanics back to their owning domain spec.
- If a presentation behavior cannot be proven by current domain slice tests, add a helper/unit validator or explicitly document the manual verification gap in the slice and milestone.
- When a rule spans domains, place it where the calculation is owned and link to related specs.
- Update `README.md` when adding a new rule spec.
- Update the current milestone after a meaningful combat commit.
- When a milestone has an ordered queue, complete the first unfinished item before starting later items unless the user explicitly reprioritizes.
- Mark a queued milestone item complete only when owner spec, slice, implementation, and named validation/test proof are all present.

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
- `presentation/`: UI layout, target/move preview, board rendering, visual preparation, and animation behavior.
