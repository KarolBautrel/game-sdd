# Resume: player review step1, dungeon visual corrections

Latest user direction2026-11-04,72c: flattened72b looks much worse. Restore the
previous textured72 as temporary current, save the versions, research fantasy
game-UI skills/packs/MCP and make a separate improved proposal. This supersedes
the72b follow-up described in the history below. No new publication requested.

Active checklist: docs/qa/2026-11-04-player-review-checklist.md. Order is dungeon,
equipment, world travel, forest battle, mine battle, courtyard prototype.
Step1 is ACTIVE_ART_DIRECTION_REVIEW;2..6remain PENDING. The old autonomous
two-hour queue has finished. Do not jump to the town campaign bridge B while this
new first review item is active.

The approved comparison is the current world-travel UI. The aged/worn material
direction is acceptable, but visible small repeating square textures are not.
Fix backdrop/panel material repetition, integrate bottom party portraits and
complete current/max HP, use a consistent HP bar style/color, and fit all text
inside frames. Room plates need truthful readable connections again. The latest
request supersedes omitting all overlays; previously rejected heavy pipes/crosses
remain rejected. Proposed replacement: quiet map-like paths behind room plates
and a clear current/selected route, without false graph edges or label crossings.

Before-stage72 code comparison (not visual approval): both shells used campaign_skin fonts
and assets. ExpeditionChrome tiles leather over the full background; shared
StyleBoxTexture frames tile their center spans. CampaignShell also tiles leather,
so the defect cannot honestly be explained by a dungeon-only file mismatch.
Different exposed areas, sizes and composition can make repetition more obvious.
PartyCard fills its HP bar with the per-hero accent, explaining the different
colors. Native screen evidence is still needed for the exact clipping cause.

Owning visual spec: presentation026 pending review addendum; existing027 keeps
preview/confirm/event/domain guards. Preserve approved actors/animation and saves.
Use game-ui-ux/godot-ui-control and the actual world view as the direct reference.
No new style exploration, gameplay rule change or extra roster work is requested.

Previous delivered checkpoint and source proofs:
2026-11-04-autonomous-polish.md, master bce3c616. The new checkpoint documentation
is local until publication is requested. No push or physical gameplay is claimed.

Stage72 details: qa/2026-11-04-dungeon-visual-cohesion.md; owner031/slice031.
Dungeon-local quiet Aseprite materials, dark world-family panels, horizontal
whole-portrait/full-HP cards with one red bar, actual passive routed corridors.
12/12headless suites PASS (new cohesion692checks), validator PASS, native263checks /
44engine-local clicks /40captures at720p..4K PASS. Inspect persisted review1
images in docs/design/dungeon-ui/review1/. Physical/user visual acceptance remains
open; no new OS play was attempted in this turn. Next: player review1 retest via
start_game.ps1 -Scene dungeon, Use Old Mine, Start Expedition. Do not automatically
advance review2, town B/C, the completed timer or a publication queue.

Latest72b follow-up: user says "better" but rejects pixelated background motifs
around frames. Corrected the remaining stretched-grain edge strips via Aseprite:
matte fills and uniform rail cross-sections with approved corner shapes. A
continuous charcoal shader supplies screen-pixel grain around panels. The old
hide raster remains a reference, not the runtime backdrop.696cohesion checks,
art99/0, route31/0, party layout and validator PASS; native198checks /33engine
actions /30captures at720p/1080p/4K PASS. Current full view and1:1 edge crops in
review1/material-fix/. User retest remains next; no OS play or push claimed.

72c complete:72b is REJECTED_BY_USER; textured72 source/export snapshots saved
with hashes under assets_src/ui_review_baselines/. Its restored native1080p
route PNG matches preserved review1/route-1080p.png exactly.692cohesion checks,
validator and native32checks/9actions/6captures PASS. game-ui-design and
frontend-design installed/read; pack/MCP research and the generated Expedition
Ledger concept are in research-2026-11-04/. Main candidates: paid Moon Tribe
PNG/PSD4K, free Bloodlines textures. Figma already available; no new MCP or
paid assets acquired. Concept is design-only, no character/scene replacement.
Next: user chooses the look before further native UI art work. Do not advance
reviews2..6, town B/C, publication or the expired timer.

Latest follow-up asks for an immediate sample using game-ui-design, inspired
especially by free Bloodlines assets without1:1copying. Inspected publisher's
public preview sheets; produced independent Ashen Cartographer v2 with ashen
chart, original iron fittings/mining seals and crimson emphasis. Saved in
research-2026-11-04/ashen-cartographer-concept.png, with BRIEF-v2, GENERATION-v2
and manifest-v2. Await visual selection; no new native implementation authorized
by a sample request. Textured72 remains temporary current.

Superseded current task: user now approves this v2 mine look and requests related
archetype samples before implementation. Read the newer handoff linked at the top
of CONTINUE_HERE:2026-11-04-exploration-archetype-art.md. Four-family gallery ready;
new themes await review, native production remains deferred.
