# Exportable asset catalogue

Status: implemented and accepted (stage2 report)
Date: 2026-11-01

## Ownership and rules

Tooling owns a deterministic catalogue of PNG textures under `assets/`.
`tools/assets/build_catalogue.py` writes sorted unique resource paths, byte size,
SHA-256 and PNG dimensions to `resources/catalogues/textures.json`. No timestamps
or absolute workstation paths appear. `--check` fails on missing, added or changed
assets and never modifies the catalogue. Existing per-sheet extraction manifests
remain the source-processing provenance; this catalogue describes shipped lookup.

`AssetCatalog` owns shared imported-texture lookup. Runtime presentation uses
ResourceLoader and Texture2D.get_image for CPU transformations; it never loads
raw `res://` PNG files with Image.load. Image callers receive independent RGBA8
images, so resizing/tinting one consumer cannot corrupt another. Optional missing
paths return null and are negatively cached; existing deterministic visual fallback
order remains. The catalogue supplies editor lists without exported-directory scans.
No gameplay rule or art content changes in this stage.

Export all project resources, include runtime JSON explicitly, and exclude local
QA overrides, docs, source tools, Python environments and previous artifacts.
Windows x86_64 debug and release presets use the installed matching 4.7 templates.
For reproducible builds, smoke exports temporarily move the owned local profile
into the run directory and restore it in finally. An unmanaged override is
rejected. Reports identify the omitted profile by hash. Do not rely on a local
profile to select an exported entry scene; export uses the tracked project entry.
Export smoke must run the produced executable/PCK from its own directory, load
the catalogue and representative UI, terrain and animated unit textures, and
load App, dungeon, combat and map editor scenes. It must detect Godot diagnostics
as well as nonzero exits. Building a PCK alone is insufficient proof.

Official 4.7 export templates disable CLI script and scene overrides. The
`ExportProbe` autoload does nothing during normal play; explicit user argument
`--qa-export-smoke` requests checks, scene loading and a nonzero failure exit.
The external runner requires the final probe token and one token per scene,
so ignored flags, a partial run or an empty exit-zero process cannot pass.
Its wall-clock timeout and engine `--quit-after` bound test execution.

Stage12 extension (combat overview093/slice101): also require
`SDD_EXPORT_ENCOUNTER_PASS clearing_crossfire`. The opt-in probe loads the
catalogue-authored scenario through the real controller, checks map/roster and
numeric resource UI, then executes ordinary confirmed movement with MP/input
checks. Missing this token fails export smoke even if every generic scene loads.
Use `--max-fps 60` with the600-iteration export probe bound, so its real-time
movement/feedback timer can finish without an unlimited-frame premature quit.
The external wall-clock timeout remains an independent failure bound.

Stage16 extension (world005/combat slice102): require token
`SDD_EXPORT_CAMPAIGN_PASS travel_stash_equipment_road`. The opt-in probe uses
only in-memory campaign data: travel to cart, resolve salvage, actual stash
Equip control, frozen road-fight gear and real CombatDebug launch. It verifies
packaged campaign/item/event resources and gear lock without writing player data.
The external parser rejects a missing token. This is technical boundary proof;
ordinary visible equipped victory/return/restart remains in the live registry.

Stage17 extension (world006/slice006): require
`SDD_EXPORT_TRADE_PASS ravenford_buy_sell`. From a fresh in-memory campaign, the
real town Trading Post Buy/Sell/Back controls buy a16g blade, sell its unassigned
copy for7g and verify gold31, no remaining blade, unchanged assignments and empty
sale state. Negative parser tests reject an otherwise complete run without this
token. It tests packaged offer/item data and UI transactions, not actual play.

Stage19 extension (world007/presentation002): require token
`SDD_EXPORT_INTERFACE_PASS shell_training`. Use a fresh in-memory10-XP fixture,
open Training through the real shell navigation, train Bran, verify level2,
available0 XP, disabled Torin training and footer inside the viewport. This checks
the packaged progression data and new interface controller; it is not live proof.

Stage22 extension (presentation003..005): require
`SDD_EXPORT_POLISH_PASS inventory_services_map`. Using only a fresh in-memory
profile, Buy leather through the visual merchant grid, choose Torin and the tile,
Equip and check retained selection, then travel through the map's Broken Cart
marker and verify pending cart/locked markers. All existing tokens still required.
This proves exported controls/resources/transactions, not native live acceptance.

Actual source and exported-build gameplay on windowed DISPLAY1 is mandatory.
Export smoke is a technical acceptance tool, not a replacement for this playtest.

## Proof

Slice `slices/002_exportable_asset_catalogue.md`; Python catalogue negative tests,
Godot asset-catalogue tests, full verification and isolated Windows export smoke.
Evidence: `docs/qa/stages/2026-11-01-stage-2.md`.
