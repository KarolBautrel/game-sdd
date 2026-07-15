# Asset Layers

The project keeps visual assets separated by gameplay layer.

## Combat

Combat assets live in `assets/combat/`.

- `characters/` tactical unit sprites used by combat presentation.
- `terrain/` tactical terrain decorations and combat-scale terrain objects.
- `tilesets/` combat map atlases used by Tiled and the Godot combat sandbox.
- `movement_tmp/` temporary combat movement visuals.

Combat terrain should stay readable under units, targeting overlays, movement previews, and hit feedback.

## Dungeon

Dungeon crawler assets live in `assets/dungeon/`.

Use this layer for corridor, room, wall, door, prop, trap, and exploration-scale art. Do not reuse combat terrain by default; dungeon readability and camera language may differ.

## World

World map assets live in `assets/world/`.

Use this layer for symbolic map terrain, routes, settlements, regions, icons, and points of interest. World map terrain should be authored separately from combat grass, cover, and obstacle art.
