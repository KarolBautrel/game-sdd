# 002 Dungeon Debug View V1

Status: implemented
Date: 2026-07-15

## Acceptance

This slice proves the first visible dungeon exploration screen. The owning presentation rules live in:

```text
docs/specs/dungeon/presentation/003_dungeon_debug_view_v1.md
```

- `scenes/dungeon/DungeonDebug.tscn` loads without errors;
- the scene loads `resources/data/dungeons/dungeon_old_mine.json`;
- rooms render from authored room positions;
- corridors render from authored corridor references;
- the start room is visually highlighted;
- room labels show room name and content summary;
- the scene is the current Godot main scene for manual testing.

## Manual Gap

There is no automated screenshot harness yet for dungeon UI. Visual confirmation is manual.
