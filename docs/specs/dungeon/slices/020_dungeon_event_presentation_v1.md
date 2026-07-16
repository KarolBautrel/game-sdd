# Slice 020: Dungeon Event Presentation V1

Status: implemented
Date: 2026-07-16

## Intent

Prove the first player-facing corridor event panel.

Owner:

```text
docs/specs/dungeon/presentation/012_dungeon_event_presentation_v1.md
```

## Acceptance

- Event UI shows title, text, choices, supply availability, and resolved outcome.
- Event UI can work with placeholder art.
- Event UI does not require pixel art.
- Result text mirrors the structured hazard outcome event.

## Validation

First-pass event panel behavior is covered by:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```

The implementation is a custom debug panel without final art. Future work may replace it with a production event card and illustration slot, but the first player-facing event panel proof is complete.
