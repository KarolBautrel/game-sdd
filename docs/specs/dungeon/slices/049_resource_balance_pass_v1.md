# Slice 049: Resource Balance Pass V1

Status: implemented
Date: 2026-07-17

Owner:

```text
docs/specs/dungeon/overview/041_resource_balance_pass_v1.md
```

## Acceptance

- `dungeon_old_mine` uses 7 packing points.
- Generated `short_mine`, `medium_mine`, and `deep_mine` profiles use distinct packing capacity.
- Overpacked loadouts clamp back inside capacity.
- Bandage can reduce dungeon HP loss and consumes one bandage.
- Trap tools are the carried trap-disarm supply; antidote remains outside the visible default carried set until poison recovery is reintroduced as a separate supply decision.
- Camp requires `camping_kit` and `food`.
- Camp consumes both camping kit and food.
- Camp without food is rejected.
- HUD recovery chooses bandage when HP loss exists without an active debuff.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/presentation/dungeon_exploration_hud_tests.gd
```
