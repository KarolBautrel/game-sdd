# Stable Dungeon Entry Selection V1

Status: implemented
Owner: dungeon overview

## Purpose

Move dungeon entry source selection out of debug-only presentation state and into a small stable entry payload that can later be provided by world map, progression, or test harness code.

## Rules

- Dungeon entry selection is represented by a dictionary payload.
- The payload records:
  - `source`: `authored` or `generated`;
  - `dungeon_path` for authored dungeon data;
  - `generated_seed` for generated drafts;
  - `generated_difficulty` for generated drafts.
- Invalid or missing source values fall back to authored Old Mine.
- Generated difficulty is clamped to the supported first beta range, `1..3`.
- Authored entry clears generated seed to `0`.
- The same generated entry payload must produce the same dungeon graph.
- Debug preparation controls may still edit the payload, but the dungeon data must be produced from the payload contract.

## Current Scope

This is the first contract layer only. It does not yet add a world-map dungeon selector, party progression gate, or persistent run setup service.

## Proof

- `scripts/domain/dungeon_entry_selection_tests.gd`
- `scripts/presentation/dungeon_exploration_hud_tests.gd`
