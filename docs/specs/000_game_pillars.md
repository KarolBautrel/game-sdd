# 000 Game Pillars

Status: draft  
Date: 2026-07-14

## Product intent

The game is a 2D pixel art RPG/roguelite built around a small, testable vertical slice before broad content production.

## Pillars

1. Spec first

   Every meaningful mechanic starts as a written spec, a data contract, acceptance scenarios, and reference data.

2. Deterministic systems

   Combat, travel, encounters, and loot must be reproducible from input commands and RNG seed.

3. Data-driven content

   Towns, dungeons, world map nodes, actions, items, NPCs, and encounters live in validated data files.

4. Thin presentation

   Godot scenes display state and collect input. Domain rules stay outside UI and animation code.

5. Small vertical slice

   The first playable target is one town, one world region, one dungeon path, one combat encounter, one loot result, and save/load.

## Non-goals for the first slice

- Full procedural campaign generation.
- Large dialogue system.
- Multiple player classes.
- Complex enemy AI.
- Internal game editor.
- Mod support.

