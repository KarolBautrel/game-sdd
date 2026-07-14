# Combat Presentation Modules

`scripts/presentation/combat_debug.gd` is the sandbox controller. It owns current combat state, command submission, and high-level render orchestration.

New production-facing presentation code should live in this folder instead of growing the root sandbox script.

## Current Modules

- `combat_text.gd` formats action labels, event feed lines, rejection labels, unit display names, and status text.
- `combat_unit_art.gd` resolves unit visual state, facing, character asset paths, fallback paths, and cached textures.
- `combat_action_model.gd` decides which actions are visible in the UI based on the current combat state, resources, cooldowns, and loadout-granted actions.
- `combat_scenario_catalog.gd` owns sandbox scenario options and encounter paths.

## Direction

The long-term combat screen should keep this shape:

- `CombatResolver` remains the only source of combat legality and results.
- A combat controller submits commands and receives events.
- Board, unit, preview, action panel, and event feed rendering live in separate view/controller scripts.
- Animation logic should move toward a unit animation controller/state machine instead of one-off flags in the sandbox root.

Do not put new rendering systems, asset lookup rules, action visibility rules, or event formatting back into `combat_debug.gd` unless the change is explicitly throwaway debug code.
