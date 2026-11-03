# Painted tactical character batch

Latest correction2026-11-03: user explicitly accepts planted idle feet, corrected
rear shield interiors and stronger/slower bow draw/aim. Open the focused125-case
before/after player with `tools/qa/start_drawn_refinement_preview.ps1`. Baseline938
files preserved in `refinements/before`; exact proof in `refinements/verification.json`.
Stage55: native7368checks/0, offline3579, full regressions/validator PASS. The bow
attack now lasts1800ms and releases at1260ms. Original physical gameplay gaps remain.

Owner: presentation022 / slice022 / milestone017. The user accepted the knight's
12-clip front-right motion and requested this complete six-role batch. Directional
and in-game visual acceptance is still pending. Branch: `2d-art-research`; local
work only, no commit/push/history change.

| Profile | Equipment appearance | Runtime clips per facing | Facings | Runtime frames |
| --- | --- | --- | --- | --- |
| knight | Two-handed sword, forward guard A | 12 | 8 | 544 |
| warrior | One-handed sword and shield | 7 | 8 | 352 |
| archer_1 | Bow and arrow | 7 | 8 | 352 |
| rogue_1 | Paired daggers | 7 | 8 | 352 |
| axe_bandit | Axe | 7 | 8 | 352 |
| bandit_spearman | Spear | 7 | 8 | 352 |

Primary clips: neutral/combat idle and walk, attack, hit, death. Knight extras:
draw, sheathe, alternate thrust, block, dodge. Other roles also retain front-right
and reflected front-left defense samples in the offline player. Those samples
are not additional resolver commands. Runtime: 2304 frames. Source player: 2344
frames, 386 animation clips; every view uses a 384x320 canvas and 192,270 pivot.

Each role has five drawn camera views (S, SE, E, NE, N) and three reflections
(SW from SE, W from E, NW from NE). Reflection reverses costume asymmetry and
weapon handedness; it is labelled in the players and provenance. Unused generated
left-view candidates remain under `raw/sequence_candidate.png`. Mixed facings or
opaque backgrounds were not activated.

Built-in imagegen authored the painted pose sheets. Every main profile and drawn
direction retains `raw/`, exact `prompts.json`, `clips_source.json`, exported
frames/atlases, `manifest.json` and `export_report.json`. Main SE sources live at
the profile root, other views under `directions/`. Non-knight main neutral idles
hold two breathing drawings for 500ms each using four 250ms cels. This is held
animation, with no generated intermediate drawing claim.

Aseprite owns segmentation, alpha cleanup, shared body scale, pivot placement,
timing/tags, atlas export and reflections. Every saved animation source is reopened
and compared pixel-for-pixel and duration-for-duration with its exported frames.
Editable sources: `assets_src/aseprite/characters/drawn_animation/2026-11-03/`.
That directory also has two layered static roster boards and ten independent
weapon sources. The rigid weapon masters in `weapon_library/props` are reusable
reference parts; current articulated action frames have painted/baked weapons,
not a modular runtime weapon rig.

`roster_neutral_idle_1x.png` and `roster_attack_1x.png` use the actual game floor,
contact shadow and native character exports. Their 2x companions use nearest
scaling. They are static compositions, not runtime screenshots or motion proof.

Open the offline player from any working directory:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_drawn_animation_preview.ps1"
```

Native gallery and battle entry:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene drawn
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat
```

Run these separately. In battle, Tools -> scenario "Rycerz — próba animacji";
Tools -> "Malowane postacie" opens the read-only gallery overlay. Existing open
native windows need relaunching to load updated asset registries. No player save
is replaced by this fixture.

Repeat exports from the repository root using the recorded configurations:

```powershell
.venv/Scripts/python.exe tools/qa/export_drawn_actions.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/qa/export_drawn_direction_batch.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/qa/stabilize_drawn_idles.py
.venv/Scripts/python.exe tools/qa/mirror_drawn_directions.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/qa/package_drawn_roster.py knight warrior archer_1 rogue_1 axe_bandit bandit_spearman
.venv/Scripts/python.exe tools/assets/build_catalogue.py
.venv/Scripts/python.exe tools/qa/build_drawn_animation_preview.py
.venv/Scripts/python.exe tools/qa/build_drawn_refinement_preview.py
node tools/qa/check_drawn_animation_player.cjs
.venv/Scripts/python.exe tools/qa/run_drawn_godot_checks.py --import-assets --require-all --regression
.venv/Scripts/python.exe tools/qa/build_drawn_reference_boards.py
.venv/Scripts/python.exe tools/qa/summarize_drawn_batch.py
.venv/Scripts/python.exe tools/validators/validate_all.py
```

No generation API call is needed to repeat the exports. Scripts use the installed
Aseprite and Godot in hidden/headless mode. Final proof: `batch_verification.json`,
`preview_verification.json`, `runtime_package_verification.json` and per-view
reports. All119 earlier source identities are preserved. Technical tests do not
close the61 earlier physical cases or new gallery/battle/campaign review cases.
