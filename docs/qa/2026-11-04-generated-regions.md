# Stage80: generated region geography and illustrated playable pilot

User authorizes the proposed generator: "Dobram to dawaj". Owners world013 /
presentation039 and corresponding slices. This stage is implemented locally on
master564dbdae alongside preserved stages78/79. No new commit/push was requested.

## Review

```powershell
cd C:\Users\karol\Desktop\Gierka\game_dir\sdd-game
& .\tools\qa\start_game.ps1 -Scene regions
```

1. Inspect seed2087 / Marches,42 / Deep woodland,170717 / Highlands. Change the
   seed/preset, Generate and click a site to preview the real safe route/cost.
2. Toggle Terrain overlay to compare rivers, peaks, forest and crossings with
   actual navigation. Preview never advances or saves the current company.
3. Play / Resume opens that seed/preset's own living company. Travel through a
   crossing, forest and pass; check pause/resume,1x/2x/4x and independent NPCs.
4. Accept the mine contract in Ravenford, travel to Old Mine, open Company & gear,
   return to the map, prepare owned supplies, Start Expedition and ordinarily
   retreat. Return to Ravenford; retreat must not clear/reward the contract.
5. Restart Regions, select the same seed AND preset, Generate, Play / Resume.
   Exact geography, clock, company and progress resume. Authored Marches opens
   the preserved original pilot/designer revision9. Current company returns from
   preview without a switch; Back to atlas returns to the ordinary campaign.

Separate generated saves:
`user://qa_living_world_generated_v1_<preset>_<seed>.json`.
The authored pilot remains `user://qa_living_world_v1.json`; ordinary campaign
remains `user://campaign_v1.json`. No QA fixture uses these player slots.

[Native gallery](../design/generated-regions/2026-11-04/index.html).

## Implementation and limits

Deterministic192x108 elevation/moisture/coast, eroded downstream main/tributary
channels, bank-to-bank crossings, coherent biomes/ridges and a traversable saddle.
Separated accessible sites are placed after terrain; weighted roads connect all
six roles. Maximum eight deterministic attempts reject disconnected candidates.
Snapshots retain version, full geometry, checksum and diagnostics. Profile-owned
navigation prevents previews or other seeds from redirecting the active company.
Generated geography stays immutable; manual painting remains authored-only.

This is the first playable geography generator, retaining the current three towns,
two factions, six role names and three contracts. New content families, regional
transition travel and a complete persistent multi-region world remain later work.
Physical visual/feel acceptance and ordinary played mine victory remain unreported
(L80-01 and L77-01). Native pointer fixtures do not close those gaps.

## Evidence

- Generator443 checks:72 seed/preset combinations, cold deterministic replay,
  exact JSON/checksum roundtrip, coverage/separation/connectivity/road safety,
  rejected corrupt/version/false-bridge snapshots and authored isolation.
  Final full-suite batch maximum650ms; attempts0:54,1:10,3:8.
- Session20: actual generated mine course, managed packing/ordinary retreat,
  independent navigation, atomic mid-route save/reload, failed-write rollback,
  per-seed pilot resumption and failed-switch restoration with corrupt slot intact.
- Foundry UI79:720p/1080p control/label fit, read-only previews, dirty seed guard,
  overlay, exact preview-to-live identity, immutable terrain and resumption.
- Four new Python contract/provenance tests;67 Python tests overall. Three actual
  generated snapshot examples and a complete generated campaign pass strict schemas.
- Final native `regions-native-final`:164checks,66 engine-local pointer actions,
  24captures across720p/1080p, zero errors/warnings. Actual bridge banks/crossing,
  mine travel, gear roundtrip, packing/Start, ordinary retreat, return, selector
  resumption and authored return.694frames /3470 displayed company/NPC samples,
  zero blocked samples. Host remained minimized/unfocused; no OS input/player save.
- Full-source final `regions-full-final`:82/82 PASS,67 Python tests, zero errors
  and warnings. Source SHA256:
  `4621376c2ee0245334c03444f63df0b87adae9aa2a1494cb762a4152f7a6e2a9`.
  Receipt retained as source-verification.json in the gallery. Physical review
  remains AWAITING_INTERACTIVE, not inferred from automated success.

Raw reports/logs/captures: `artifacts/qa-runs/regions-native-final/` and
`artifacts/qa-runs/regions-full-final/`. Portable copies of receipts and nine
unaltered native screenshots are in the gallery directory.

Initial native-first preview passed functional checks but square terrain patches,
overcrowded snow mountains and misaligned bridge symbols were visually rejected.
Continuous one-hot terrain weights/ground wash, spaced peaks and geometry-aligned
native masonry decks replace them. `regions-flow-first` has142 functional checks
but is FAIL: an accidentally requested unrelated generic App exercise ran on the
living scene and raised two missing-shell diagnostics. It is not final proof.
The final correct regions-only fixture passes with zero diagnostics.

## Art and preservation

Builtin imagegen generated a transparent4x4 symbol family and a continuous ground
wash using our approved atlas as style reference. Raw outputs, exact English
prompts and SHA256 manifest:
[source record](../../assets_src/region_symbols/2026-11-04/README.md).
Editable sources: `assets_src/aseprite/region_symbols/`; runtime PNGs:
`assets/ui/world/region_symbols.png` and `ground_wash.png`.
Repeatable normalization/export: `tools/aseprite/region_symbols.lua`.
`python tools/world/audit_region_assets.py --export` verifies nine hashes and exact
byte-identical editable exports. Source red matte residue is removed in Aseprite.
Texture catalogue contains10614 entries; original atlas pixels are untouched.

All119 approved atlas asset/font files still match the saved stage76 manifest.
Original atlas SHA256:516bdc4ad1635f931c79fac9eaaaba0ac041607dc5aacc501593907cd41ea9a5.
Designer r9 runtime/source copy:
a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327.
Immutable stage76 ZIP:
d208ceb651294cc56318d4aa32bee7a5caa44a7cf9c7ec76d8f54bbf9280e777.
Gallery preservation.json retains the119-file check and nine screenshot hashes.

Next: user reviews generated appearance/travel/resumption, then discuss a broader
site/content pool and regional transitions. Equipment/battle/courtyard review
queue remains saved. No new autonomous batch or publication is inferred.
