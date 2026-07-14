# Milestone 001: Combat Core Debug Loop

Status: complete  
Date: 2026-07-14

## Summary

Combat has a verified core loop in both Python and Godot.

The project now has:

- combat rule specs;
- combat rule specs organized by tactical domain;
- executable combat slices;
- JSON encounter and command data;
- Python simulation and validation;
- Godot domain resolver;
- Godot headless combat slice tests;
- interactive Godot combat debug scene.

## Implemented Combat Rules

- Turn-based command resolution.
- Active unit validation.
- AP cost validation.
- Melee `basic_attack`.
- `move` to adjacent legal tiles.
- Rejection for invalid move targets:
  - occupied tile;
  - blocked tile;
  - out of bounds;
  - non-adjacent destination.
- `defend` status application.
- `end_turn` turn handoff.
- Enemy AI v0:
  - attack adjacent player;
  - otherwise move one tile toward nearest living player;
  - end turn when it has no AP;
  - otherwise end turn.
- 8-way adjacency:
  - diagonal movement is legal;
  - diagonal melee attacks are legal;
  - AI can use diagonal steps when moving toward the player.
- Deterministic event logs.
- Replay checks for executable slices.
- Terminal combat results:
  - last enemy defeated emits `combat_ended` with `victory`;
  - last player defeated emits `combat_ended` with `defeat`;
  - commands after combat end are rejected with `combat_already_ended`;
  - debug scene disables command buttons after combat ends.
- Terrain v1:
  - `blocked` tiles are not walkable;
  - `highground` tiles are walkable;
  - debug scene colors terrain types distinctly;
  - attacker on `highground` gets `+10` ranged hit chance.
- Ranged attack v1:
  - `ranged_attack` targets a living enemy up to range 3;
  - range uses Chebyshev distance to match current 8-way movement;
  - no line of sight or cover is applied yet;
  - out-of-range targets are rejected with `target_out_of_range`.
- Hit chance v1:
  - `ranged_attack` resolves a deterministic 1-100 roll;
  - base hit chance is 70%;
  - `hit_roll_resolved` records roll, base chance, unit modifiers, terrain modifier, final chance, and outcome;
  - misses spend AP but do not apply damage;
  - melee attacks still always hit.
- Accuracy/evasion v1:
  - final ranged hit chance uses `base + attacker.accuracy - target.evasion`;
  - omitted accuracy/evasion stats default to 0;
  - final hit chance is clamped to 10-95.
- Debug scene usability pass:
  - action buttons use readable labels;
  - ranged attack can be selected and tested;
  - unit HP/AP, accuracy/evasion, and position are visible in a side panel;
  - a compact legend explains grid colors.

## Verified Slices

Executable slice docs live in:

```text
docs/specs/combat/slices/
```

Current verified slices:

- `001_basic_attack.md`
- `002_invalid_no_ap.md`
- `003_move.md`
- `004_move_occupied.md`
- `005_move_blocked.md`
- `006_defend.md`
- `007_end_turn.md`
- `008_enemy_ai_adjacent_attack.md`
- `009_enemy_ai_move_toward_player.md`
- `010_diagonal_move.md`
- `011_diagonal_attack.md`
- `012_enemy_ai_no_ap_end_turn.md`
- `013_round_cycle_player_enemy_player.md`
- `014_victory_last_enemy_defeated.md`
- `015_defeat_last_player_defeated.md`
- `016_command_after_combat_end_rejected.md`
- `017_debug_legal_target_feedback.md`
- `018_debug_reset_and_enemy_turn_helper.md`
- `019_highground_walkable.md`
- `020_terrain_debug_visible.md`
- `021_ranged_attack_in_range.md`
- `022_ranged_attack_out_of_range.md`
- `023_ranged_attack_hit_roll.md`
- `024_ranged_attack_miss.md`
- `025_accuracy_increases_hit_chance.md`
- `026_evasion_decreases_hit_chance.md`
- `027_highground_increases_ranged_hit_chance.md`

## Spec Organization

Rule specs now live in domain folders:

- `overview/`
- `grid/`
- `turns/`
- `actions/`
- `attacks/`
- `hit_resolution/`
- `ai/`

Executable slices remain flat in `slices/`.

See:

```text
docs/specs/combat/STRUCTURE.md
```

## Latest Update

Latest verified scope:

- round increments when turn order wraps back to the player;
- player AP refreshes when the next player turn starts;
- full player -> enemy -> player round cycle is verified in Python and Godot;
- victory and defeat are verified in Python and Godot;
- commands after combat end are rejected.
- debug scene highlights active unit and legal targets using resolver-backed checks;
- debug scene displays last accepted action or rejection reason.
- debug scene can reset the encounter;
- debug scene has a one-click enemy turn helper.
- terrain v1 is specified and highground movement is verified.
- ranged attack v1 is specified and verified in Python and Godot.
- hit chance v1 is specified and verified in Python and Godot.
- accuracy/evasion v1 is specified and verified in Python and Godot.
- highground ranged hit modifier is specified and verified in Python and Godot.
- debug scene has a clearer status panel, unit panel, legend, and ranged attack button.

## Important Files

Python domain prototype:

```text
tools/combat/simulate_combat.py
tools/validators/validate_combat_slice.py
```

Godot domain implementation:

```text
scripts/domain/combat_resolver.gd
scripts/domain/combat_slice_tests.gd
```

Interactive debug scene:

```text
scenes/combat/CombatDebug.tscn
scripts/presentation/combat_debug.gd
```

## Validation Commands

Full validation:

```powershell
python tools\validators\validate_all.py
```

Combat slices in Python:

```powershell
python -m tools.validators.validate_combat_slice
```

Combat slices in Godot:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd
```

Interactive combat debug scene:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
```

## Planned But Not Implemented

These specs exist as planned placeholders:

- line of sight;
- cover.

## Recommended Next Step

Implement line of sight v1:

- `ranged_attack` requires clear line of sight;
- `blocked` tiles block line of sight;
- no cover modifier yet;
- no highground line-of-sight exception yet.

Suggested slice:

```text
docs/specs/combat/slices/028_ranged_attack_blocked_by_line_of_sight.md
```
