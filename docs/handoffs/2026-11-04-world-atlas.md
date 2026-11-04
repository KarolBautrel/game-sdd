# Latest handoff: world and province atlas

Latest user feedback: the atlas appearance is explicitly praised/approved and
must be preserved. The user questions the fixed map's long-term campaign value
and describes a living mercenary world inspired by Battle Brothers/Mount & Blade,
with factions/contracts and dungeon crawling as the main activity. Preserve the
art; discuss campaign structure before changing gameplay. Visual style card and
discussion-only proposal: docs/design/world-atlas/2026-11-04/APPROVED_STYLE.md and
LIVING_WORLD_PROPOSAL.md. The latter is not an approved implementation spec.
Exact preservation ZIP/manifest:
assets_src/ui_review_baselines/2026-11-04-world-atlas-approved/.
Byte-identical external backup: workspace backups/sdd-game/2026-11-04-world-atlas-approved/.
No new commit or remote push was requested; preservation is local.

The user explicitly selects original review point3 (world) ahead of equipment.
They like the current map but request a much larger interactive world; the
current map can be a province beneath a global overview. This supersedes the
older next-equipment priority, not its saved pending review.

Implemented stage76 under world009/presentation035 and slices009/035: four
provinces, twenty destinations,26roads, native atlas/province browsing and
deterministic multi-leg planning. Actual travel commits one adjacent leg and
stops at existing road events. Old costs, return reserve, atomic saves, v4 and
region001 remain. New destinations are travel/description sites; no new dungeon
interiors/services/loot. Authored world geography, not a randomized world generator.

Accepted Marches PNG is byte-identical. Four new map plates use its style,
built-in imagegen and Aseprite. Raw prompts, source PNGs, editable sources,
reproducible exporter and12file hashes are saved in assets_src/world_atlas/.
Preserve the accepted Ashen dungeon and painted actors; neither was reworked.

Focused atlas170/0, campaign interface2468/0 and dark-fantasy218/0 PASS. Native
final roundtrip fixture362checks/58pointer clicks/20captures plus Enter at720p/1080p
PASS. Full source verification and final-source native receipts are recorded in
[stage76 QA](../qa/2026-11-04-world-atlas.md); read its latest status. Initial
full sweep caught party-summary and narrow-label overlap, repaired and rerun.
Town-bound plans minimize food then hours, so the displayed return route is
usable with exactly the saved return reserve; final native fixture exercises
the round trip. Read the QA report for its final-source result.
Final full verification70/70 PASS, zero diagnostics, checked source fingerprint
matches workspace. Tracked verification/native receipts and13actual screenshots
are retained in docs/design/world-atlas/2026-11-04/.

Next: discuss the living-world campaign proposal while retaining the approved
appearance. Physical outbound/return review remains available via
`& .\tools\qa\start_game.ps1 -Scene app`. Start at World
atlas; try Iron Highlands -> Black Keep. Provision first; initial full itinerary
needs7food including return reserve. Plans are UI-only; current position/events
persist, final target is reselected after restart/scene return. Physical L76-01
is pending; appearance is approved. Native fixtures are not physical play.

Work stays local/uncommitted on master. No new publication was requested. The
earlier accepted dungeon was already published at d8b068c/f0afad7c. Equipment
point2 and battles/courtyard points4..6 remain pending. Do not resume an expired
autonomous timer or implement other queue items without the user's direction.
