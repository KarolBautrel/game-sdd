# Region foundry and illustrated generated map

Stage80. Owner world013, accepted campaign035/036 family and motion038.

Provide a native region selector/foundry with seed input, marches/woodland/
highlands presets, Generate, Previous/Next seed, Play/Resume, and Authored Marches.
Preview does not advance/save/reset the campaign. Show generation progress,
actual terrain/connection diagnostics and actionable errors. Play resumes the
same seed's separate pilot rather than replacing existing progress.

Use the accepted leather/brass frames, parchment, Cinzel/Source Sans, elevated
painted cartographic symbols, olive woodland, ochre land and muted blue water.
Generate transparent modular terrain/site art through imagegen and editable
Aseprite sources with repeatable exports. Preserve approved atlas pixels.
Continuous geography-based ground shading/water, painted forest/mountain/site
symbols and native roads/crossings/labels all follow the semantic snapshot.
Avoid repeated rectangular image patches and moving labels over unrelated art.
The generated map is the live map, not a mockup disconnected from pathfinding.

720p/1080p: keep a large independent map viewport; controls/text must fit without
overlapping site labels. All site hit targets and company/NPC banners use the
same projection and smooth motion as the authored map. Offer a semantic overlay
for inspection. Generated geography is immutable during a campaign; the manual
r9 painter stays scoped to the authored Marches.

Proof: slice039, region_foundry_interface_tests.gd, actual native GPU previews
of several seeds/presets and live seed travel with per-frame safety checks.
