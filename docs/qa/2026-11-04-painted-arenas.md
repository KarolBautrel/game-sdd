# Stage70 authored tactical arenas

Status: IMPLEMENTED / AUTOMATED_PASS / AGENT_GPU_VISUAL_REVIEW /
AWAITING_INTERACTIVE. Owners: presentation030/slice030, tooling003, combat092/024.

Two canonical14x11TMX arenas and derived encounters reuse all seven approved
pilot actors and their unchanged stats/kits/PNG/cel timing. Forest has woodland
floor, broken obstacles and broad flanks; mine has one-cell/two-cell crossings,
sparse piers, cover and a ranged rise. No campaign pool/balance/LOS change.
Builder exports/checks derived data without rewriting canonical TMX. Named
titles/actors and compact720p chrome preserve readable board area.

Proof:
-53Python tests PASS, including canonical drift, connectivity, reachable spawns,
 alternative crossings, retained default and actor-data equality. Validator PASS.
-Arena2292/0: active victories48/43commands, passive defeats208/209commands, no
 rejected AI action or800-command stall, correct floor costs/materials and gait.
-Complete autonomous-polish-70-final:65/65checks PASS, including all Godot tests,
 combat slices, import and5scene boots;0engine errors/warnings. Runtime code then
 stayed unchanged; additional native full-battle QA/docs were added separately.
-Native layout painted-arenas-70-v2:278checks/18engine pointer events/12captures
 PASS,720p/1080p/1440p. Reviewed forest/mine/compact views; no actor clipping or
 inspector/tile overlap.720p visible floor exceeds500x280px.
-Native painted-arenas-70-battles-v2:718checks/205engine pointer events/2terminal
 captures PASS. Existing AI selects actions for both teams; normal action/tile
 buttons execute all48/43commands, each compared with resolver after animation.
 Walk0..7, attack0..7, hit0..3, death0..7, shield reaction0..3sampled. Both Victory
 without Debug Win, resource edits or rejected commands.
-Windows debug EXE/PCK export/runtime autonomous-polish-70 PASS from independent
 packaged directory, all scene/campaign/trade/interface tokens,0errors/warnings.
 EXE103055872bytes SHA256
 `6b580a72cca9c31922ff4f7f1519a42debdd856e6852eec39ae46ce0e709231d`;
 PCK274563784bytes SHA256
 `0b145f94168cde0c65f8d757d7f9eed0f558ef5eb4c40f4308c0737196439e64`.

Full initial regression exposed count/path assertions predating the approved
painted roster/greatsword offer. Updated to canonical discovery and distinct
current/archive paths. New test-only numeric Dictionary comparisons normalize
JSON values (TMX floats versus UI integers); a test constant shadowing Godot's
Environment class was renamed. Failed attempts remain in artifacts.

Original roster36text differences were proven exactly CRLF-to-LF-only; all model
summaries/geometry/FBX/PNG/Aseprite bytes unchanged. Environment30JSON metadata
hashes refreshed after verifying28FBX checksums/triangle counts and unchanged
non-JSON hashes. Old/new receipts:2026-11-04-{roster,environment}-metadata-receipt.
No artwork regenerated. OS activation still fails as in67; native fixtures do
not count as physical play/user approval. L70-01 remains open. Next: full town
plan, then bounded isolated mechanical pilot, existing town services default.
