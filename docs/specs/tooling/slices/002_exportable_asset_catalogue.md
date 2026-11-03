# Slice 002: exportable textures

Owner: `../002_exportable_asset_catalogue.md`.

| ID | Scenario | Expected |
| --- | --- | --- |
| A2-01 | Generate twice, check unchanged catalogue | Identical bytes and sorted unique paths |
| A2-02 | Add, remove or modify PNG; corrupt catalogue | Check fails without writing |
| A2-03 | Load UI, terrain and character textures | Imported textures and dimensions match |
| A2-04 | Request same texture and mutate copied image | Texture cached; other consumers unchanged |
| A2-05 | Missing optional texture | null, deterministic fallback remains available |
| A2-06 | Map-editor floor/decoration catalogue | Stable nonempty lists, all resources load |
| A2-07 | Full suites and four scenes | No runtime raw-PNG warnings or errors |
| A2-08 | Export, run standalone executable/PCK | Catalogue and four scenes work outside source cwd |
| A2-09 | Personally play source and exported game | UI/props/units animate, normal move/attack, dungeon interaction |

Automated: `tests/test_asset_catalogue.py`, `scripts/presentation/asset_catalog_tests.gd`,
`tools/qa/verify_project.py`, `tools/qa/export_smoke.py`. A2-09 is recorded separately
in the stage report. The later2026-11-01 user override permits the stages9..12
background batch before accumulated live testing; it does not waive acceptance.
