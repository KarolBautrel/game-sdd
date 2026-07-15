# 069 Combat Presentation Architecture V1

Status: implemented
Date: 2026-07-14

## Purpose

Stop growing the combat sandbox as one large Godot script and start moving toward production-shaped combat presentation.

The sandbox can remain the fastest place to test rules, but it should now be composed from reusable presentation modules that can later be used by the real combat screen.

This slice proves the first presentation extraction step. The owning presentation rules live in:

```text
docs/specs/combat/presentation/069_combat_presentation_architecture.md
```

## Acceptance

- `CombatResolver` remains the source of combat legality and outcomes.
- `combat_debug.gd` remains the sandbox controller, not the owner of every presentation concern.
- Event labels, action labels, status labels, rejection labels, and event feed formatting are handled outside `combat_debug.gd`.
- Unit asset lookup, visual action fallback, facing, and texture caching are handled outside `combat_debug.gd`.
- Action visibility based on resources, cooldowns, learned actions, and loadout-granted actions is handled outside `combat_debug.gd`.
- Sandbox scenario options are handled outside `combat_debug.gd`.
- Target legality preview is prepared before rendering/interacting instead of asking the resolver once for every tile overlay and tooltip lookup.
- Terrain textures, decorations, and common unit visual states are preloaded during presentation preparation for the active encounter.
- The combat sandbox scene still loads after refactor.
- Python and Godot combat validation still pass.

## Implemented Modules

- `scripts/presentation/combat/combat_text.gd`
- `scripts/presentation/combat/combat_unit_art.gd`
- `scripts/presentation/combat/combat_action_model.gd`
- `scripts/presentation/combat/combat_scenario_catalog.gd`

## Still To Extract

- Board/tile renderer.
- Unit node renderer.
- Preview overlay renderer.
- Persistent board nodes that are created during an encounter loading/preparation step and then update overlays/textures in place instead of rebuilding every tile on each render.
- Action panel view.
- Event feed view.
- Animation controller and walk-cycle state machine.

## Notes

This slice is intentionally an architectural slice, not a gameplay rule slice. It keeps the sandbox working while creating a path away from a single monolithic Godot presentation script.
