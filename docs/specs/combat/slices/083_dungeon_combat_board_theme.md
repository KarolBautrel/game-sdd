# 083 Dungeon Combat Board Theme

Status: implemented
Date: 2026-07-15

## Acceptance

This slice proves the first dungeon-themed combat board presentation. The owning presentation spec lives in:

```text
docs/specs/combat/presentation/083_dungeon_combat_board_theme.md
```

- a combat encounter can reference `res://assets/combat/terrain/backgrounds/old_mine_dungeon_00_stone.png`;
- the dungeon background is generated from stone floor assets under `assets/combat/terrain/floors/stone/`;
- `debug_dungeon_combat_showcase` is available through the combat scenario catalog as `Old Mine dungeon`;
- dungeon boards use dungeon props for blocked, cover, highground, and floor accent decoration;
- meadow boards keep the existing meadow background and nature decorations;
- dungeon board theming does not alter combat rule resolution.

## Non-Goals

- automatic dungeon room to combat encounter authoring;
- dungeon exploration scene transitions;
- room clearing, loot application, inventory, or XP;
- final dungeon art direction.
