# 004 Dungeon Combat Transition V1

Status: implemented
Date: 2026-07-15

## Purpose

Prove that dungeon state can create a combat request and consume a combat result payload without scene transitions.

The owning transition rules live in:

```text
docs/specs/dungeon/overview/005_dungeon_combat_transition_v1.md
```

## Acceptance

- Entering a combat room creates `pending_combat_request`.
- Victory result payload for that room marks the room cleared.
- Defeat result payload for that room does not mark the room cleared.
- Guarded treasure victory unlocks that room's reward for later claim.
- Result payload with mismatched dungeon or room id is rejected.
- `in_progress` result payload is rejected.

## Proof

Automated coverage:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/dungeon_state_model_tests.gd
```

## Non-Goals

- launching combat scene;
- returning from combat scene;
- reward inventory application;
- production dungeon UI.
