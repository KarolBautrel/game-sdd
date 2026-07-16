# 017 Dungeon Debuff Table V1

Status: implemented
Date: 2026-07-16

## Intent

Define the future dungeon debuff catalogue and outcome weighting model.

Dungeon hazards need consistent consequences. This spec records the first planned debuff map so future hazards do not invent ad hoc effects.

## Planned Debuffs

Initial debuff candidates:

- `bleeding`: HP loss over time or combat-start status;
- `poisoned`: HP loss over time, possible accuracy/evasion penalty;
- `limping`: reduced movement points, target starting value `-50% MP`;
- `bruised`: reduced max HP or temporary defense penalty;
- `fatigued`: lower initiative, lower max AP/MP, or stress/morale pressure later;
- `shaken`: reduced accuracy or increased stress gain;
- `strained_back`: reduced carry/supply efficiency later, temporary combat penalty now;
- `burned`: HP loss, possible light/oil mishap consequence.

Exact combat mappings are future work.

## Outcome Weighting Direction

Hazards may define weighted outcomes.

Example design language:

```text
rubble_without_pickaxe:
- 45% slow passage only
- 30% bruised
- 15% limping
- 10% ambush noise

trap_without_tools:
- 30% bleeding
- 25% poisoned
- 25% limping
- 20% HP loss only
```

Final percentages should be data-driven and testable.

## Combat Bridge Direction

Some dungeon debuffs should later translate into combat state:

- `bleeding` -> existing combat bleeding status if compatible;
- `poisoned` -> future combat poison status;
- `limping` -> reduced starting MP or movement_points modifier;
- `fatigued` -> initiative/AP/MP penalty;
- `shaken` -> accuracy or morale/stress penalty.

Dungeon owns the debuff source. Combat receives prepared modifiers/statuses.

## Persistence Direction

Early implementation may keep debuffs only in dungeon run state. Later versions may persist them to party/character state after the run.

Applied dungeon debuffs and per-target effects must persist across ordinary dungeon movement, including backtracking and entering pending corridor events. Traversal does not heal, expire, or clear negative effects by itself. Effects may be removed only by an explicit future recovery/removal system, end-of-run cleanup, or debug/run reset flow.

## Implementation Notes

Implemented first-pass support in:

```text
resources/data/dungeon_debuffs/base_dungeon_debuffs.json
resources/schemas/dungeon_debuff.schema.json
scripts/domain/dungeon_state_model.gd
scripts/presentation/dungeon_debug.gd
tools/validators/validate_all.py
```

Dungeon debuff ids now live in validated data. Dungeon hazard consequences that use `apply_debuff` are validated against that catalogue. Runtime dungeon state stores active debuffs in `active_debuffs` with stack counts, and the debug HUD summarizes them as `Debuffs: <id> x<count>`. The main progress line also names active effects, so the player/debugger can see that they remain active while moving through the dungeon.

The first implemented applied debuff is `bruised`, produced by forcing passage through the rubble corridor without a pickaxe.

## Implementation Timing

Implement before trap tools if traps apply debuffs. It can be implemented after light/oil if light starts with simple numeric modifiers only.

## Non-Goals

- final balance;
- character sheet UI;
- healing/camping system;
- permanent injury system.
