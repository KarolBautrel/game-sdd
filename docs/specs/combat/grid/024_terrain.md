# 024 Terrain

Status: specified  
Date: 2026-07-14

## Intent

Combat terrain gives tactical meaning to grid tiles and provides hooks for tactical modifiers.

## Tile Types V1

- `floor`: walkable base tile.
- `blocked`: not walkable; used for rocks, walls, crates, and other obstacles.
- `highground`: walkable elevated tile.
- `cover_low`: walkable low cover tile.

## Current Rules

- Units may move onto `floor`.
- Units may move onto `highground`.
- Units may move onto `cover_low`.
- Units may not move onto `blocked`.
- Units with `resources.mp` pay the terrain MP cost of each tile they enter:
  - `floor`: 1 MP;
  - `cover_low`: 1 MP;
  - `highground`: 2 MP.
- Multi-tile movement chooses the cheapest legal path to the destination, not just the fewest tile steps.
- `unit_moved.mp_spent` records the total MP cost paid for the path.
- Move rejection uses `not_enough_mp` when a walkable destination has a legal path but the path costs more MP than the actor has.
- `highground` gives the attacker `+10` hit chance when using `ranged_attack`.
- `highground` gives the attacker `+1` effective maximum range when using `ranged_attack`.
- `cover_low` gives the ranged target `-20` hit chance modifier.
- No line of sight exception or damage modifier is applied yet.

## Future Hooks

Later specs may add:

- height advantage in melee or ranged combat.
- difficult terrain;
- hazard terrain.
