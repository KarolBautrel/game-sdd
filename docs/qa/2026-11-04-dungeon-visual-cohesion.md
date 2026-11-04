# Dungeon review1 correction — stage72

Status: IMPLEMENTED / AUTOMATED_PASS / AWAITING_USER_RETEST. User explicitly
authorized this dungeon-only work with "DO dziela". Reviews2..6remain pending.
No commit, push, packaged release or physical desktop play is claimed.

Latest72c supersedes72b: the user rejects the flattened result and selects
textured72 as temporary current.72b proofs below are historical, not approval.
Use `review1/route-1080p.png` for the current screen; both snapshots are retained.
Research and a separate concept: `docs/design/dungeon-ui/research-2026-11-04/RESEARCH.md`.

Owner: presentation031 and slice031, extending026/027. The approved world-travel
screen was inspected directly as the reference for dark frames, cream/gold text,
Cinzel headings and Source Sans body text. Shared world skin/assets are unchanged.

Changes:
- Aseprite exports the approved hide crop at539x539and keeps original brass
  border pixels in quieter dungeon-local frame/button derivatives. Background
  uses a single aspect-cover texture; local nine-slice centers stretch once.
  Dark map/inspector panels replace the large bright parchment surfaces; the
  illustrated chart and narrative modal retain parchment. No repeated square
  patches were observed in the reviewed native captures.
- Horizontal company cards show whole aspect-fit portraits, names, current/max
  HP and identical red health bars. Feedback has real reserved line height and
  a full tooltip; compact feedback may show only two lines.
- Passive fine brass/ink routes derive from actual corridors. Cached display
  geometry avoids unrelated room plates; collision-safe simplification removes
  grid stair steps. Only the selected real adjacent route is emphasized. Graph
  routing does not change gameplay adjacency or consume resources.
- Authored and generated layouts keep their scrolling and room hit targets;
  selection/confirmation, event focus, locks, oil, hazards and rewards remain.

Verification:
-12/12focused/existing headless suites PASS, no diagnostics: visual cohesion,
  route preview, party layout, art direction, exploration HUD, HUD components,
  entry selection, state model, procedural draft, generation quality,
  dungeon-run session and campaign session. New cohesion proof:692checks/0
  failures across1280x720,1920x1080,2560x1440,3840x2160and generated D1/D2/D3.
- Validator PASS. Texture catalogue10549matches source PNGs. `git diff --check`
  PASS. No accepted character art or animation changes.
- Native Windows GPU fixture:263checks,44engine-local pointer actions,
 40captures,0errors/0warnings, at720p/1080p/1440p/4K. Logical UI2560x1440for
  physical widths>=1920, matching the established review harness;720p direct.
  Covers packing, preview/confirm, shrine, rubble, oil, loot, generated D2
  selection/end scrolling, full and injured health. The injury image is an
  explicitly synthetic presentation fixture; existing party tests prove real
  model injury/recovery refresh. No player save or desktop input was used.
- Inspected native authored, generated, compact injured, modal and4K packing
  images. Persisted examples: `docs/design/dungeon-ui/review1/`.
  Detailed local logs: `artifacts/qa-runs/dungeon-polish-72-before/`; final GPU
  report/captures: `artifacts/qa-runs/dungeon-polish-72-final/native-review.json`.
  Draft captures with routing errors are superseded by the clean final run.

Reproduce native fixture:

```powershell
.venv/Scripts/python.exe tools/qa/render_campaign.py --suite play --run-id dungeon-review1-retest --views dungeonpolish --sizes 1280x720,1920x1080,2560x1440,3840x2160 --exercise --timeout 210
```

Player retest on DISPLAY1:

```powershell
& .\tools\qa\start_game.ps1 -Scene dungeon
```

Choose **Use Old Mine**, then **Start Expedition**. Inspect all six routes,
select a destination, travel and resolve its event. Check Bran/Torin health and
framing. Also inspect generated content and compact scrolling if desired.
L67-01/review1 remains open until the user's visual/physical retest; automated
input is not OS play or user approval. Do not advance equipment review2 yet.

## Follow-up72b — pixelated motifs around frames

Player feedback: improved screen, but background motifs around frames still
look pixelated. Inspection of the native1080p frame-edge crop confirmed that
the previous center-only cleanup left grain in the nine-slice edge strips.
Those strips stretched into large streaks. The [Godot nine-slice documentation](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html)
also describes distortion from stretching unmatched raster regions.

Updated the repeatable Aseprite export: retain the approved brass corner shapes,
use constant cross-sections for straight rails, and matte dark interiors. Both
horizontal and vertical strips are now uniform along their stretching axes.
The surrounding backdrop uses a continuous charcoal vignette with faint static
grain in physical screen pixels. The old539x539hide export remains a provenance
reference and is no longer enlarged at runtime. Fonts, layout, routes, HP and
world-travel assets remain as before this follow-up.

Proof: cohesion696checks/0failures, art-direction99/0, route-preview31/0 and
party-layout PASS; validator and `git diff --check` PASS. Log diagnostics are
clear. Source native GPU review `dungeon-polish-72b`:198checks,33engine-local
pointer actions,30captures at1280x720,1920x1080and3840x2160,0errors/0warnings.
No player save or desktop input. Focused logs remain in
`artifacts/qa-runs/dungeon-polish-72-before/*72b.log`; native report/captures in
`artifacts/qa-runs/dungeon-polish-72b/`.

Inspected native720p full screen and Aseprite-cropped1080p/4K edge images at
actual pixel size. Before/current crops and the current full1080p preview are
persisted in `docs/design/dungeon-ui/review1/material-fix/`. Enlarged grain bands
are removed; rail width and corner shapes remain legible. This is agent visual
inspection, not a new user approval. Review1 remains AWAITING_USER_RETEST.
