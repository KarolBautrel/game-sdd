# Agent Working Rules

This project is built with Spec Driven Development.

## Default Workflow

1. Read `docs/specs/` before changing gameplay code.
2. Add or update the relevant spec before implementation.
3. Add or update schemas and reference data when behavior depends on data.
4. Add or update executable slices for acceptance scenarios.
5. Run validation before finishing:

```powershell
python tools\validators\validate_all.py
```

6. Run Godot combat slice tests when combat changes:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd
```

## Milestone Updates

After every meaningful commit, update the relevant milestone document in `docs/specs/*/milestones/`.

The update should include:

- what changed;
- which specs or slices were affected;
- which commands passed;
- what the next recommended step is.

Do not leave milestone notes only in chat. Persist them in the repository.

## Combat Rules

Combat domain rules live in:

```text
scripts/domain/combat_resolver.gd
tools/combat/simulate_combat.py
```

Presentation code must not decide combat legality or outcomes. It sends commands to the resolver and displays events.

