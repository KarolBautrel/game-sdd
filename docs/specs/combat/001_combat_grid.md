# 001 Combat Grid

Status: draft  
Date: 2026-07-14

## Intent

The tactical battlefield is a square grid. The first slice uses a fixed 6x6 board.

## Coordinates

Coordinates are zero-based:

```text
x: 0..width-1
y: 0..height-1
```

Top-left is `{ "x": 0, "y": 0 }`.

## Tile Types

Initial tile types:

- `floor`: walkable and targetable.
- `blocked`: not walkable and blocks movement.

Future tile types:

- `hazard`
- `difficult`
- `water`
- `pit`
- `cover_low`
- `cover_high`

## Movement

Movement uses 8-way adjacency:

- north
- south
- east
- west
- north-east
- north-west
- south-east
- south-west

Diagonal movement is allowed when the destination tile is inside bounds, walkable, and unoccupied.

## Occupancy

Rules:

- A living unit occupies exactly one tile.
- Two living units cannot occupy the same tile.
- Dead units do not block movement in the first slice.
- A unit cannot move outside grid bounds.
- A unit cannot move through `blocked` tiles.

## Distance

Melee adjacency and one-step movement use Chebyshev distance:

```text
max(abs(ax - bx), abs(ay - by))
```

## Acceptance Criteria

### Legal movement

- Given a unit at `{ "x": 1, "y": 1 }`
- And a floor tile at `{ "x": 2, "y": 1 }`
- When the unit moves one step east
- Then the move is accepted
- And the unit position becomes `{ "x": 2, "y": 1 }`

### Blocked movement

- Given a unit at `{ "x": 1, "y": 1 }`
- And a blocked tile at `{ "x": 2, "y": 1 }`
- When the unit attempts to move east
- Then the move is rejected
- And the unit position remains `{ "x": 1, "y": 1 }`

### Occupied tile

- Given a player unit at `{ "x": 1, "y": 1 }`
- And an enemy unit at `{ "x": 2, "y": 1 }`
- When the player attempts to move to `{ "x": 2, "y": 1 }`
- Then the move is rejected
