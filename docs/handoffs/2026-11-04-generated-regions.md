# Latest handoff: seeded illustrated regions

User explicitly approves the proposed next step: "Dobram to dawaj". Stage80
implements terrain/river/crossing-first region generation and its playable pilot.
No commit/push was requested. Master remains564dbdae; local stages78..80 and the
user's hand-painted revision9 must be preserved. Do not reactivate the expired
two-hour batch or old art/character work.

Owners: world013/presentation039, slices013/039; milestone80 in presentation022.
Read [stage80 QA](../qa/2026-11-04-generated-regions.md) and
[native gallery](../design/generated-regions/2026-11-04/index.html).

Three presets: marches, woodland, highlands; positive seed1..1000000000; version1.
Each snapshot stores192x108 semantic geography, eroded main/tributary channels,
bank-to-bank crossings, six separated functional sites, five detailed road paths,
NPC waypoints, diagnostics and checksum. Bounded deterministic retries reject
disconnected terrain. Whole snapshots are saved; loading never rerolls geography.
Definition/navigation are profile-specific; previews never replace Terrain.current.

Region Foundry: seed/preset, Generate, previous/next, read-only route preview and
semantic overlay, Play / Resume, Current company and Authored Marches. Generated
geography is immutable; the painter remains authored-only. The generated live map
uses exactly the preview/saved geometry, existing motion79 and real company/NPC,
contracts, gear, managed mine packing/ordinary retreat, town services and persistence.
Each seed/preset has its own `user://qa_living_world_generated_v1_<preset>_<seed>.json`.
Restart and select the SAME seed AND preset to resume that company. A selector
failure restores the previous playable session and preserves corrupt file bytes.

Builtin imagegen + Aseprite supplies sixteen transparent painted symbols and a
continuous neutral ground wash. English prompts/raws/manifest under
assets_src/region_symbols/2026-11-04/; editable sources under
assets_src/aseprite/region_symbols/. Repeatable Lua normalization/export and
`tools/world/audit_region_assets.py --export` prove exact runtime byte equality.
Runtime assets are new siblings, not edits of the approved atlas. Continuous
terrain weights replace the rejected square-cell first preview; mountains are
spaced and bridges align with actual banks. New appearance awaits USER review.

Proof: generator443checks/72inputs including cold replay; session20; foundry79;
four new Python tests/67 overall; strict reference snapshots/full-profile schemas.
Native final164checks/66pointer actions/24captures,720p/1080p, zero diagnostics;
actual bridge crossing and real mine travel/gear/packing/Start/ordinary retreat/
return/selector resumption/authored return.694frames/3470 displayed unit samples,
zero blocked samples. No OS input, focus acquisition or player save used.
Full exact-source82/82 PASS, zero errors/warnings, source SHA256:
4621376c2ee0245334c03444f63df0b87adae9aa2a1494cb762a4152f7a6e2a9.
Receipts/preservation proof are retained in stage80 QA/gallery.
These fixtures do not imply physical acceptance or an ordinary played mine win.

Preservation: all119 stage76 approved asset/font files match their manifest;
original atlas516bdc4ad1635f931c79fac9eaaaba0ac041607dc5aacc501593907cd41ea9a5;
designer r9/sourcecopy a5d90d2ff4dbf36d0f3b46856fc30be0812767876cc407e72c3c0067a8a8f327;
immutable archive d208ceb651294cc56318d4aa32bee7a5caa44a7cf9c7ec76d8f54bbf9280e777.
Never run the initial terrain builder over revision9 or rebuild that ZIP.

Next: user launches `& .\tools\qa\start_game.ps1 -Scene regions` and reviews
generated appearance, crossings/weighted smooth travel and same-seed resumption
(L80-01). The authored Marches/r9 remains available for L79-01 movement review.
This first increment retains six existing role names and current contracts;
broader location/content pools and cross-region travel require the next scoped
discussion/authorization. Equipment/battle/courtyard and ordinary physical mine
victory reviews remain saved, not silently closed. Do not infer new publication.
