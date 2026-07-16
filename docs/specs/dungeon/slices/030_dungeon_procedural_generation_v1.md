# Slice 030: Dungeon Procedural Generation V1

Status: implemented
Date: 2026-07-16

## Intent

Prove generated dungeon maps vary by seed and scale by difficulty.

Owner:

```text
docs/specs/dungeon/overview/025_dungeon_procedural_generation_v1.md
```

Related owners:

```text
docs/specs/dungeon/overview/024_dungeon_procedural_draft_v1.md
docs/specs/dungeon/presentation/014_dungeon_debug_generated_toggle_v1.md
```

## Acceptance

- Same seed and difficulty produce the same generated graph signature.
- Different seeds produce different generated graph signatures.
- Higher difficulty produces more rooms/corridors than lower difficulty in the first profile.
- Generated maps contain entrance, treasure, combat, and exit room content.
- Generated maps can still enter the existing state model and traverse to a combat room.
- The debug screen generates a new seed when switching/rerolling Generated Draft in preparation.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
