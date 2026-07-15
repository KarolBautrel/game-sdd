# 005 Dungeon Exploration Scene V1

Status: implemented
Date: 2026-07-15

## Purpose

Prove the first end-to-end dungeon exploration scene bridge.

The owning presentation rules live in:

```text
docs/specs/dungeon/presentation/006_dungeon_exploration_scene_v1.md
```

## Acceptance

- Dungeon scene can move through connected rooms.
- Pending combat room shows `Start Combat`.
- `Start Combat` opens `CombatDebug.tscn` with a presentation-ready encounter path.
- Dungeon combat encounter paths do not reference `slice_*` regression encounters.
- Dungeon combat encounters provide generated backgrounds and at least a 10x8 board.
- Combat launched from dungeon carries source dungeon id and source room id.
- Combat launched from dungeon keeps the authored board preset but randomizes enemy units to 2-3 legal spawns.
- Randomized enemies use supported enemy archetypes and are not placed on blocked tiles.
- Ended combat shows `Return to Dungeon`.
- Returning after victory clears the source room in dungeon state.
- Returning after defeat does not clear the source room.
- Guarded treasure victory unlocks its reward marker.

## Proof

Automated coverage:

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/dungeon/DungeonDebug.tscn --quit --resolution 2560x1440
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" res://scenes/combat/CombatDebug.tscn --quit --resolution 2560x1440
```

Manual verification:

- Launch `DungeonDebug.tscn`, enter a combat room, press `Start Combat`, finish the battle, and press `Return to Dungeon`.

## Non-Goals

- production UI polish;
- automated visual click-through harness;
- reward inventory application.
