# Dark fantasy UI workshop and preparation layout proofs

Date: 2026-11-04. Owners: presentation033 / dungeon047; slices033 / 055;
milestone022 stage74. The user approves the entire mine/dungeon/castle/forest
family and requests randomized maps plus an English reusable design package.

## Delivered

- Canonical English package: `packages/dark-fantasy-ui-workshop/`.
- Installed skill: `C:/Users/karol/.codex/skills/dark-fantasy-game-ui/`.
  Discovery should refresh on a subsequent turn; invoke `$dark-fantasy-game-ui`.
- Four actual approved reference PNGs with provenance, saved sibling prompts,
  original mine brief, corrected castle history and a rejected material example.
  Native font identity remains unresolved; compare licensed serif candidates
  against the actual images rather than guessing from legacy game fonts.
- Fifteen authored graph recipes, five each for short (5..7 rooms), medium
  (8..10) and long (11..14), reusable across four themes: 60 base combinations.
  Stable seeds vary topology choice, endpoint orientation, mirroring, room roles,
  labels, optional locks and planned art keys. Difficulty changes abstract budget
  metadata separately from length. Generated keys are not produced sprites.
- Offline tools for initialization, seeded blueprints, layout study galleries,
  reference/native overlays, integrity checks, safe installation and ZIP export.
- Installable ZIP: `artifacts/releases/dark-fantasy-ui-workshop-v0.1.0.zip`.
  SHA256: `9d9e10fdc2d2f65da794ba2c3d8c9efd0826eb86904512d34302aa3e782f9209`.
  All 19 packaged/installed files match canonical source bytes; actual images,
  not LFS pointer files, are included. The canonical package also retains the
  authoring script and regression suite outside the installable skill folder.

## Proofs

From the repository:

```powershell
.venv/Scripts/python.exe -m unittest discover -s packages/dark-fantasy-ui-workshop/tests -v
.venv/Scripts/python.exe packages/dark-fantasy-ui-workshop/skills/dark-fantasy-game-ui/scripts/workshop.py check --seeds 100
.venv/Scripts/python.exe C:/Users/karol/.codex/skills/.system/skill-creator/scripts/quick_validate.py packages/dark-fantasy-ui-workshop/skills/dark-fantasy-game-ui
```

PASS: six regression tests; 3,600 configuration checks across 100 seeds, all
themes, lengths and difficulties, plus explicit coverage of all 15 recipes.
Checks cover deterministic replay, independence of theme/difficulty from topology,
connectedness, unique rooms/positions/edges, pacing slots, reachable keys/exits,
non-crossing diagram geometry and rejection of malformed/deadlocked inputs.
Native routing will additionally need clearance from actual artwork/labels.
Repository `tools/validators/validate_all.py` and `git diff --check` also PASS.

Portability tests copy to a differently named folder and use paths with spaces.
They initialize/sample/check, reject overwrites and output inside the skill,
exercise preview/overlay generation, install and inspect ZIP bytes. This caught
and fixed an archive root that incorrectly followed the relocation folder name.
The official skill validator now passes. Its PyYAML dependency was added to the
local development venv; the workshop itself uses only Python's standard library.

A separate real installed-skill smoke ran from an external temporary directory,
`C:/Users/karol/AppData/Local/Temp/Dark Fantasy UI External osb_bakb/`, initializing
a forest project and generating a long/hard castle blueprint. No repository
imports or original conversation are required. Actual Aseprite executable reports
1.3.17.2-x64; no new production Aseprite components are claimed in this stage.

Evidence: `artifacts/ui-workshop-review/config-check.json`, `external-smoke.json`,
`browser-review.json`, `layouts.png` and `comparison.png`. Chrome rendered the
offline study gallery and reference/current-native overlay; both were visually
inspected. The gallery clearly separates the approved art from 15 logic diagrams.
The overlay demonstrates the existing textured72 UI's visible difference from
the approved target; it is not approval of a completed replacement.

## Boundaries and next production work

Preparation/library/tooling PASS does not mean native UI completion. Current
runtime still uses textured72; its accepted nine-template Old Mine pool matches
HEAD exactly, hash `1fdc809dd5a95ef65237d409b1c61859e46a481d023e41ba4f5c78497277826e`.
The same pool hash is recorded in `external-smoke.json`.
No gameplay, saves, actors or old generation behavior changed in this extraction.

Next: production shared frames/buttons/fonts/portraits/HP; per-theme clean map
substrates, transparent room vignettes/props/seals; native Godot composition and
truthful data-driven paths/state; then a domain adapter promoting tested legal
content into the runtime generator. Preserve the accepted sample's geometry,
materials, type and proportions, with scrolling for longer readable charts.
Compare actual native captures at target sizes and test real interaction before
calling the requested 1:1 recreation complete. Family approval is already given.

Review1 physical acceptance and reviews2..6 remain pending. No new autonomous
timer, remote repository, commit, push or public license change was requested.
