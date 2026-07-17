# Slice 045: Generated Dungeon Profiles V1

Status: active
Date: 2026-07-17

## Acceptance

- Generated payloads preserve a named profile id.
- Generated dungeon drafts expose `generated_profile` metadata.
- Short, medium, and deep mine profiles produce profile-specific difficulty, display copy, light budget, and loadout capacity.
- Existing seed determinism remains intact.

## Proof

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_entry_selection_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_procedural_draft_tests.gd
```
