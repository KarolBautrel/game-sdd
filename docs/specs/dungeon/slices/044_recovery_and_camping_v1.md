# Slice 044: Recovery And Camping V1

Status: active
Date: 2026-07-17

## Acceptance

- Carrying `camping_kit` enables a `Camp` action when recovery is useful.
- Camping is rejected with no kit or when no recovery is needed.
- Camping consumes one kit.
- Camping reduces run HP loss by the first beta recovery amount.
- Camping clears active dungeon debuffs.
- Camping reduces light by one.

## Proof

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
