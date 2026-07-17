# Pixel-Art Dungeon UI Assets V1

Status: implemented
Date: 2026-07-17

## Intent

Replace temporary indexed dungeon icon reuse with dedicated, readable pixel-art icons for the visible dungeon resource tray and core room markers.

## Rules

- Dedicated dungeon HUD icons live under `assets/ui/dungeon/processed/icons/`.
- Resource tray icons must be named by meaning, not atlas index:
  - `icon_lamp_oil.png`;
  - `icon_pickaxe.png`;
  - `icon_trap.png`;
  - `icon_bandage.png`;
  - `icon_camping_kit.png`;
  - `icon_food.png`.
- Dungeon presentation may also use dedicated icons for gold, light states, room events, hazards, treasure rooms, combat rooms, exits, and locked rooms.
- Processed icons must not retain visible green background pixels from the source atlas.
- HUD code should reference semantic icon names instead of `dungeon_icons_XX` indices for newly covered dungeon play icons.

## Non-Goals

- final production UI skin;
- full animation;
- replacing every legacy dungeon atlas frame;
- town/world inventory icon coverage.

## Proof

- Generated icons exist under `assets/ui/dungeon/processed/icons/`.
- A pixel scan confirms no visible green background pixels remain.
- Dungeon HUD tests prove resource and room icon paths use dedicated semantic files.
