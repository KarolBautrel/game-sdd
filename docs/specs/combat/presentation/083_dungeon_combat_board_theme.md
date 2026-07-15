# 083 Dungeon Combat Board Theme

Status: active
Date: 2026-07-15

## Purpose

Combat should be able to show a dungeon room using the same tactical rules and debug controls as the meadow showcase.

This is a presentation layer theme. It does not introduce dungeon exploration movement, room clearing, loot application, or combat scene transitions.

## Rules

- Combat encounters may reference a generated dungeon board background through `background_path`.
- The dungeon board background uses stone floor assets from `assets/combat/terrain/floors/stone/`.
- The board should read as one continuous grey stone combat surface, not a set of isolated square tiles.
- Logical combat terrain remains data-driven by encounter `grid.tiles`.
- Dungeon terrain props render above the generated background and stay aligned to logical tile centers.
- Dungeon `blocked` tiles may use large props such as gates, spike fences, barricades, or door pieces.
- Dungeon `cover_low` tiles may use chest, coffin, skull pile, or similar waist-height props.
- Dungeon `highground` tiles keep the existing elevation presentation and may use stone/tablet/coffin accents.
- The same move, attack, target preview, highground bonus, cover, and terrain MP cost rules apply on dungeon boards.

## Current Debug Encounter

`debug_dungeon_combat_showcase` is the first authored dungeon-themed combat board.

It reuses the existing full combat showcase mechanics with:

- `old_mine_dungeon_00_stone.png` as the generated board background;
- dungeon props selected for blocked, cover, highground, and a few floor accent positions;
- the scenario picker label `Old Mine dungeon`.

## Acceptance

- Loading `Old Mine dungeon` in the combat debug scenario picker shows a grey stone dungeon board.
- The combat grid, unit positions, overlays, and movement previews remain aligned with the background.
- Cover and blocked tiles are visually represented by dungeon props rather than meadow/nature props.
- Highground remains visibly elevated for units and does not lose its tactical bonuses.
- Existing meadow combat encounters still use meadow backgrounds and nature props.
