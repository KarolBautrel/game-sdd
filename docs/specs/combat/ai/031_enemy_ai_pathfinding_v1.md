# 031 Enemy AI Pathfinding V1

Status: implemented  
Date: 2026-07-14

## Intent

Enemy AI pathfinding v1 replaces naive "step closer" movement with deterministic route search.

## Rule

When an enemy wants to move toward a living player:

1. Find a path through legal walkable tiles.
2. Treat living units as occupied path blockers.
3. Treat the enemy's current tile as legal.
4. Stop when the path reaches any tile adjacent to the target.
5. Move one step along that path.

Diagonal movement cannot cut through blocked corners. If the move is diagonal, both orthogonal side tiles must be walkable.

## Path Search

- The search uses 8-way movement, matching current movement rules.
- Candidate neighbors are sorted by `y`, then `x` for deterministic replay.
- If no path exists, AI falls back to the older local step rule, then `end_turn`.

## Deferred

- path costs by terrain;
- avoiding dangerous tiles;
- choosing cover or highground intentionally;
- multi-turn path memory;
- multi-unit coordination.

## Verified By

- `031_enemy_ai_pathfinds_around_blocked_tile.md`
- `032_enemy_ai_multi_turn_path_pursuit.md`
- `033_diagonal_corner_cut_blocked.md`
