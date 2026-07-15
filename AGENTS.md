# Agent Working Rules

This project is built with Spec Driven Development.

## Default Workflow

1. Read `docs/specs/` before changing gameplay or presentation behavior.
2. Identify the domain spec that owns the rule. If no owner exists, create one in the correct domain folder before implementation.
3. Add or update the relevant domain spec before implementation.
4. Add or update schemas and reference data when behavior depends on data.
5. Add or update executable slices for acceptance scenarios.
6. Keep slices as proofs/tests only. Do not define durable gameplay, data, AI, UI, or presentation rules only inside `slices/`.
7. Keep milestones as progress summaries and navigation aids only. Do not use milestones as the only source for implemented rules.
8. Run validation before finishing:

```powershell
python tools\validators\validate_all.py
```

9. Run Godot combat slice tests when combat changes:

```powershell
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game" --script res://scripts/domain/combat_slice_tests.gd
```

10. Always give the user the command for launching the interactive debug scene after combat work:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& "C:\Users\karol\Desktop\Gierka\installers\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game"
```

## Milestone Updates

After every meaningful gameplay/spec change, update the relevant milestone document in `docs/specs/*/milestones/`.

The update should include:

- what changed;
- which specs or slices were affected;
- which commands passed;
- what the next recommended step is.

Do not leave milestone notes only in chat. Persist them in the repository.

## Spec Ownership Rules

- Domain folders own rules: `overview/`, `grid/`, `turns/`, `actions/`, `attacks/`, `hit_resolution/`, `equipment/`, `weapons/`, `ai/`, `presentation/`, and future domain folders.
- `slices/` contains chronological executable acceptance scenarios proving that domain rules work.
- `milestones/` contains implementation summaries, validation notes, and next-step guidance.
- When adding a slice for a new mechanic, link the slice back to the owning domain spec.
- When adding a new domain spec, update the relevant `README.md` or structure file that indexes that domain.
- If implementation reveals a rule not covered by a domain spec, update the spec in the same change before finishing.

## Git And Push Policy

Do not commit or push automatically after every change.

- Commit only when the user asks for a commit or when explicitly instructed as part of the current task.
- Push only when the user explicitly says to push, wypchnij, or otherwise asks to send changes to the remote repository.
- It is acceptable to leave validated local changes uncommitted when the user wants to test first.
- Before any requested commit or push, run the relevant validation commands and report the result.

## Combat Rules

Combat domain rules live in:

```text
scripts/domain/combat_resolver.gd
tools/combat/simulate_combat.py
```

Presentation code must not decide combat legality or outcomes. It sends commands to the resolver and displays events.

## Art Creation Rules

Read `agents/README.md` before creating or editing pixel art.

- Pixel-art work must use Aseprite as the source/editor pipeline.
- Terrain art must follow the current tactical 2.5D/oblique direction, not flat top-down debug tiles.
- Keep exported assets repeatable: store Aseprite sources under `assets_src/aseprite/` and generation/export scripts under `tools/aseprite/` when practical.
