# 067 Terrain Movement Costs

Status: planned
Date: 2026-07-14

## Purpose

Make movement points care about authored terrain instead of treating every walkable tile as the same cost.

This should build directly on slice 066: encounters can now reference generated Tiled map JSON through `map_path`, so terrain costs must be resolved from the same map data that renders the sandbox.

## Proposed Rules

- `floor` costs 1 MP to enter.
- `cover_low` costs 1 MP to enter.
- `highground` costs 2 MP to enter unless a later unit trait reduces it.
- `blocked` cannot be entered.
- Movement pathfinding chooses the cheapest legal path, not only the fewest tile steps.
- `unit_moved` should expose both `path` and total `mp_spent`.
- Rejections should distinguish:
  - `destination_not_walkable`;
  - `destination_unreachable`;
  - `not_enough_mp`.

## Acceptance

- A unit with enough MP can enter highground and spends the increased cost.
- A unit without enough MP cannot enter a legal-but-too-expensive destination.
- Enemy AI pathfinding can choose a longer floor route over a shorter expensive route when that preserves enough MP.
- Python and Godot combat slice validation cover the same scenario.
- Combat sandbox preview shows the resulting MP cost before the player clicks.

## Notes

Keep this small. Do not add stamina, traits, mud, water, elevation advantage changes, or per-unit terrain modifiers in this slice. The goal is only to make MP and terrain data talk to each other cleanly.
