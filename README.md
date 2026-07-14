# sdd-game

Godot 4.7 project built with Spec Driven Development.

## Current workflow

1. Update or add a spec in `docs/specs/`.
2. Add or update data contracts in `resources/schemas/`.
3. Add reference data in `resources/data/`.
4. Run validation:

```powershell
python tools/validators/validate_all.py
```

5. Implement gameplay only after the spec and data contract pass.

## Manual Commands

Run these commands from the project directory:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
```

Validate all specs, schemas, reference data, and executable slices:

```powershell
python tools\validators\validate_all.py
```

Validate only combat executable slices:

```powershell
python -m tools.validators.validate_combat_slice
```

Check that Godot can load the project without opening a window:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --quit
```

Run the Godot combat domain slices:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd
```

Run the interactive combat debug scene:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
```

The current main scene is `scenes/combat/CombatDebug.tscn`.

Debug scene controls:

- Select `move`, then click a neighboring floor tile.
- Select `basic_attack`, then click an enemy tile.
- Click `defend` to apply the defending status.
- Click `end_turn` to pass control to the next unit.
- Click `enemy_ai` while an enemy is active to let AI v0 choose a command.
- Read the right-side event log to verify what the domain resolver emitted.

## Tooling

- Godot 4.7 stable
- GDScript
- Python 3.12+ for validators and generators
- Tiled for maps
- Aseprite for sprite sources and sprite sheet export

## Spec Domains

- `docs/specs/combat/` tactical combat on a square grid.
- `docs/specs/combat/slices/` executable combat acceptance scenarios.
- `docs/specs/dungeon/` dungeon exploration and encounter triggers.
- `docs/specs/world/` world map, towns, travel, and services.
- `docs/specs/data/` shared data contracts and validation rules.
