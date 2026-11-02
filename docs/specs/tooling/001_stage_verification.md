# Stage verification

Status: stages0..7 implemented and accepted
Date: 2026-11-01

## Ownership

Prepared UI releases always start App.tscn, regardless of the source launcher's
current dungeon/combat/map-editor preview. Rewrite only the owned release profile;
preserve the source profile and report the actual launch scene in metadata.

`tools/qa/verify_project.py` orchestrates existing checks. It does not implement
game rules. Use the repository's `.venv` and Godot 4.7 stable. The binary may be
supplied with `--godot`; the existing workspace installation is the default.

## Automated contract

- Import project resources before tests so checks can run on a fresh checkout.
- Run `tools/validators/validate_all.py` with the runner's Python interpreter.
- Discover every `scripts/**/*tests.gd` suite in deterministic path order.
- Load App, Ravenford town, DungeonDebug, CombatDebug and CombatMapEditor with a bounded frame count.
- Each process has a wall-clock timeout; a timeout fails the run.
- Capture stdout and stderr, command, exit code, duration and diagnostic counts.
- Nonzero exits and `SCRIPT ERROR:`, `ERROR:` or assertion diagnostics fail a check,
  even if Godot itself exits zero. Existing warnings are reported separately.
- A failed import stops dependent Godot checks. Independent Python validation still runs.
- Store the run ID, UTC timestamp, Godot version, Python identity, Git HEAD, dirty
  status and source fingerprint alongside results in ignored `artifacts/qa-runs/`.
- Invalid arguments, missing executables and incompatible Godot versions fail
  explicitly. A failed or incomplete run must never produce a PASS.

## Interactive contract

`tools/qa/start_game.ps1` launches one requested project scene on Windows
`DISPLAY1`, the additional monitor selected explicitly by the user. It resolves
the display by device name, centers a window inside its working area and fails
if the monitor is absent. It must not fall back to the main screen or terminate
existing project/user processes. The launcher records requested display bounds,
position, size, scene and the newly created PID. Current display dimensions must
come from the native display mode in physical pixels: WinForms alone can report
DPI-virtualized sizes. Manual physical-pixel placement was found unreliable under
mixed DPI. Instead, use Godot's own screen centering and size settings through a
local ignored `override.cfg`. DISPLAY1 must be the leftmost display, matching
Godot screen 0 on this workstation; fail if this known layout changes. This
workstation-specific launcher is not a general monitor mapping library.
An explicitly requested interactive preview must launch with normal visible window
state, never WindowStyle Hidden. Background GPU fixtures keep their separate
minimized/no_focus settings. The interactive launcher must record an early process
exit and its log paths, rather than imply that a preview is still running.
`-ConfigureOnly` prepares the same settings for the Project Manager's Run action,
which permits an ordinary, non-elevated game when this CLI is elevated. Refuse to
overwrite an override file not owned by this launcher. The window is windowed.
This records launch intent;
it does not establish visual or gameplay acceptance.

For input-delivery diagnosis, `start_game.ps1 -TraceInput` may pass
`--qa-input-trace` to DungeonDebug. The scene logs its actual window mode,
screen, physical position/size and received key/mouse-button events to stdout.
The trace is opt-in, does not synthesize input or change game rules, and does not
turn a scripted state mutation into hands-on acceptance. Normal launches do not
log input. Use the trace only for this game's window.

An actual playthrough requires observing the visible game and operating its
normal controls. Headless tests and domain simulations cannot satisfy this gate.
Debug Win cannot prove a real combat victory. Reports list automated results and
interactive evidence separately. Normally a missing interactive test leaves the
stage open and prevents proceeding to the next implementation stage. Explicit
user override, extended2026-11-02, permits stages9..29 background implementation after
each automated PASS, with stages8..29 actual tests accumulated in
`docs/qa/live-test-scenarios.md`. Acceptance stays open until that live session.
No desktop input/window activation is authorized while the user uses the PC.

For presentation006 native reviews, the existing ExportProbe autoload accepts
the explicit --qa-campaign-review user argument in source and packaged builds.
It replaces the normal scene with an isolated campaign fixture and renders through
a SubViewport while the host is initially minimized/no_focus. Export templates
disable CLI scene/script overrides, so the same opt-in entry is used in both.
The fixture must load an in-memory campaign before actions, inject only viewport
events, verify no focus acquisition and report physical acceptance NOT_RUN.
Presentation007 uses the same boundary with --qa-play-review and renderer --suite
play for dungeon and combat. Scene reload, movement/MP, rejected targets and
terminal fixtures use real Controls/resolver/animations; never label those fixtures
as a physical ordinary battle. Preserve the source profile and player save.

## Stage sequence

0. Local environment, validation runner, DISPLAY1 launch and baseline playthrough.
1. Playable Dungeon Beta full-loop QA and deterministic smoke runner.
2. Exportable asset catalogue and export smoke test.
3. Combat and dungeon presentation component extraction.
4. Unified map authoring pipeline and workbench.
5. Generated dungeon quality gates and seed sweep.
6. World/town integration.
7. Final regression, exported build and hands-on verification.

Every stage needs its owning specs and acceptance slice before implementation,
all named checks, an actual playthrough on DISPLAY1, and a persisted stage report.
Do not mark a stage complete merely because its implementation compiles.
