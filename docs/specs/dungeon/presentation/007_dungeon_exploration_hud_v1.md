# 007 Dungeon Exploration HUD V1

Status: active
Date: 2026-07-16

## Intent

Replace the first dungeon debug readout with a cleaner player-facing exploration HUD while keeping the existing room graph, movement model, and dungeon-to-combat bridge.

This is not final dungeon art. It is the first pass that removes raw state diagnostics from the main exploration screen.

## Rules

- `DungeonDebug.tscn` remains the temporary playable dungeon scene for this slice.
- The main status line describes the current room and available action in player-facing language.
- The room detail panel shows:
  - current room name;
  - room state;
  - room content summary;
  - connected exits;
  - reward availability when relevant;
  - last short feedback message when present.
- The header shows a compact expedition progress line with visited rooms, secured rooms, and unlocked rewards.
- The active room panel must be visually distinct from the old debug readout through a stronger framed panel, larger room title, and a prominent combat action when available.
- The room detail panel must not expose raw state lists such as visited room ids, cleared room ids, pending combat request paths, or internal dungeon ids.
- Pending combat rooms expose one primary `Enter Combat` command.
- Manual combat result controls are not visible in the exploration HUD.
- Debug-only combat result application may remain in code for tests or temporary developer hooks, but it must not be part of the visible player-facing HUD.

## Acceptance Proof

Implemented by:

```text
docs/specs/dungeon/slices/006_dungeon_exploration_hud_v1.md
scenes/dungeon/DungeonDebug.tscn
scripts/presentation/dungeon_debug.gd
scripts/presentation/dungeon_exploration_hud_tests.gd
```

## Non-Goals

- final dungeon art direction;
- keyboard/controller navigation;
- minimap fog of war;
- inventory, XP, or item application;
- replacing the tactical combat debug UI.
