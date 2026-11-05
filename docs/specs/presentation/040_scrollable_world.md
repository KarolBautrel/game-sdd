# Scrollable illustrated world

Stage81, owner world014. User approves the current gold/olive painted map style;
retain art, frames, fonts and cartographic symbols. Reuse accepted Aseprite exports.
A larger region opens on a local portion, not entirely fitted to its panel.

Provide pointer-anchored wheel zoom, right/middle drag pan, bounded view center,
zoom buttons, Overview and Company/Center controls. Overview fits the complete
map; Company returns to the real displayed party at a useful local zoom. A small
overview chart shows the viewport and current company; clicking it repositions
the view without ordering travel. Input outside the map belongs to ordinary UI.
Left map/site clicks still order travel or preview routes. Drag/wheel/minimap
must never issue travel accidentally. Camera remains usable while paused.

One forward/inverse projection governs terrain, roads, crossings, site labels,
native actor hit targets, moving banners, route overlays and tooltips. Clip
all map children to the map viewport. Hide offscreen site labels instead of
pinning them onto panel edges; visible labels fit their hit targets. Keep labels
and banners readable as the ground zooms. Resize clamps the camera safely.
Authored Marches/r9 keeps its existing fit view and painter behavior.

Large climate transitions tint continuous ground and alter actual biome placement;
symbol density is per physical area, preserving the approved detail scale.
720p/1080p: toolbar/inspector remain usable; map navigation controls are discoverable.
Tests must exercise genuine input at multiple zoom/pan positions, verify no
campaign mutation, and inspect native overview/local biome/travel screenshots.
Physical feel acceptance remains separate from engine-local automated fixtures.
