# 024 Terrain

Status: specified  
Date: 2026-07-14

## Intent

Combat terrain gives tactical meaning to grid tiles before advanced systems like line of sight and cover are implemented.

## Tile Types V1

- `floor`: walkable base tile.
- `blocked`: not walkable; used for rocks, walls, crates, and other obstacles.
- `highground`: walkable elevated tile.

## Current Rules

- Units may move onto `floor`.
- Units may move onto `highground`.
- Units may not move onto `blocked`.
- `highground` gives the attacker `+10` hit chance when using `ranged_attack`.
- No line of sight, cover, or damage modifiers are applied yet.

## Future Hooks

Later specs may add:

- cover interaction;
- line of sight blockers;
- height advantage in melee or ranged combat.
