# Slice 008: Dungeon Reward Claim V1

Status: active
Date: 2026-07-16

## Intent

Prove one-time reward claiming for treasure and guarded treasure rooms.

The owning domain rules live in:

```text
docs/specs/dungeon/overview/008_dungeon_reward_claim_v1.md
```

## Acceptance

- Plain treasure can be claimed after entering the room.
- Claimed reward rooms cannot be claimed again.
- Claiming a reward stores a reward record in dungeon state.
- Claiming a reward marks the room cleared.
- Guarded treasure cannot be claimed until combat victory unlocks it.
- Guarded treasure can be claimed after combat victory.

## Validation

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
