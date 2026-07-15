# 003 Dungeon State Model V1

Status: implemented
Date: 2026-07-15

## Purpose

Prove the first deterministic dungeon run state without UI or scene transitions.

The owning state rules live in:

```text
docs/specs/dungeon/overview/004_dungeon_state_model_v1.md
```

## Acceptance

- Initial state starts in `start_room_id`.
- Initial room is marked visited.
- Empty rooms are marked cleared when entered.
- Entering an adjacent room succeeds and updates current room.
- Entering a missing room is rejected.
- Entering a non-adjacent room is rejected.
- Entering a combat room creates `pending_combat_request`.
- Pending combat request includes dungeon id, room id, content type, and combat encounter path.
- Entering a treasure room exposes treasure content but does not apply rewards.

## Proof

Automated coverage:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
```

## Non-Goals

- combat scene launch;
- combat result consumption;
- reward application;
- production dungeon UI.
