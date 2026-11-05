# Stage81: larger scrollable mixed-biome regions

User approves stage80's map style, requests larger scrollable maps and biome
variation. Owners world014/presentation040 and slices014/040. Existing local
stages78..80 and authored designer revision9 are preserved. No new Git publication.

Launch `& .\tools\qa\start_game.ps1 -Scene regions`. Select **Large**, seed/type,
Generate, then Play / Resume. Wheel zooms around the pointer; RMB/MMB drags;
Overview fits the whole region; Company/Center returns to the real party/local
view. Clicking the mini chart moves only the camera. Left map/site click orders
travel (preview only in Foundry). Camera remains usable while paused.

V2 terrain384x216 is four times v1 area, with wet/dry/upland zones and coherent
forest/open-country/upland transitions. Physical travel scale2 applies to both
company and NPC traces/estimates. Same six role ids/current contracts; broader
content/cross-region travel remains later work. Source art is reused unchanged.
Version-specific slots preserve Classic same-seed progress. Resume the same seed,
preset AND size. Authored Marches retains the original separate pilot/r9 painter.

## Proof

- `large-regions-full-final`:84/84 PASS,68 Python tests, zero errors/warnings.
  Exact source SHA2564909f7b7208d784c0de24749cb2081728ee9c133d0873306162e06f945bf8ab6.
- V1 generator443 checks/72inputs and frozen stage80 checksum compatibility;
  large generator134 checks/24inputs, max1486ms in the final suite; valid topology,
  climate coexistence, exact JSON/cold replay and scaled committed traces.
- Camera/UI46 + foundry79 + generated session23 checks PASS. Strict v1/v2 schemas,
  three large snapshot references and a session-owned large profile pass.
- `large-regions-native-final`:236 checks,90engine-local actions,36captures across
  720p/1080p, zero diagnostics. Anchored wheel, RMB pan/release, clickable chart,
  read-only preview, scaled continuous travel through a real bridge, gear,
  mine packing/Start, ordinary retreat/return, resumption and authored return.
 1212frames/6060 displayed unit samples, zero blocked positions. Host minimized,
  unfocused; no OS input or player slot. This is not physical acceptance.
- Initial native-first236 checks passed; final adds deferred initial framing and
  consistent disabled-button sizing. Shader uniform constant/schema bounds were
  corrected during focused development before the final full/native receipts.

Raw evidence: artifacts/qa-runs/large-regions-full-final and
artifacts/qa-runs/large-regions-native-final. Portable receipts and nine unaltered
captures: [gallery](../design/large-regions/2026-11-05/index.html).

The user subsequently releases the desktop and authorizes a two-hour travel /
tactical polish batch. Visible review is tracked in2026-11-05-two-hour-polish.md.
CLI-launched elevated Godot ignored Sky input; a normal Sky-launched Project
Manager game responds. No physical PASS is inferred from that diagnosis alone.

Preserved r9 SHA256a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327;
the stage76 archive,119 original atlas/font files and nine region-art provenance
hashes remain the reference. Stage80 appearance is USER approved; the larger
variant and ordinary played mine victory remain separate review items.
