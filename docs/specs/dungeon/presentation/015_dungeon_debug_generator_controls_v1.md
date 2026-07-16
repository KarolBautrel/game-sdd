# Dungeon Debug Generator Controls V1

Status: implemented
Owner: dungeon presentation

## Purpose

The dungeon debug scene must expose enough generated-dungeon metadata to make template-pool testing understandable without turning the debug controls into a player-facing flow.

In the target game, dungeon difficulty is selected before entering the dungeon by world/progression content. The debug scene may still expose difficulty buttons so testers can quickly inspect template pools for difficulty 1, 2, and 3.

## Rules

- Generator controls are only available while the expedition is still in preparation.
- Generated source uses a debug-selected difficulty and seed.
- Authored Old Mine keeps its authored data and does not depend on the debug difficulty buttons.
- Switching generated difficulty rebuilds the generated dungeon data, resets preparation state, clears pending session data, and keeps the selected source as generated.
- Reroll changes the seed and rebuilds the generated dungeon data for the currently selected debug difficulty.
- The preparation panel must show the active source, difficulty, seed, room count, corridor count, and generated corridor hazard count.
- The map must recalculate its graph transform after every generated source, seed, or difficulty change.
- Dense generated templates must scale room blocks, corridor widths, marker sizes, and map text down enough to keep every room inside the framed map area.
- The displayed difficulty is test metadata. It is not a durable player-facing rule for how final dungeons are entered.

## Non-goals

- No player-facing difficulty selection flow.
- No manual seed text input.
- No generated-dungeon save/load persistence beyond the active debug run/session.

## Proof

- `scripts/presentation/dungeon_exploration_hud_tests.gd` covers debug difficulty switching, seed/reroll metadata, and generated summary text.
