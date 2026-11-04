# Dungeon review1: world-family materials, company strip and passages

Date:2026-11-04. Stage72, explicitly authorized by the user's "DO dziela" after
the saved review brief. Scope is dungeon only; review2..6stay pending. Extend
006/007/026/027; the accepted world screen is the concrete material/type target.

- Temporary current appearance is textured72, restored by user request after
  rejecting72b. Reuse campaign artwork, Cinzel/Source Sans3 and the single
  aspect-cover Aseprite leather crop. Frame/plate/button/paper centers stretch rather
  than tile; keep authored border/corner details. Do not globally restyle world,
  inventory, town or combat. Native review must confirm no visible square seams.
- Match the world's dark framed map/inspector panels and cream/gold text. Keep
  parchment for the illustrated map and narrative modal, rather than a large
  bright tiled inspector. Background grain stays subordinate to content.
  Current derivatives retain original textured borders with muted center contrast.
  Magnified edge grain remains a known defect; replacement materials must preserve
  the authored fantasy character instead of flattening the screen.
- Use horizontal company cards: whole aspect-fit portrait, readable name and
  explicit current/max HP, consistent red health fill/dark track. Reserve real
  space for both health text and bar at720p/1080p/1440p/4K. The model still owns HP;
  hero accent colors must not change the health meaning. Feedback fits beside
  the company and cannot force health outside the footer.
- Draw one passive map-like route per actual corridor, behind room plates and
  above the chart. Endpoints meet their real room boundaries; avoid other room
  rectangles and text. Restrained ink/brass strokes, no ornament diamonds/crosses
  or thick pipes. Selected adjacent route is emphasized from current room toward
  destination; never draw an edge for a nonadjacent selection. Routing geometry
  is presentation only and never changes graph topology or travel legality.
- Both exact illustrated Old Mine and generated layouts retain truthful paths.
  Long generated maps remain scrollable. Cache display route geometry by layout;
  state/selection only changes appearance. Route controls never intercept input.
- Text respects frame padding with deliberate line heights and wrapping. Essential
  name/HP/action values remain readable; show long content through scrolling and
  full tooltips rather than hiding information with arbitrary font reduction.
- Preserve preview/confirm costs, locks, event focus, resource updates, saves,
  authored/generated content and accepted actor art/animation.

Proof: slices/031_dungeon_visual_cohesion.md, focused layout/route geometry tests,
existing dungeon route/party/event/domain suites, real GPU captures across sizes
including preparation, selected passage, forced event, loot and generated map.
Physical/user visual acceptance remains separate; no other review step advances.

## Follow-up72b: magnified grain around frame edges

Status: REJECTED_BY_USER. The user found the flattened result much worse and
explicitly restores the earlier textured72 appearance as the temporary current
version. Retain both snapshots; do not continue stripping material character.
Further research/proposals are isolated previews until the user chooses a look.

The user reports improvement but rejects pixelated background motifs around the
frames. Clean the whole nine-slice material, including its edge strips. Preserve
the approved brass corner ornaments and palette. Straight rails use a constant
cross-section, so resizing cannot magnify irregular specks or rivets. Panel and
button interiors use quiet matte fills. Do not substitute blur or upscale the
small image to imply added detail.

The surrounding charcoal background uses a continuous shader vignette and faint
grain in physical screen pixels, without magnifying the small leather raster.
Keep linear sampling for the remaining painted UI art. Validate native720p,
1080p and4K crops at actual pixel size, including panel edges and corners. This
is a material correction only; layouts, routes, health and game rules remain.

## Current72c: preserve textured baseline, research and review new art

User selects textured72 as the temporary default and rejects72b as much worse.
Snapshots and hashes are in assets_src/ui_review_baselines/. Restore72 rather
than silently promoting a new design. Research external game-UI skills, fantasy
asset packs and MCP. New art-direction attempts stay in isolated design previews.
The user chooses the look before production Godot replacement. Keep existing
gameplay guards, full HP, room topology, actors and reviews2..6unchanged.
