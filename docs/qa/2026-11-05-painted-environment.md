# Stage83 painted environment and terrain readability

Owners presentation042/slice042; grid024 unchanged. Built-in imagegen generated
one16prop family from the current native Forest Ambush/accepted character reference.
English prompt/raw source/manifest live in assets_src/tactical_environment/2026-11-05.
Aseprite source: assets_src/aseprite/tactical_environment/painted_props.aseprite.
Normalization/export tool: tools/aseprite/tactical_props.lua; registration tool:
tools/assets/promote_painted_props.py.16old PNGs remain byte-identical, all existing
canvas sizes/pivots retained. Editable re-export16/16hashes equal current runtime.

Palette/camera/native game-scale review: desaturated olive/umber/slate, soft painted
edges, upper-left diffuse light and oblique camera match actors better than old
bright faceted props. Trees frame the forest; low brambles/logs leave actors visible.
Agent selected under delegated polish; user art approval still pending.

124checks cover canvas/alpha/padding/aliases/hash provenance/original preservation,
real HUD tooltip and terrain024 values. Export trial caught JSON userdata arrays
serializing as null: materialized plain arrays and added registration guard.
Native first import trial caught missing imported16PNG resources; explicit Godot
import resolved them. Failed artifacts remain for audit, are not PASS evidence.

Final native `painted-props-native-imported`:1757checks,422engine-local clicks,
22GPU captures,720p/1080p,0errors/warnings. Forest/Mine complete ordinary-control
victories48/43commands at both sizes; full attack/death frames sampled, no rejected
or forced command. These engine-local fixtures are distinct from physical desktop.
Actual Sky Forest play separately confirms new art,4MP cover entry, tarczownik
movement and a normal aimed shot14->11HP. Continued full battles in stage84.

Full source `tactical-polish-full-first`:86/86PASS,0diagnostics; exact fingerprint
c18c1ae1680c5b94c9639098fe7f71a14d905c0b6bceb72fec3eef4753f461ce
recomputed equal after run. Source subsequently changes only if a live-play
defect requires a new stage/final receipt. Stage84 physical Mine play exposed an
incorrect no-LOS claim in the new explanation and older presentation030 wording.
Corrected both against existing combat/grid022: intermediate blocked cells stop
ranged targeting. No resolver, terrain costs, hit formulas or animations changed.
Updated imported-texture alpha/canvas checks avoid source-image export warnings:
124checks PASS,0diagnostics. Native tactical-environment-los-final PASS,12engine
actions at720p/1080p,0errors/warnings; actual third desktop battle shows corrected
blocked-cell popup. The earlier receipt above remains historical, not final source.

Live investigation: after aimed shot an already-open tile tooltip still showed
oldHP while actor label correctly showed11. Check native tooltip popup lifetime
in stage84; do not call the whole combat polish fully accepted yet.
