# 003 Dungeon Debug View V1

Status: implemented
Date: 2026-07-15

## Intent

Provide the first visible dungeon exploration screen while final dungeon assets are still being prepared.

The debug view renders authored dungeon data as an abstract room-and-corridor graph. It is intentionally simple and data-driven, so later art passes can replace the visual treatment without changing the dungeon data contract.

## Rules

- The view loads `resources/data/dungeons/dungeon_old_mine.json`.
- Rooms are positioned from room `position` data.
- Corridors render between connected rooms.
- The start room is highlighted.
- Room labels show the room name and content type.
- Clicking a connected room attempts to enter it through the dungeon state model.
- Clicking a non-connected room keeps the current room and shows a rejection reason.
- The view highlights visited, cleared, current, pending combat, and reward-unlocked room states.
- The view may provide debug-only victory/defeat buttons for pending combat requests.
- Debug victory/defeat buttons must call the dungeon state model instead of mutating room state directly.
- The view still does not launch the combat scene.
- Final cave/crypt art is out of scope until dungeon assets are imported.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/002_dungeon_debug_view_v1.md
scenes/dungeon/DungeonDebug.tscn
scripts/presentation/dungeon_debug.gd
```

## Manual Gap

There is no automated screenshot harness for dungeon UI yet. Visual placement and readability are verified by Godot headless load plus manual scene launch.
