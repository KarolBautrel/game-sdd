# 011 Spatial Dungeon Map V1

Status: active
Date: 2026-07-16

## Intent

Make the current abstract graph read more like an authored spatial dungeon map.

This is a presentation pass over the existing room graph data. It does not replace the graph with a tile map yet.

## Rules

- Room cards show a room-type marker.
- Room cards expose authored map coordinates through presentation text.
- The current room detail panel shows the room position.
- Exit labels may include stateful destination hints such as locked, danger, reward, or exit.
- The underlying authored graph and movement rules remain unchanged.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/012_spatial_dungeon_map_v1.md
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- tile-map exploration;
- camera panning;
- fog of war;
- final dungeon art.
