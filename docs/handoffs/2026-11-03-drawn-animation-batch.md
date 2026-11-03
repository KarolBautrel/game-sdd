# Resume: accepted knight motion, continue the authorized character batch

Active repository game_dir/sdd-game, branch2d-art-research. Preserve all existing
uncommitted work. No commit/push/history task. Owner presentation022, slice022,
milestone017 supersedes021's old stop-for-review gate.

User selects painted pose A from stage51 as default two-handed combat guard;
side guard B is not the default. Retain neutral/rest posture. User requested the
complete knight action set, then other weapon roles and a useful character
subset. Provide knight review command before rewriting other characters, then
continue immediately. That command WAS supplied before other-character image
generation began. User then explicitly says animations are great, approves the
delivered3/4 set, and asks to continue all work with periodic new review commands.

Final batch: IMPLEMENTED / AUTOMATED_PASS / AWAITING_INTERACTIVE. Six active
profiles: knight (two-handed sword), warrior (sword/shield), archer_1 (bow),
rogue_1 (paired daggers), axe_bandit, bandit_spearman. All have eight facings:
five drawn camera views S/SE/E/NE/N and three disclosed reflections SW/W/NW.
The latter reverse visible handedness/costume asymmetry; user review pending.
Unused mixed-facing/opaque left-view candidates retained, not activated.

Knight12 clips per direction: neutral/combat idle/walk, draw/sheath, cut/thrust,
parry, dodge, hit, death.544 runtime frames. Other roles seven primary clips per
direction=352each. Total2304 runtime frames, copied with SHA256 proof. Offline
player includes extra two-view defense samples for other roles:2344 source frames,
386 animation sources.398 editable Aseprite files including10 independent rigid
weapon reference masters and2 layered static boards. Action sprite weapons are
painted/baked; do not claim a modular runtime weapon rig.

Sources, exact prompts, raw inputs, clip recipes, frame atlases and per-view
source-reopen reports:
`assets_src/characters/drawn_animation/2026-11-03/README.md`.
Editable sources under `assets_src/aseprite/characters/drawn_animation/2026-11-03`.
All48 view sources reopen pixel-exactly with timing/tags;384x320,pivot192,270,
171px body target.119 prior static/pose-source identities preserved. All raster
processing/export in Aseprite; built-in imagegen supplied drawings. No paid tool,
installation or new3D work. Source queue completed in `direction_plan.json`;
do not regenerate the obsolete pending queue. Bow/spear axial attack repairs
and corrected warrior combat walk are already selected by recorded configs.

The existing renderer reads `resources/data/presentation/drawn_roster.json`;
all six complete profiles active, untouched families/portraits preserved. Authored
timing/stride, combat-ready idle/walk, impact-delayed damage/reaction, full action/
fall recovery, terminal corpse and reset cancellation implemented. Original
resolver/equipment/save rules unchanged. Native gallery offers all clips/views
and read-only Tools overlay. Separate knight sandbox uses ordinary combat data
with a separate pilot ID and no shield, not a new weapon rule or player save.

Review commands supplied in chat. Run separately from any PowerShell directory:

```powershell
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_drawn_animation_preview.ps1"
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene drawn
& "C:\Users\karol\Desktop\Gierka\game_dir\sdd-game\tools\qa\start_game.ps1" -Scene combat
```

Close/relaunch older native windows for final registry. In battle: Tools scenario
"Rycerz — próba animacji" -> Load; Tools "Malowane postacie" opens the gallery.
Offline player has native/enlarged views, all clips/views, speed, pause/step/tour,
floor choice and preserved selected action when changing view.

Final proof2026-11-03:

- `build_drawn_animation_preview.py`: PASS6profiles/2344frames.
- `node tools/qa/check_drawn_animation_player.cjs`: PASS3579checks.
- `run_drawn_godot_checks.py --import-assets --require-all --regression`: PASS;
  final drawn6980checks, original roster15679, equipment31, feedback179; lifecycle OK
  and Godot combat slice passed. Logs have no errors/warnings. Actual resolver-
  driven attack/hit/death, final frames, reset and overlay restoration exercised.
  Last gallery step/resume fix rechecked with `--require-all --only runtime`:
  PASS6980; full regression suites had already passed before this gallery-only fix.
- `build_catalogue.py`:9920textures; `validate_all.py`: PASS.
- `summarize_drawn_batch.py`: PASS; durable `batch_verification.json`, source and
  runtime reports. Raw logs under artifacts/drawn-animation. Stage53/54 reports
  and milestone017 updated.

Agent inspected native-scale static neutral/attack boards and repaired pose
stills. Browser host unavailable, so agent-watched continuous motion NOT_RUN.
Earlier explicit user feedback accepts knight3/4 only. Other roles, directions,
mirrored convention and gameplay visuals still need actual review. No broad
visual acceptance inferred from technical checks.

Next unfinished task: L53-01 gallery and L54-01/L54-02 battle/campaign review;
all61 earlier physical cases remain NOT_RUN. Do not start another roster batch
or historical Git task without new scope. Desktop remains unreleased: no visible
agent launch/native input. Current changes remain local/uncommitted on
2d-art-research; Git history repair remains deferred.
