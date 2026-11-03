# sdd-game

Godot 4.7 project built with Spec Driven Development.

Current character direction: accepted painted tactical2D, six animated weapon
roles, eight views, editable Aseprite sources and repeatable imagegen/export
recipes. See [source guide](assets_src/characters/drawn_animation/2026-11-03/README.md)
and [accepted corrections](docs/qa/stages/2026-11-03-stage-55.md).

For a new agent/session, start with [Continue development here](docs/CONTINUE_HERE.md):
accepted stages, next unfinished milestone item, evidence and required playtest loop.
Stages8..29 have automated PASS; their combined actual-play session remains
pending in [live-test-scenarios.md](docs/qa/live-test-scenarios.md). Final technical
build and review: [stage29 report](docs/qa/stages/2026-11-02-stage-29.md).

Latest Windows build: `artifacts/export-smoke/stage29-release-20261102/sdd-game.exe`
with adjacent PCK/override.cfg. It starts directly in the campaign map, windowed
on larger left DISPLAY1. Dark fantasy inventory, distinct item art, parchment map,
merchant inspectors, training and town share one coherent visual family.
Dungeon exploration and battle now use that family too: named room vignettes,
paper preparation/events, readable actions/costs and an inspector outside the board.
[Play UI previews and launch commands](docs/design/play-ui/README.md).
[Art/tool workflow](docs/design/campaign-ui/TOOLING.md) includes installed skills,
Godot MCP, Aseprite recipes, asset libraries and native GPU review commands.
Physical gameplay review remains pending in the live registry; character preview
and stage55 idle/shield/bow corrections are explicitly user-accepted.
No player-save reset is required.

## Current workflow

1. Find the domain spec in `docs/specs/` that owns the rule.
2. Update or add that domain spec before implementation.
3. Add or update data contracts in `resources/schemas/`.
4. Add reference data in `resources/data/`.
5. Add or update executable slices as acceptance scenarios. Slices prove rules; they do not own durable rules.
6. Add or update automated test/validator coverage for the slice. If automation does not exist yet, document the manual verification gap in the slice and milestone.
7. Update the active milestone as a summary and pointer to the owning specs, slices, and tests.
8. Run validation:

```powershell
python tools/validators/validate_all.py
```

9. Implement gameplay only after the spec and data contract pass.

Required SDD chain for behavior changes:

```text
domain/presentation spec -> slice acceptance scenario -> test/validator proof
```

`docs/specs/*/milestones/` summarizes progress. `docs/specs/*/slices/` proves behavior. Durable gameplay, data, AI, UI, and presentation rules belong in domain folders such as `actions/`, `equipment/`, `ai/`, or `presentation/`.

When a milestone defines an ordered queue, work from the first unfinished item. Mark it complete only after its owner spec, slice, implementation, and validation/test proof are all present.

## Manual Commands

### Stage verification and DISPLAY1 playtest

Set up the project-local Python environment once:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
```

Run all data validation, runner contract checks, Godot suites and entry-scene
smoke checks with logs and a machine-readable report:

```powershell
.\.venv\Scripts\python.exe tools\qa\verify_project.py
```

Launch the real game on the additional monitor selected by the user, Windows
`DISPLAY1` (the launcher fails if it is unavailable):

```powershell
.\tools\qa\start_game.ps1 -Scene dungeon
.\tools\qa\start_game.ps1 -Scene app
.\tools\qa\start_game.ps1 -Scene combat
.\tools\qa\start_game.ps1 -Scene map-editor
.\tools\qa\start_game.ps1 -Scene drawn
```

Reports and logs are under ignored `artifacts/qa-runs/`. Automated success is
reported separately from hands-on playthrough acceptance. Stage reports are
indexed in `docs/qa/README.md`; the owning contract is
`docs/specs/tooling/001_stage_verification.md`.

When this CLI is elevated, prepare placement with
`.\tools\qa\start_game.ps1 -ConfigureOnly`, then use **Run** in the ordinary
Godot Project Manager. This tested workflow accepts normal desktop input.
The local profile uses windowed DISPLAY1 and is ignored by Git and exports.

After adding/changing PNG assets, regenerate the runtime catalogue:

```powershell
.\.venv\Scripts\python.exe tools\assets\build_catalogue.py
.\.venv\Scripts\python.exe tools\assets\build_catalogue.py --check
.\.venv\Scripts\python.exe tools\qa\export_smoke.py
```

Export smoke uses installed Godot 4.7 Windows templates and writes a standalone
EXE/PCK plus logs/report into `artifacts/export-smoke/`. Add `--release` for a
release build. It executes the actual exported binary from that directory.
Exports omit the owned local QA profile while building and restore it afterwards.
For DISPLAY1 placement during a playtest, copy the generated `override.cfg` next
to the exported EXE. Entry-scene selection through that file is unverified;
the tested export starts at the tracked project entry scene.

### Individual commands

Run these commands from the project directory:


Validate all specs, schemas, reference data, and executable slices:

```powershell
python tools\validators\validate_all.py
```

Validate only combat executable slices:

```powershell
python -m tools.validators.validate_combat_slice
```

The current main scene is `scenes/dungeon/DungeonDebug.tscn`.

From preparation press **F7** (or World / Ravenford) to open the campaign hub.
Visit Ravenford to buy supplies or recover at the inn, travel to Old Mine and
prepare a managed expedition (keep food for the journey back). Roads advance
time/food and may create persisted cart choices or tactical ambushes. Open Stash
shows item stacks/filters and per-hero weapon, off-hand and armor assignments.
Ravenford Trading Post buys equipment and sells one unassigned loot copy at a
time. Quest/legacy/assigned copies are protected; bought equipment is fitted
through Open Stash.
Equipment uses owned copies and locks for active expeditions/events. Campaign
v4 migrates valid older saves without losing progress. Training in Ravenford
allocates shared earned XP to hero levels without healing. Campaign interfaces
share responsive navigation, resource header, party rail and visible feedback.
Stock, equipment, advancement, world
position, injuries and exploration checkpoints persist in
`user://campaign_v1.json`; use F7 then Resume after restarting. Direct dungeon
launch is a free sandbox. Managed runs use normal Retreat or Finish then F7 to
settle their loot once. Combat saves resume at encounter entry, not mid-turn.

Debug scene controls:

- Select `move`, then click a neighboring floor tile.
- Select `basic_attack`, then click an enemy tile.
- Select `ranged_attack`, then click an enemy tile up to 3 tiles away.
- Click `defend` to apply the defending status.
- Click `end_turn` to pass control to the next unit.
- Click `enemy_ai` while an enemy is active to let AI v0 choose a command.
- Click `enemy_turn` to advance through a simple enemy turn sequence.
- Click `reset` to reload the debug encounter.
- The active unit is highlighted yellow.
- Legal move and attack targets are highlighted green.
- Blocked terrain is dark.
- Highground terrain is gold.
- The right side shows action buttons, unit HP/AP, and the event log.
- Ranged attacks show hit/miss rolls, unit modifiers, and terrain modifiers in the event log.
- Rejected commands show the rejection reason in the feedback label.
- Read the right-side event log to verify what the domain resolver emitted.

## Tooling

- Godot 4.7 stable
- GDScript
- Python 3.12+ for validators and generators
- Tiled for maps
- Aseprite for sprite sources and sprite sheet export

## Spec Domains

- `docs/specs/combat/` tactical combat specs, organized by domain.
- `docs/specs/combat/STRUCTURE.md` explains combat spec ownership and folder rules.
- `docs/specs/combat/slices/` executable combat acceptance scenarios.
- `docs/specs/dungeon/` dungeon exploration and encounter triggers.
- `docs/specs/world/` world map, towns, travel, and services.
- `docs/specs/data/` shared data contracts and validation rules.
- `docs/specs/presentation/` reusable passive UI components shared across screens.


