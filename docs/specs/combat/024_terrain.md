# 024 Terrain

Status: specified  
Date: 2026-07-14

## Intent

Combat terrain gives tactical meaning to grid tiles before advanced systems like line of sight, cover, and ranged bonuses are implemented.

## Tile Types V1

- `floor`: walkable base tile.
- `blocked`: not walkable; used for rocks, walls, crates, and other obstacles.
- `highground`: walkable elevated tile; no combat bonus yet.

## Current Rules

- Units may move onto `floor`.
- Units may move onto `highground`.
- Units may not move onto `blocked`.
- Tile type affects movement legality only in this version.
- No line of sight, ranged, damage, or hit chance modifiers are applied yet.

## Future Hooks

Later specs may add:

- ranged accuracy bonus from `highground`;
- cover interaction;
- line of sight blockers;
- height advantage in melee or ranged combat.

