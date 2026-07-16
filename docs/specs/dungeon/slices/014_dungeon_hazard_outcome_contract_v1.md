# Slice 014: Dungeon Hazard Outcome Contract V1

Status: implemented
Date: 2026-07-16

## Intent

Prove a deterministic contract for corridor hazard resolution.

Owner:

```text
docs/specs/dungeon/overview/013_dungeon_hazard_outcome_contract_v1.md
```

## Acceptance

- Corridor hazard data validates through schema.
- Hazard resolution produces a stable event payload.
- Weighted outcomes are deterministic under seed.
- Consequences are listed in structured data, not prose only.

## Validation

```powershell
python tools\validators\validate_all.py
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
```
