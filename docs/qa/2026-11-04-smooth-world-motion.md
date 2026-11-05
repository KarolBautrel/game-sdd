# Stage79 — smooth motion on designer terrain revision9

User accepts the hand-painted map as a good basis and reports interrupted
movement. This stage fixes motion only, then proposes the next step. No new
publication or broader implementation batch is authorized.

Owners: world012/presentation038 and slices012/038. Base company speed, terrain
costs, fifteen-minute ticks, accepted atlas graphics and gameplay ownership stay
intact. The user's runtime terrain is byte-identical to its turn-entry hash:
`a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327`.
An exact durable copy is in assets_src/world_navigation/2026-11-04/.

## Causes and corrections

- The renderer recomputed A* between every pair of snapshots. Even a forward
  move inside one cell detoured back through that cell's center: reproduced
  dx=-0.0002604127 before the fix. Rendering now samples exact committed movement
  traces, timed by actual weighted terrain cost. No second navigation path.
- Two independent clocks and pause resets restarted interpolation. The fixed
  simulation accumulator now owns render phase too, preserving residual time
  across pause/resume and1x/2x/4x. The visual buffer is one strategic tick behind
  committed simulation; first movement fills that buffer. Explicit encounter
  transitions synchronize to the actual contact position before opening a modal.
- NPCs previously discarded leftover movement at each road waypoint. They now
  carry it through ordinary waypoints; deliberate patrol endpoint guards remain.
- NPC Control visuals snapped to whole pixels. Visible banners now draw at
  fractional map positions with native transparent hit/focus targets, preserving
  tooltip, pointer and keyboard interaction. Hover/focus redraw while paused.
- Exact route endpoint links bypass a redundant cell-center detour only when
  complete segment validation proves safety and non-increasing weighted cost.
  There are no blind river/corner shortcuts. The overlay includes unplayed trace.

Traces publish only after successful campaign commits and never enter saves.
Failed writes preserve both the profile and last published motion. Reload starts
at committed positions. The terrain validator now accepts integral JSON floats
(192.0/108.0) produced by the editor, while rejecting fractional/nonfinite/bool
dimensions. The user's file is not normalized or rewritten.

## Review

Restart the preview so it loads the new scripts:

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene living-world
```

Travel Ravenford->Saltwatch and the Old Mine at1x/2x/4x. Watch the company and
NPCs at bridges, curves and ordinary route points. Pause midway, wait, resume
and change rate: no snap, backward reset or fresh full-tick resume delay. Compare
forest/slopes with roads; actual terrain slowdowns and patrol guard stops remain.

Next proposed stage, after this physical movement check: seeded region design
from coherent terrain and crossings, followed by settlements, roads and dungeon
sites. Keep the designer's Marches as the first authored region/reference.
Do not implement that proposal without a new instruction. The existing full
ordinary-mine-victory case remains unreported; these checks do not replace it.

## Verification

Focused living_motion_tests.gd **52/0**, terrain_navigation_tests.gd27/0,
living_world_tests.gd28/0, living_world_session_tests.gd41/0 and living UI97/0
passed during implementation. Seven focused Python terrain/reference tests pass.
The deterministic movement suite covers30/60/144FPS at1x/2x/4x, forward motion
without stationary reset frames, equal distance/clock after equal elapsed time,
pause/resume/rate phase, within-cell endpoint geometry, weighted boundary timing,
NPC budget carry, deliberate guards and atomic transient rollback.

Final commands and reports:

```powershell
.\.venv\Scripts\python.exe tools\qa\verify_project.py --run-id smooth-world-full-final
.\.venv\Scripts\python.exe tools\qa\render_campaign.py --run-id smooth-world-native-complete --views motion,terrain,living --sizes 1280x720,1920x1080 --timeout 480
```

The complete core run passed **78/78**, errors0/warnings0; native gameplay
regression passed **318checks/114pointer actions/38captures** at720p/1080p.
Final image inspection then caught NPC badges drawing below site labels. A
draw-order-only correction puts the fractional banner layer above the cards,
with mouse-ignore so native targets retain input. Final motion-layer native
review passes **78checks/28pointer actions/8captures** with zero diagnostics.
It retains540frame samples across both sizes; unrecorded2x/4x sampling intervals
stay near the fixture's30FPS target. These timings are fixture evidence, not a
claim about uncapped performance or every workstation.

Final-source full command after this layer correction:
`tools/qa/verify_project.py --run-id smooth-world-layer-final`.
Result: **78/78 PASS**, including63Python tests and all eight scene boots,
errors0/warnings0. Final source SHA256:
`b5342ed950fbba66a39d1f9d3693711a6708a7e84853e42032a3e560d7bc5f6e`.
It matches the final workspace and final motion-layer native receipt exactly.
Final native command:
`tools/qa/render_campaign.py --run-id smooth-world-native-layer-final --views motion --sizes 1280x720,1920x1080 --timeout 180`.
[Retained frame gallery/receipts](../design/smooth-world/2026-11-04/index.html).

The native fixture samples all five displayed parties every frame on the actual
designer mask at1x/2x/4x, verifies terrain safety, displacement bounds and absence
of moving-company stall frames, then exercises actual pause/resume controls.
Per-frame records and real GPU still sequences are retained. Displacement bounds
use the presented simulation time: PNG readback can occur between the frame
signal and node processing, so raw wall-clock sample intervals are not a valid
animation clock. `smooth-world-native-first` preserves that measurement failure;
`smooth-world-native-clock-fixed` passes before the final endpoint refinement.
The complete final run also repeats terrain painting/save refusal, river travel,
equipment, mine packing/ordinary retreat and natural faction contact.

Native fixtures are minimized/unfocused, use engine-local input and isolated
memory/QA files, and never touch a player save or activate desktop controls.
Physical feel acceptance remains pending. Source/full/native compact receipts
and the frame gallery are retained under docs/design/smooth-world/2026-11-04/.

API reference for the diagnosed default Control snapping:
[Godot4.7 Viewport](https://docs.godotengine.org/en/4.7/classes/class_viewport.html#class-viewport-property-gui-snap-controls-to-pixels).
