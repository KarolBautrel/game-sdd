# Slice 022: Dungeon Party Targeting V1

Status: implemented
Date: 2026-07-16

## Intent

Prove that dungeon hazard effects target a stable party slot and are translated to a combat unit only when combat launches.

Owner:

```text
docs/specs/dungeon/overview/019_dungeon_party_targeting_v1.md
```

## Acceptance

- Dungeon data can define `default_party_formation`.
- Dungeon run state exposes `party_formation`.
- Hazard consequences in `dungeon_old_mine` use `party_slot_front` instead of `party_member_0`.
- `target_effects.party_slot_front` persists across movement and pending hazards.
- Combat launch maps `party_slot_front` to `unit_player_001`.
- Backwards-compatible `party_member_0` metadata still maps to the first player unit.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/session/dungeon_run_session_tests.gd
```
