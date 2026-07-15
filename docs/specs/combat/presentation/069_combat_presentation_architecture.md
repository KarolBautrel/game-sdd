# 069 Combat Presentation Architecture

Status: active
Date: 2026-07-15

## Purpose

Combat presentation should move toward production-shaped UI and rendering while keeping the debug scene useful as the fastest tactical sandbox.

The sandbox controller may orchestrate the screen, but reusable presentation concerns should live in dedicated modules.

## Ownership

- Domain combat rules live in `scripts/domain/combat_resolver.gd`.
- Presentation may request simulated outcomes for previews, but it must not duplicate legality rules.
- `combat_debug.gd` remains the sandbox controller.
- Text formatting, action visibility, scenario selection, and unit art lookup should be extracted into presentation helpers.
- Board, tile, unit, preview, action bar, event feed, and animation rendering should be extracted when they become large enough to own independently.

## Implemented Helpers

- `scripts/presentation/combat/combat_text.gd`
- `scripts/presentation/combat/combat_unit_art.gd`
- `scripts/presentation/combat/combat_action_model.gd`
- `scripts/presentation/combat/combat_scenario_catalog.gd`
- `scripts/presentation/combat/combat_floating_text.gd`
- `scripts/presentation/combat/combat_targeting_preview.gd`
- `scripts/presentation/combat/combat_unit_visual_state.gd`

## Runtime Preparation

- Static terrain/background assets should be prepared when an encounter loads.
- Reused unit textures and common visual states should be cached during presentation preparation.
- Dynamic overlays and unit nodes should update in place instead of rebuilding the full board every render.
- Per-action preview data should be cached when selected action or state changes.

## Still To Extract

- Board/tile renderer.
- Unit node renderer.
- Preview overlay renderer.
- Action skillbar view.
- Event feed view.
- Animation controller and walk-cycle state machine.

## Acceptance

- The combat sandbox scene still loads after refactors.
- Python and Godot combat validation still pass.
- Presentation changes are documented here first, then backed by executable slices or debug scenarios when behavior needs regression coverage.
